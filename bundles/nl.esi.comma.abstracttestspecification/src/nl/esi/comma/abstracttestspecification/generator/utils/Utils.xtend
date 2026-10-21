/**
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */

package nl.esi.comma.abstracttestspecification.generator.utils

import java.util.Collections
import java.util.List
import nl.asml.matala.product.product.Block
import nl.asml.matala.product.product.ProductPackage
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.assertthat.assertThat.AssertThatFactory
import nl.esi.comma.assertthat.assertThat.JsonArray
import nl.esi.comma.assertthat.assertThat.JsonExpression
import nl.esi.comma.assertthat.assertThat.JsonMember
import nl.esi.comma.assertthat.assertThat.JsonObject
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionConstantBool
import nl.esi.xtext.expressions.expression.ExpressionConstantInt
import nl.esi.xtext.expressions.expression.ExpressionConstantReal
import nl.esi.xtext.expressions.expression.ExpressionConstantString
import nl.esi.xtext.expressions.expression.ExpressionFactory
import nl.esi.xtext.expressions.expression.ExpressionMinus
import nl.esi.xtext.expressions.expression.ExpressionNullLiteral
import nl.esi.xtext.expressions.expression.ExpressionPlus
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.expressions.expression.Variable
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypesFactory
import nl.esi.xtext.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.xplus.extensions.types.TypesExtensionUtil.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import nl.esi.xtext.types.types.TypeReference

class Utils 
{
    private new() {
        // Empty
    }

    static def getSteps(AbstractTestDefinition atd) {
        return atd.testSeq.flatMap[step]
    }

    static def getSystem(AbstractStep step) {
        return step.name.split('_').get(0)
    }

    static def String getInputVar(AbstractStep step) '''step_«step.name».input'''

    static def String getOutputVar(AbstractStep step) '''step_«step.name».output'''

    static def String getVarField(Binding binding) {
        return binding.name.varField
    }

    static def String getVarField(Variable variable) {
        if (variable.isContext) {
            return variable.getContainerOfType(Block).contextname ?: "___CONTEXT___"
        }
        return variable.name
    }

    static def boolean isContext(Variable variable) {
        return variable.eContainingFeature === ProductPackage.Literals.BLOCK__CONTEXTVARS
    }

    static def boolean isSuppressed(Binding binding) {
        // If all fields are suppressed, the binding is suppressed
        val type = binding.name.type
        if (type instanceof TypeReference && type.type instanceof RecordTypeDecl) {
            if ((type.type as RecordTypeDecl).allFields.forall[suppressed]) {
                return true
            }
        }
        val varField = binding.varField
        val step = binding.getContainerOfType(AbstractStep)
        return step?.suppress !== null && step.suppress.vars.exists[variable.varField == varField]
    }

    static def Iterable<Binding> getContextData(AbstractStep step) {
        // Try exclusion: all bindings except input and sut?
        val nonContext = step.varID.map[name].toSet
        nonContext += step.stepRef.flatMap[refData].map[name]
        return step.input.reject[nonContext.contains(name.name)]
    }

    static def Iterable<Binding> getInputData(AbstractStep step) {
        return step.stepRef.flatMap[ref | ref.refStep.output.filter[ref.refData.contains(name)]]
    }

    static def Iterable<Binding> getSUTData(AbstractStep step) {
        val sutvars = step.varID.map[name].toSet
        return step.input.filter[sutvars.contains(name.name)]
    }


    dispatch static def String printField(ExpressionRecordAccess exp) {
        return exp.record.printField + '.' + exp.field.name
    }

    dispatch static def String printField(ExpressionVariable exp) {
        return exp.variable.name
    }

    // Types utilities

    static def Type getOuterDimension(VectorTypeConstructor type) {
        return if (type.dimensions.size > 1) {
            EcoreUtil.copy(type) => [
                dimensions.removeLast
            ]
        } else {
            TypesFactory.eINSTANCE.createTypeReference => [
                type = type.type
            ]
        }
    }

    // JSON utilities

    static def List<JsonMember> getMemberValues(JsonValue json) {
        return json instanceof JsonObject ? json.members : Collections.emptyList
    }

    static def boolean hasMemberValue(JsonValue json, String member) {
        return json instanceof JsonObject ? json.members.exists[key == member] : false
    }

    static def JsonValue getMemberValue(JsonValue json, String member) {
        return json instanceof JsonObject ? json.members.findFirst[key == member]?.value : null
    }

    static def List<JsonValue> getItemValues(JsonValue json) {
        return json instanceof JsonArray ? json.values : Collections.emptyList
    }

    static def String getStringValue(JsonValue json) {
        return switch (json) {
            case null: null
            JsonExpression: {
                var expr = json.expr
                switch (expr) {
                    ExpressionConstantString: expr.value
                    ExpressionConstantBool: String.valueOf(expr.value)
                    ExpressionConstantReal: String.valueOf(expr.value)
                    ExpressionConstantInt: String.valueOf(expr.value)
                    ExpressionMinus: getStringSignedValue(expr)
                    ExpressionPlus: getStringSignedValue(expr)
                    ExpressionNullLiteral: 'null'
                    default: throw new IllegalArgumentException('Unknown Expression type ' + expr)
                }
            }
            JsonObject: json.members.join('{', ', ', '}')['''«key»: «value.stringValue»''']
            JsonArray: json.values.join('[', ', ', ']')[stringValue]
            default: throw new IllegalArgumentException('Unknown JSON type ' + json)
        }
    }

    static def boolean isNullLiteral(JsonValue json) {
        return switch (json) {
            case null: false
            JsonExpression: {
                var expr = json.expr
                switch (expr) {
                    ExpressionNullLiteral: true
                    default: false
                }
            }
            default: false
        }
    }

    def static String getStringSignedValue(Expression expr) {
        return switch (expr) {
            ExpressionPlus: '+'+getStringSignedValue(expr.sub)
            ExpressionMinus: '-'+getStringSignedValue(expr.sub)
            ExpressionConstantReal: String.valueOf(expr.value)
            ExpressionConstantInt: String.valueOf(expr.value)
            default: throw new IllegalArgumentException('Unknown Expression type ' + expr)
        }
    }

    static def JsonExpression toJsonString(String text) {
        return AssertThatFactory.eINSTANCE.createJsonExpression => [
            expr = ExpressionFactory.eINSTANCE.createExpressionConstantString => [ value = text ]
        ]
    }
}