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
package nl.esi.comma.testspecification.abstspec.generator

import java.util.Collections
import java.util.List
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSJsonArray
import nl.esi.comma.testspecification.testspecification.TSJsonBool
import nl.esi.comma.testspecification.testspecification.TSJsonFloat
import nl.esi.comma.testspecification.testspecification.TSJsonLong
import nl.esi.comma.testspecification.testspecification.TSJsonMember
import nl.esi.comma.testspecification.testspecification.TSJsonObject
import nl.esi.comma.testspecification.testspecification.TSJsonString
import nl.esi.comma.testspecification.testspecification.TSJsonValue
import nl.esi.comma.testspecification.testspecification.TestspecificationFactory
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.comma.types.utilities.EcoreUtil3.serialize

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

    static def getInputVar(RunStep rstep) '''«rstep.system»Input'''

    // Gets the list of referenced compose steps
    // RULE. Exactly one referenced Compose Step.
    static def getComposeSteps(RunStep step) {
        return step.stepRef.map[refStep].filter(ComposeStep)
    }

    static def getSuppressedVarFields(ComposeStep cstep) {
        switch (cstep.suppress) {
            case null: newArrayList
            case cstep.suppress.varFields.isEmpty: cstep.output.map[it.name.name]
            default: cstep.suppress.varFields.map[it.serialize]
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

    static def List<TSJsonMember> getMemberValues(TSJsonValue json) {
        return json instanceof TSJsonObject ? json.members : Collections.emptyList
    }

    static def boolean hasMemberValue(TSJsonValue json, String member) {
        return json instanceof TSJsonObject ? json.members.exists[key == member] : false
    }

    static def TSJsonValue getMemberValue(TSJsonValue json, String member) {
        return json instanceof TSJsonObject ? json.members.findFirst[key == member]?.value : null
    }

    static def List<TSJsonValue> getItemValues(TSJsonValue json) {
        return json instanceof TSJsonArray ? json.values : Collections.emptyList
    }

    static def String getStringValue(TSJsonValue json) {
        return switch (json) {
            case null: null
            TSJsonString: json.value
            TSJsonBool: String.valueOf(json.value)
            TSJsonFloat: String.valueOf(json.value)
            TSJsonLong: String.valueOf(json.value)
            TSJsonObject: json.members.join('{', ', ', '}')['''«key»: «value.stringValue»''']
            TSJsonArray: json.values.join('[', ', ', ']')[stringValue]
            default: throw new IllegalArgumentException('Unknown JSON type ' + json)
        }
    }

    static def TSJsonString toJsonString(String text) {
        return TestspecificationFactory.eINSTANCE.createTSJsonString => [
            value = text
        ]
    }
}