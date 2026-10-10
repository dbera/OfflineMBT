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
import java.util.Set
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ChainedStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ExecutableStep
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
import nl.esi.xtext.types.types.MapTypeConstructor
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeReference
import nl.esi.xtext.types.types.TypesFactory
import nl.esi.xtext.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.serialize

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

    static def getInputVar(AbstractStep step) '''«step.system»Input'''

    static def getOutputVar(AbstractStep step) '''step_«step.name».output'''

    static def List<Binding> getContextData(AbstractStep step) {
        // Try exclusion: all bindings except input and sut?
        val nonContext = step.varID.map[name].toSet
        nonContext += step.stepRef.flatMap[refData].map[name]
        return step.input.reject[nonContext.contains(name.name)].toList
    }

    static def List<Binding> getInputData(AbstractStep step) {
        return step.stepRef.flatMap[ref | ref.refStep.output.filter[ref.refData.contains(name)]].toList
    }

    static def List<Binding> getSUTData(AbstractStep step) {
        val sutvars = step.varID.map[name].toSet
        return step.input.filter[sutvars.contains(name.name)].toList
    }


    @Deprecated
    static def getChainedStepRefs(ExecutableStep step) {
        return step.stepRef.filter[refStep instanceof ChainedStep]
    }

    static def Set<String> getSuppressedVarFields(AbstractStep step) {
        return switch (it: step.suppress) {
            case null: Collections.emptySet
            case varFields.isEmpty: (step.input + step.output).map[it.name.name].toSet
            default: varFields.map[it.serialize].toSet
        }
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

    dispatch static def String getTypeName(TypeReference type) '''
        «type.type.name»'''

    dispatch static def String getTypeName(VectorTypeConstructor type) '''
        «type.type.name»«FOR dimension : type.dimensions»[]«ENDFOR»'''

    dispatch static def String getTypeName(MapTypeConstructor type) '''
        map<«type.type.name», «type.valueType.typeName»>'''

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
    
//    static def List<JsonCollection> extractSUTVars(AbstractTestDefinition atd){
//        var stepSutDataIn = new ArrayList<Binding>()
//        var stepSutDataOut = new ArrayList<Binding>()
//        for (testseq : atd.testSeq) {
//            for (step : testseq.step) {
//                stepSutDataIn.addAll(getSUTData(step))
//                stepSutDataOut.addAll(getSUTData(step, false))
//            }
//        }
//        val stepSutData = removeDuplicates(stepSutDataIn,stepSutDataOut)
//        var jsonValsList = stepSutData.map(obj | obj.jsonvals as JsonCollection).toList
//        return jsonValsList
//    }

//    static def Map<String,Set<String>> extractSUTVarExpressions(AbstractTestDefinition atd){
//        var ceh = new ConcreteExpressionHandler
//        var Map<String,Set<String>> sutexpr = new LinkedHashMap
//
//        for (testseq : atd.testSeq) {
//            for (step : testseq.step) {
//                ceh.prepareSutVariableExpressions(step, sutexpr, true)
//                ceh.prepareSutVariableExpressions(step, sutexpr, false)
//            }
//        }
//        return sutexpr
//    }

//    static def List<Binding> removeDuplicates(List<Binding> inData, List<Binding> outData) {
//        var join = new TreeSet<Binding>(new BindingComparator())
//        for (element : inData) {
//            join.add(element)
//        }
//        for (element : outData) {
//            join.add(element)
//        }
//        return join.toList
//    }
    
}