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
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.xtext.types.types.EnumTypeDecl
import nl.esi.xtext.types.types.MapTypeConstructor
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.VectorTypeConstructor

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*
import static extension nl.esi.comma.assertthat.utilities.AssertThatUtilities.isSuppressed
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*

class ConcreteExpressionHandler {
    static def Map<String, List<String>>  collectConcreteDataAssignments(AbstractStep step, Iterable<Binding> bindings) {
        val Map<String, List<String>> mapLHStoRHS = newTreeMap(String.CASE_INSENSITIVE_ORDER)

        val inputVarPrefix = step.inputVar + '.'
        for (binding : bindings.reject[suppressed]) {
            mapLHStoRHS.putVariables(inputVarPrefix + binding.varField, binding.name.type, binding.jsonvals)
        }

        return mapLHStoRHS
    }

    private static def void putVariables(Map<String, List<String>> mapLHStoRHS, String name, Type type, JsonValue value) {
        val typeDecl = type.type
        if (typeDecl  instanceof RecordTypeDecl) {
            for (field : typeDecl.allFields.reject[suppressed].filter[f|value.hasMemberValue(f.name)]) {
                mapLHStoRHS.putVariables(name + '.' + field.name, field.type, value.getMemberValue(field.name))
            }
        } else {
            mapLHStoRHS.computeIfAbsent(name)[newArrayList] += type.createValue(value)
        }
    }

    private static def String createValue(Type type, JsonValue value) {
        if (value.isNullLiteral) {
            return value.stringValue
        }
        return switch (type) {
            VectorTypeConstructor: '''
                <«type.typeObject.typeName»>[
                    «FOR itemValue : value.itemValues SEPARATOR ','»«createValue(type.outerDimension, itemValue)»«ENDFOR»
                ]
            '''
            MapTypeConstructor: '''
                <«type.typeObject.typeName»>{
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
