/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.evaluation

import com.google.inject.Inject
import com.google.inject.Singleton
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionAddition
import nl.esi.xtext.expressions.expression.ExpressionAnd
import nl.esi.xtext.expressions.expression.ExpressionAny
import nl.esi.xtext.expressions.expression.ExpressionBracket
import nl.esi.xtext.expressions.expression.ExpressionConstantBool
import nl.esi.xtext.expressions.expression.ExpressionConstantInt
import nl.esi.xtext.expressions.expression.ExpressionConstantReal
import nl.esi.xtext.expressions.expression.ExpressionConstantString
import nl.esi.xtext.expressions.expression.ExpressionDivision
import nl.esi.xtext.expressions.expression.ExpressionEnumLiteral
import nl.esi.xtext.expressions.expression.ExpressionEqual
import nl.esi.xtext.expressions.expression.ExpressionFactory
import nl.esi.xtext.expressions.expression.ExpressionFunctionCall
import nl.esi.xtext.expressions.expression.ExpressionGeq
import nl.esi.xtext.expressions.expression.ExpressionGreater
import nl.esi.xtext.expressions.expression.ExpressionLeq
import nl.esi.xtext.expressions.expression.ExpressionLess
import nl.esi.xtext.expressions.expression.ExpressionMap
import nl.esi.xtext.expressions.expression.ExpressionMapRW
import nl.esi.xtext.expressions.expression.ExpressionMaximum
import nl.esi.xtext.expressions.expression.ExpressionMinimum
import nl.esi.xtext.expressions.expression.ExpressionModulo
import nl.esi.xtext.expressions.expression.ExpressionMultiply
import nl.esi.xtext.expressions.expression.ExpressionNEqual
import nl.esi.xtext.expressions.expression.ExpressionNot
import nl.esi.xtext.expressions.expression.ExpressionNullLiteral
import nl.esi.xtext.expressions.expression.ExpressionOr
import nl.esi.xtext.expressions.expression.ExpressionPackage
import nl.esi.xtext.expressions.expression.ExpressionPlus
import nl.esi.xtext.expressions.expression.ExpressionPower
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess
import nl.esi.xtext.expressions.expression.ExpressionSubtraction
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.expressions.expression.ExpressionVector
import nl.esi.xtext.expressions.functions.ExpressionFunctionsRegistry
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.util.EcoreUtil
import nl.esi.xtext.expressions.functions.ExpressionFunctionsRegistry.NoMatchingFunctionFoundException

@Singleton
class ExpressionEvaluator {
    static extension val ExpressionFactory m_exp = ExpressionFactory.eINSTANCE

    ExpressionFunctionsRegistry functionsRegistry
    
    @Inject
    new(ExpressionFunctionsRegistry functionsRegistry) {
        this.functionsRegistry = functionsRegistry
    }
    
    def Expression evaluate(Expression expression, IEvaluationContext context) {
        if (expression === null || context === null) {
            return null
        }

        // Before evaluating this expression, try to optimize all its contained expressions,
        // such that the evaluation can use primitives as much as possible.
        expression.optimizeContainments(context)

        val evaluated = expression.doEvaluate(context);
        return evaluated === null || EcoreUtil.equals(evaluated, expression) ? expression : evaluated
    }

    protected def boolean shouldOptimize(EReference eReference, EObject eObject) {
        return switch (eReference) {
            case ExpressionPackage.Literals.EXPRESSION_RECORD_ACCESS__RECORD: false
            default: true
        }
    }

    private def void optimizeContainments(EObject eObject, IEvaluationContext context) {
        for (ref : eObject.eClass.EAllContainments.filter[shouldOptimize(eObject)]) {
            if (ExpressionPackage.Literals.EXPRESSION.isSuperTypeOf(ref.EReferenceType)) {
                if (ref.isMany) {
                    val refValue = eObject.eGet(ref, true) as EList<Expression>
                    for (var index = 0; index < refValue.size; index++) {
                        val refExpr = refValue.get(index)
                        val refEval = refExpr.evaluate(context)
                        if (refEval !== refExpr) {
                            refValue.set(index, refEval)
                        }
                    }
                } else {
                    val refValue = eObject.eGet(ref, true) as Expression
                    val refEval = refValue.evaluate(context)
                    if (refEval !== refValue) {
                        eObject.eSet(ref, refEval)
                    }
                }
            } else if (ref.isMany) {
                val refValue = eObject.eGet(ref, true) as EList<EObject>
                refValue.forEach[optimizeContainments(context)]
            } else {
                val refValue = eObject.eGet(ref, true) as EObject
                refValue.optimizeContainments(context)
            }
        }
    }

    /**
     * Returning {@code null} will evaluate to the expression itself.
     */
    protected dispatch def Expression doEvaluate(Expression expression, IEvaluationContext context) {
        return null
    }

    protected dispatch def Expression doEvaluate(ExpressionVariable expression, IEvaluationContext context) {
        var reference = context.getExpression(expression.variable)
        if (reference !== null) {
            // Reference should be evaluated before used, hence wrap it with brackets.
            // Reduction will remove the brackets if the evaluated value doesn't require them.
            val wrapped = createExpressionBracket
            // IMPORTANT: Referenced expression should be copied before it can be contained!
            wrapped.sub = EcoreUtil.copy(reference)
            return wrapped.evaluate(context)
        }
    }

