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

import java.util.Set
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSJsonValue
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.VectorTypeConstructor

import static extension nl.esi.comma.testspecification.abstspec.generator.Utils.*

class ConcreteExpressionHandler {
    def prepareStepInputExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps) {
        val suppressVars = composeSteps.flatMap[suppressedVarFields].map[rstep.inputVar + '.' + it].toSet
        prepareStepInputExpressions(rstep, composeSteps, suppressVars);
    }

    def private prepareStepInputExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps, Set<String> suppressVars) '''
        «FOR output : composeSteps.flatMap[output].reject[suppressVars.contains(rstep.inputVar + '.' + it.name.name)]»
            «printVariable(rstep.inputVar + '.' + output.name.name, output.name.type, output.jsonvals, suppressVars)»
        «ENDFOR»
    '''

    def private String printVariable(String name, Type type, TSJsonValue value, Set<String> suppressVars) '''
        «IF type instanceof TypeReference && type.type instanceof RecordTypeDecl»
            «FOR field : (type.type as RecordTypeDecl).fields.filter[f|value.hasMemberValue(f.name)].reject[suppressVars.contains(name + '.' + it.name)]»
                «printVariable(name + '.' + field.name, field.type, value.getMemberValue(field.name), suppressVars)»
            «ENDFOR»
        «ELSE»
            «name» := «type.createValue(value)»
        «ENDIF»
    '''

    dispatch private def String createValue(TypeReference type, TSJsonValue value) {
        return createDeclValue(type.type, value)
    }

    dispatch private def String createValue(VectorTypeConstructor type, TSJsonValue value) '''
        <«type.typeName»>[
            «FOR itemValue : value.itemValues SEPARATOR ','
            »«createValue(type.outerDimension, itemValue)»«
            ENDFOR»
        ]
    '''

    dispatch private def String createValue(MapTypeConstructor type, TSJsonValue value) '''
        <«type.typeName»>{
            «FOR memberValue : value.memberValues SEPARATOR ','
            »«createDeclValue(type.type, memberValue.key.toJsonString)» -> «createValue(type.valueType, memberValue.value)»«
            ENDFOR»
        }
    '''

    dispatch private def String createDeclValue(SimpleTypeDecl type, TSJsonValue value) {
        if (type.base !== null) {
            return type.base.createDeclValue(value)
        }
        return switch (type.name) {
            case 'int',
            case 'real',
            case 'bool': value.stringValue
            default: '''"«value.stringValue»"'''
        }
    }

    dispatch private def String createDeclValue(EnumTypeDecl type, TSJsonValue value) {
        val typePrefix = type.name + '::'
        val valueString = value.stringValue
        return valueString.startsWith(typePrefix) ? valueString : (typePrefix + valueString)
    }

    dispatch private def String createDeclValue(RecordTypeDecl type, TSJsonValue value) '''
        «type.name» {
            «FOR field : type.fields.filter[f|value.hasMemberValue(f.name)] SEPARATOR ','»
                «field.name» = «field.type.createValue(value.getMemberValue(field.name))»
            «ENDFOR»
        }
    '''
}
