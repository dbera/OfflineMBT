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
import nl.esi.xtext.types.types.RecordField
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.TypeReference
import nl.esi.xtext.types.types.VectorTypeConstructor
import org.eclipse.xtext.xbase.lib.Functions.Function1

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*
import static extension nl.esi.xplus.extensions.types.TypesExtensionUtil.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*

class ConcreteExpressionHandler {
    static def Map<String, List<String>>  collectConcreteDataAssignments(AbstractStep step, Iterable<Binding> bindings) {
        collectConcreteDataAssignments(step, bindings, [ Binding field | field.suppressed ])
    }

    static def Map<String, List<String>>  collectConcreteDataAssignments(AbstractStep step, Iterable<Binding> bindings, Function1<Binding, Boolean> filter) {
        val Map<String, List<String>> mapLHStoRHS = newLinkedHashMap

        val inputVarPrefix = step.inputVar + '.'
        for (binding : bindings.reject(filter)) {
            mapLHStoRHS.putVariables(inputVarPrefix + binding.varField, binding.name.type, binding.jsonvals)
        }

        return mapLHStoRHS
    }

    private static def void putVariables(Map<String, List<String>> mapLHStoRHS, String name, Type type, JsonValue value) {
        putVariables(mapLHStoRHS, name, type, value, [ RecordField field | field.suppressed ])
    }

    private static def void putVariables(Map<String, List<String>> mapLHStoRHS, String name, Type type, JsonValue value, Function1<RecordField, Boolean> filter) {
        if (type instanceof TypeReference && type.type instanceof RecordTypeDecl) {
            for (field : (type.type as RecordTypeDecl).allFields.reject(filter).filter[f|value.hasMemberValue(f.name)]) {
                mapLHStoRHS.putVariables(name + '.' + field.name, field.type, value.getMemberValue(field.name), filter)
            }
        } else {
            mapLHStoRHS.computeIfAbsent(name)[newArrayList] += type.createValue(value)
        }
    }

    static def Map<String, List<String>>  collectSUTDataAssignments(AbstractStep step, Iterable<Binding> bindings) {
         collectSUTDataAssignments(step, bindings, [ Binding field | field.suppressed ])
    }

    static def Map<String, List<String>>  collectSUTDataAssignments(AbstractStep step, Iterable<Binding> bindings, Function1<Binding, Boolean> filter) {
        val Map<String, List<String>> mapLHStoRHS = newLinkedHashMap

        val inputVarPrefix = step.inputVar + '.'
        for (binding : bindings.reject(filter)) {
            mapLHStoRHS.computeIfAbsent(inputVarPrefix + binding.varField)[newArrayList] +=
                binding.name.type.createValue(binding.jsonvals)
        }

        return mapLHStoRHS
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
         createTypeDeclValue(type, value, [ RecordField field | field.suppressed ])
    }

    static def String createTypeDeclValue(TypeDecl type, JsonValue value, Function1<RecordField, Boolean> filter) {
        if (value.isNullLiteral) {
            return value.stringValue
        }
        return switch (type) {
            SimpleTypeDecl case type.base !== null: type.base.createTypeDeclValue(value, filter)
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
                    «FOR field : type.fields.reject(filter).filter[f|value.hasMemberValue(f.name)] SEPARATOR ','»
                        «field.name» = «field.type.createValue(value.getMemberValue(field.name))»
                    «ENDFOR»
                }
            '''
        }
    }
}
