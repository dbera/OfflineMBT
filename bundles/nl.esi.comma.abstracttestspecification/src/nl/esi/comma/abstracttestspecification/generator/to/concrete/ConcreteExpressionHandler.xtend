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
package nl.esi.comma.abstracttestspecification.generator.to.concrete

import java.util.List
import java.util.Map
import java.util.Set
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.xtext.types.types.EnumTypeDecl
import nl.esi.xtext.types.types.MapTypeConstructor
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.TypeReference
import nl.esi.xtext.types.types.VectorTypeConstructor

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*

class ConcreteExpressionHandler {
    static def Map<String, List<String>>  collectConcreteDataAssignments(AbstractStep step, Iterable<Binding> bindings) {
        val Map<String, List<String>> mapLHStoRHS = newTreeMap(String.CASE_INSENSITIVE_ORDER)

        val inputVarPrefix = step.inputVar + '.'
        val suppressedVarFields = step.stepRef.flatMap[suppressedVarFields].map[inputVarPrefix + it].toSet
        for (binding : bindings.reject[suppressedVarFields.contains(inputVarPrefix + it.name.name)]) {
            mapLHStoRHS.putVariables(inputVarPrefix + binding.name.name, binding.name.type, binding.jsonvals, suppressedVarFields)
        }

        return mapLHStoRHS
    }

    private static def void putVariables(Map<String, List<String>> assignments, String name, Type type, JsonValue value, Set<String> suppressedVarFields) {
        if (type instanceof TypeReference && type.type instanceof RecordTypeDecl) {
            for (field : (type.type as RecordTypeDecl).fields.filter[f|value.hasMemberValue(f.name)].reject[suppressedVarFields.contains(name + '.' + it.name)]) {
                assignments.putVariables(name + '.' + field.name, field.type, value.getMemberValue(field.name), suppressedVarFields)
            }
        } else {
            assignments.computeIfAbsent(name)[newArrayList] += type.createValue(value)
        }
    }

    private static def String createValue(Type type, JsonValue value) {
        if (value.isNullLiteral) {
            return value.stringValue
        }
        return switch (type) {
            VectorTypeConstructor: '''
                <«type.typeName»>[
                    «FOR itemValue : value.itemValues SEPARATOR ','»«createValue(type.outerDimension, itemValue)»«ENDFOR»
                ]
            '''
            MapTypeConstructor: '''
                <«type.typeName»>{
                    «FOR memberValue : value.memberValues SEPARATOR ','»«createTypeDeclValue(type.type, memberValue.key.toJsonString)» -> «createValue(type.valueType, memberValue.value)»«ENDFOR»
                }
            '''
            default:
                createTypeDeclValue(type.type, value)
        }
    }

    static def String createTypeDeclValue(TypeDecl type, JsonValue value) {
        if (value.isNullLiteral) {
            return value.stringValue
        }
        return switch (type) {
            SimpleTypeDecl case type.base !== null: type.base.createTypeDeclValue(value)
            SimpleTypeDecl case type.name == 'int',
            SimpleTypeDecl case type.name == 'real',
            SimpleTypeDecl case type.name == 'bool': value.stringValue
            SimpleTypeDecl: '''"«value.stringValue»"'''
            EnumTypeDecl: {
                val typePrefix = type.name + '::'
                val valueString = value.stringValue
                valueString.startsWith(typePrefix) ? valueString : (typePrefix + valueString)
            }
            RecordTypeDecl: '''
                «type.name» {
                    «FOR field : type.fields.filter[f|value.hasMemberValue(f.name)] SEPARATOR ','»
                        «field.name» = «field.type.createValue(value.getMemberValue(field.name))»
                    «ENDFOR»
                }
            '''
        }
    }
}
