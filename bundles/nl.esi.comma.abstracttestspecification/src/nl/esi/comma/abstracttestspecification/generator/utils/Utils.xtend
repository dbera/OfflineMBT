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

import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.TreeSet
import java.util.stream.Collectors

import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ExecutableStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.abstracttestspecification.generator.to.concrete.BindingComparator

import nl.esi.comma.assertthat.assertThat.AssertThatFactory
import nl.esi.comma.assertthat.assertThat.JsonArray
import nl.esi.comma.assertthat.assertThat.JsonCollection
import nl.esi.comma.assertthat.assertThat.JsonExpression
import nl.esi.comma.assertthat.assertThat.JsonMember
import nl.esi.comma.assertthat.assertThat.JsonObject
import nl.esi.comma.assertthat.assertThat.JsonValue

import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Variable

import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.VectorTypeConstructor

import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.comma.types.utilities.EcoreUtil3.serialize
import nl.esi.comma.expressions.expression.ExpressionNullLiteral
import nl.esi.comma.abstracttestspecification.generator.to.concrete.ConcreteExpressionHandler
import java.util.LinkedHashMap
import java.util.Map
import java.util.Set

class Utils 
{
    private new() {
        // Empty
    }

    static def getSteps(AbstractTestDefinition atd) {
        return atd.testSeq.flatMap[step]
    }

    static def getSystem(RunStep step) {
        return step.name.split('_').get(0)
    }
    static def getSystem(AssertionStep step) {
        return step.name.split('_').get(0)
    }
    static def getSystem(ExecutableStep step) {
        return step.name.split('_').get(0)
    }

    static def getInputVar(ExecutableStep rstep) '''«rstep.system»Input'''

    // Gets the list of referenced compose steps
    // RULE. Exactly one referenced Compose Step.
    static def getComposeSteps(RunStep step) {
        return step.stepRef.map[refStep].filter(ComposeStep)
    }

    static def getRunSteps(AssertionStep step) {
        return step.stepRef.map[refStep].filter(RunStep)
    }

    static def getSuppressedVarFields(ComposeStep cstep) {
        switch (cstep.suppress) {
            case null: newArrayList
            case cstep.suppress.varFields.isEmpty: cstep.output.map[it.name.name]
            default: cstep.suppress.varFields.map[it.serialize]
        }
    }

    static def getSuppressedVarFields(RunStep rstep) {
        switch (rstep.suppress) {
            case null: newArrayList
            case rstep.suppress.varFields.isEmpty: rstep.output.map[it.name.name]
            default: rstep.suppress.varFields.map[it.serialize]
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
    
    static def List<JsonCollection> extractSUTVars(AbstractTestDefinition atd){
        var stepSutDataIn = new ArrayList<Binding>()
        var stepSutDataOut = new ArrayList<Binding>()
        for (testseq : atd.testSeq) {
            for (step : testseq.step) {
                stepSutDataIn.addAll(getSUTData(step))
                stepSutDataOut.addAll(getSUTData(step, false))
            }
        }
        val stepSutData = removeDuplicates(stepSutDataIn,stepSutDataOut)
        var jsonValsList = stepSutData.map(obj | obj.jsonvals as JsonCollection).toList
        return jsonValsList
    }

    static def Map<String,Set<String>> extractSUTVarExpressions(AbstractTestDefinition atd){
        var ceh = new ConcreteExpressionHandler
        var Map<String,Set<String>> sutexpr = new LinkedHashMap

        for (testseq : atd.testSeq) {
            for (step : testseq.step) {
                ceh.prepareSutVariableExpressions(step, sutexpr, true)
                ceh.prepareSutVariableExpressions(step, sutexpr, false)
            }
        }
        return sutexpr
    }

    static def List<Binding> getSUTData(AbstractStep astep) { getSUTData(astep, true) }
    static def List<Binding> getSUTData(AbstractStep astep, boolean fromInput) {
        var EList<Binding> bindings = fromInput? astep.input : astep.output
        var EList<Variable> sutvars = astep.varID

        val sutvars_names = sutvars.map[s|s.name]
        return bindings .stream
                        .filter(p | sutvars_names.contains(p.name.name))
                        .collect(Collectors.toList())
    }
    
    static def List<Binding> removeDuplicates(List<Binding> inData, List<Binding> outData) {
        var join = new TreeSet<Binding>(new BindingComparator())
        for (element : inData) {
            join.add(element)
        }
        for (element : outData) {
            join.add(element)
        }
        return join.toList
    }
    
}