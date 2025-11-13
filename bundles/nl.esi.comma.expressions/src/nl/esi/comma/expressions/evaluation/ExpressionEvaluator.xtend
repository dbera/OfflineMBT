package nl.esi.comma.expressions.evaluation

import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil

class ExpressionEvaluator {
    extension val ExpressionInterpreter interpreter

    new() {
        this(new ExpressionInterpreter())
    }

    protected new(ExpressionInterpreter _interpreter) {
        interpreter = _interpreter
    }

    def Expression evaluate(Expression expression, IEvaluationContext context) {
        if (expression === null) {
            return null
        }
        val _context = InternalEvaluationContext.wrap(context)

        val expressionValue = expression.execute(_context)
        if (!expressionValue.undefined) {
            val valueExpression = expressionValue.createExpression(_context.typeOf(expression))
            return EcoreUtil.equals(expression, valueExpression) ? expression : valueExpression
        }

        val evaluated = switch (expression) {
            // IMPORTANT: expression references should be copied before evaluation!
            ExpressionVariable: _context.getExpression(expression).evaluateReference(_context)
            ExpressionRecordAccess: {
                val recordExpression = expression.record.evaluate(_context)
                if (recordExpression instanceof ExpressionRecord) {
                    recordExpression.fields.findFirst[recordField == expression.field]?.exp
                }
            }
            default: {
                expression.evaluateAllContainments(_context)
                expression.reduce(_context)
            }
        }
        return evaluated ?: expression
    }

    /**
     * IMPORTANT: Expression references should be copied before evaluation!
     */
    private def Expression evaluateReference(Expression expression, IEvaluationContext context) {
        return EcoreUtil.copy(expression).evaluate(context)
    }

    private def void evaluateAllContainments(EObject eObject, IEvaluationContext context) {
        if (eObject === null) {
            return
        }
        for (ref : eObject.eClass.EAllContainments) {
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
                refValue.forEach[evaluateAllContainments(context)]
            } else {
                val refValue = eObject.eGet(ref, true) as EObject
                refValue.evaluateAllContainments(context)
            }
        }
    }

    /**
     * Returning {@code null} will evaluate to the expression itself.
     */
    protected dispatch def Expression reduce(Expression expression, IEvaluationContext context) {
        return expression
    }

    protected dispatch def Expression reduce(ExpressionMinus expression, IEvaluationContext context) {
        val sub = expression.sub
        if (sub instanceof ExpressionMinus) {
            return sub.sub
        }
    }

    protected dispatch def Expression reduce(ExpressionPlus expression, IEvaluationContext context) {
        return expression.sub
    }
}
