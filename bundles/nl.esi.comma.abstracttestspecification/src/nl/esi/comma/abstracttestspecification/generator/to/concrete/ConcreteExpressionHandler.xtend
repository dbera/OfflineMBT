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

import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.Map
import java.util.Set
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.StepReference
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.VectorTypeConstructor
import org.eclipse.emf.common.util.EList

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*

class ConcreteExpressionHandler {
    def prepareStepInputExpressions(RunStep rstep, Iterable<StepReference> composeStepRefs) {
        val suppressVars = composeStepRefs.flatMap[suppressedVarFields].map[rstep.inputVar + '.' + it].toSet
        return '''
            «FOR output : composeStepRefs.flatMap[refStep.output].reject[suppressVars.contains(rstep.inputVar + '.' + it.name.name)]»
                «printVariable(rstep.inputVar + '.' + output.name.name, output.name.type, output.jsonvals, suppressVars)»
            «ENDFOR»
        '''
    }

    def Map<String,Set<String>> prepareSutVariableExpressions(AbstractStep astep, boolean fromInput) {
        var Map<String,Set<String>> varDefs = new LinkedHashMap
        return prepareSutVariableExpressions(astep, varDefs, fromInput)
    }

    def Map<String,Set<String>> prepareSutVariableExpressions(AbstractStep astep, Map<String,Set<String>> varDefs, boolean fromInput) {

        var EList<Variable> sutvars = astep.varID
        var EList<Binding> bindings = fromInput? astep.input : astep.output
        var String io_label = fromInput? '.input.' : '.output.'

        for(svar: sutvars){
            val sv_name = svar.name
            val sv_def = 'step_' +astep.name+ io_label+sv_name
            for(bind: bindings.filter[name.name == sv_name]) {
                var type = bind.name.type.type
                var json = bind.jsonvals
                var exp_str = type.createDeclValue(json)
                varDefs.computeIfAbsent(sv_def, [new LinkedHashSet<String>]) += exp_str
            }
        }
        return varDefs
    }

    def prepareStepInputExpressions(AssertionStep astep, Iterable<StepReference> runStepRefs) {
        val suppressVars = runStepRefs.flatMap[suppressedVarFields].map[astep.inputVar + '.' + it].toSet
        return '''
            «FOR output : runStepRefs.flatMap[refStep.output].reject[suppressVars.contains(astep.inputVar + '.' + it.name.name)]»
                «printVariable(astep.inputVar + '.' + output.name.name, output.name.type, output.jsonvals, suppressVars)»
            «ENDFOR»
        '''
    }

    def private String printVariable(String name, Type type, JsonValue value, Set<String> suppressVars) '''
        «IF type instanceof TypeReference && type.type instanceof RecordTypeDecl»
            «FOR field : (type.type as RecordTypeDecl).fields.filter[f|value.hasMemberValue(f.name)].reject[suppressVars.contains(name + '.' + it.name)]»
                «printVariable(name + '.' + field.name, field.type, value.getMemberValue(field.name), suppressVars)»
            «ENDFOR»
        «ELSE»
            «name» := «type.createValue(value)»
        «ENDIF»
    '''

    private def String createValue(Type type, JsonValue value) {
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
                    «FOR memberValue : value.memberValues SEPARATOR ','»«createDeclValue(type.type, memberValue.key.toJsonString)» -> «createValue(type.valueType, memberValue.value)»«ENDFOR»
                }
            '''
            default:
                createDeclValue(type.type, value)
        }
    }

    private def String createDeclValue(TypeDecl type, JsonValue value) {
        if (value.isNullLiteral) {
            return value.stringValue
        }
        return switch (type) {
            SimpleTypeDecl case type.base !== null: type.base.createDeclValue(value)
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

    def String createTypeDeclValue(TypeDecl type, JsonValue value) {
        return type.createDeclValue(value)
    }

    // Prepend the Run Step name to the ExpressionVariable name 
    def prepareAssertionStepExpressions(AssertionStep astep, ExpressionVariable variable) {
        val var_name = variable.variable.name
        var rstep = astep.stepRef                                // in the (abstract) AssertionStep 
                         .findFirst[                             // look for the (abstract) Run Step
                             it.refData.exists[name == var_name] // from which @variable
                         ].refStep                               // is consumed-from
        var infix = rstep.name // get name of run step from which @variable is consumed from
        return 'step_'+ infix + '.output.'+ var_name
    }
}