    protected dispatch def Expression doEvaluate(ExpressionRecordAccess expression, IEvaluationContext context) {
        // ExpressionRecordAccess#getRecord() is not optimized, see #shouldOptimize(EReference, EObject).
        // Hence it should be evaluated before used
        val recordExpression = expression.record.evaluate(context)
        if (recordExpression instanceof ExpressionRecord) {
            // TODO: Should we throw an Exception when the field is not associated with a value?
            return recordExpression.fields.findFirst[recordField == expression.field]?.exp
        }
    }

    // Functions
    protected dispatch def Expression doEvaluate(ExpressionMapRW expression, extension IEvaluationContext context) {
        val mapExpr = expression.map
        if (mapExpr instanceof ExpressionMap) {
            if (!expression.key.isValue) {
                return null
            } else if (expression.value === null) {
                // TODO: Should we throw an Exception when the key is not associated with a value?
                return mapExpr.pairs.findFirst[EcoreUtil.equals(key, expression.key)]?.value
            } else {
                mapExpr.pairs += createPair => [
                    key = expression.key
                    value = expression.value
                ]
                return mapExpr
            }
        }
    }

    protected dispatch def Expression doEvaluate(ExpressionFunctionCall expression, IEvaluationContext context) {
        try {
            return functionsRegistry.invokeFunction(expression, context);
        }
        catch(NoMatchingFunctionFoundException e) {
            return null;
        }
        catch(Exception e) {
            throw e;
        }
    }

    // Binary

    protected dispatch def Expression doEvaluate(ExpressionAnd expression, extension IEvaluationContext context) {
        return expression.calcIfBool[l, r | l && r]
    }

    protected dispatch def Expression doEvaluate(ExpressionOr expression, extension IEvaluationContext context) {
        return expression.calcIfBool[l, r | l || r]
    }

    protected dispatch def Expression doEvaluate(ExpressionEqual expression, extension IEvaluationContext context) {
        if (expression.left.isValue && expression.right.isValue) {
            return EcoreUtil.equals(expression.left, expression.right).toBoolExpr
        }
    }

    protected dispatch def Expression doEvaluate(ExpressionNEqual expression, extension IEvaluationContext context) {
        if (expression.left.isValue && expression.right.isValue) {
            return (!EcoreUtil.equals(expression.left, expression.right)).toBoolExpr
        }
    }

    protected dispatch def Expression doEvaluate(ExpressionGeq expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l >= r]
            ?: expression.calcIfReal[l, r | l >= r]
    }

    protected dispatch def Expression doEvaluate(ExpressionGreater expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l > r]
            ?: expression.calcIfReal[l, r | l > r]
    }

    protected dispatch def Expression doEvaluate(ExpressionLeq expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l <= r]
            ?: expression.calcIfReal[l, r | l <= r]
    }

    protected dispatch def Expression doEvaluate(ExpressionLess expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l < r]
            ?: expression.calcIfReal[l, r | l < r]
    }

    protected dispatch def Expression doEvaluate(ExpressionAddition expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l + r]
            ?: expression.calcIfReal[l, r | l + r]
            ?: expression.calcIfString[l, r | l + r]
    }

    protected dispatch def Expression doEvaluate(ExpressionSubtraction expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l - r]
            ?: expression.calcIfReal[l, r | l - r]
    }

    protected dispatch def Expression doEvaluate(ExpressionMultiply expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l * r]
            ?: expression.calcIfReal[l, r | l * r]
    }

    protected dispatch def Expression doEvaluate(ExpressionDivision expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l / r]
            ?: expression.calcIfReal[l, r | l / r]
    }

    protected dispatch def Expression doEvaluate(ExpressionMaximum expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l.max(r)]
            ?: expression.calcIfReal[l, r | l.max(r)]
    }

    protected dispatch def Expression doEvaluate(ExpressionMinimum expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l.min(r)]
            ?: expression.calcIfReal[l, r | l.min(r)]
    }

    protected dispatch def Expression doEvaluate(ExpressionModulo expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l % r]
    }

    protected dispatch def Expression doEvaluate(ExpressionPower expression, extension IEvaluationContext context) {
        return expression.calcIfInt[l, r | l.pow(r.intValueExact)]
            ?: expression.calcIfReal[l, r | l.pow(r.intValueExact)]
    }

    // Unary

    protected dispatch def Expression doEvaluate(ExpressionNot expression, extension IEvaluationContext context) {
        val subValue = expression.sub.asBool
        if (subValue !== null ) {
            return (!subValue).toBoolExpr
        }
    }

    // Derived

    protected dispatch def Expression doEvaluate(ExpressionBracket expression, IEvaluationContext context) {
        return switch (expression.sub) {
            // ExpressionLevel8
            ExpressionRecordAccess,
            ExpressionMapRW,
            // ExpressionLevel9
            ExpressionConstantBool,
            ExpressionConstantInt,
            ExpressionConstantReal,
            ExpressionConstantString,
            ExpressionEnumLiteral,
            ExpressionNullLiteral,
            ExpressionVariable,
            ExpressionRecord,
            ExpressionAny,
            ExpressionFunctionCall,
            ExpressionVector,
            ExpressionMap,
            ExpressionBracket: expression.sub
            default: expression
        }
    }

    protected dispatch def Expression doEvaluate(ExpressionPlus expression, IEvaluationContext context) {
        return expression.sub
    }
}