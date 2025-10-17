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
import java.util.stream.Collectors
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
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
    def prepareStepInputExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps) {
        val suppressVars = composeSteps.flatMap[suppressedVarFields].map[rstep.inputVar + '.' + it].toSet
        prepareStepInputExpressions(rstep, composeSteps, suppressVars);
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
            var sv_binds = bindings.stream.filter(p | sv_name.equals(p.name.name)).collect(Collectors.toList())
            for(bind: sv_binds){
                var type = bind.name.type.type
                var json = bind.jsonvals
                var exp_str = type.createDeclValue(json)
                varDefs.putIfAbsent(sv_def, new LinkedHashSet<String>)
                varDefs.get(sv_def).add(exp_str)
            }
        }
        return varDefs
    }

    def private prepareStepInputExpressions(RunStep rstep, Iterable<ComposeStep> composeSteps, Set<String> suppressVars) '''
        «FOR output : composeSteps.flatMap[output].reject[suppressVars.contains(rstep.inputVar + '.' + it.name.name)]»
            «printVariable(rstep.inputVar + '.' + output.name.name, output.name.type, output.jsonvals, suppressVars)»
        «ENDFOR»
    '''
    def prepareStepInputExpressions(AssertionStep astep, Iterable<RunStep> runSteps) {
        val suppressVars = runSteps.flatMap[suppressedVarFields].map[astep.inputVar + '.' + it].toSet
        prepareStepInputExpressions(astep, runSteps, suppressVars);
    }

    def private prepareStepInputExpressions(AssertionStep astep, Iterable<RunStep> runSteps, Set<String> suppressVars) '''
        «FOR output : runSteps.flatMap[output].reject[suppressVars.contains(astep.inputVar + '.' + it.name.name)]»
            «printVariable(astep.inputVar + '.' + output.name.name, output.name.type, output.jsonvals, suppressVars)»
        «ENDFOR»
    '''

    def private String printVariable(String name, Type type, JsonValue value, Set<String> suppressVars) '''
        «IF type instanceof TypeReference && type.type instanceof RecordTypeDecl»
            «FOR field : (type.type as RecordTypeDecl).fields.filter[f|value.hasMemberValue(f.name)].reject[suppressVars.contains(name + '.' + it.name)]»
                «printVariable(name + '.' + field.name, field.type, value.getMemberValue(field.name), suppressVars)»
            «ENDFOR»
        «ELSE»
            «name» := «type.createValue(value)»
        «ENDIF»
    '''

    dispatch private def String createValue(TypeReference type, JsonValue value) {
        return createDeclValue(type.type, value)
    }

    dispatch private def String createValue(VectorTypeConstructor type, JsonValue value) '''
        <«type.typeName»>[
            «FOR itemValue : value.itemValues SEPARATOR ','
            »«createValue(type.outerDimension, itemValue)»«
            ENDFOR»
        ]
    '''

    dispatch private def String createValue(MapTypeConstructor type, JsonValue value) '''
        <«type.typeName»>{
            «FOR memberValue : value.memberValues SEPARATOR ','
            »«createDeclValue(type.type, memberValue.key.toJsonString)» -> «createValue(type.valueType, memberValue.value)»«
            ENDFOR»
        }
    '''

    dispatch private def String createDeclValue(SimpleTypeDecl type, JsonValue value) {
        if (type.base !== null) {
            return type.base.createDeclValue(value)
        }
        if (value.isNullLiteral){
            return value.stringValue
        }
        return switch (type.name) {
            case 'int',
            case 'real',
            case 'bool': value.stringValue
            default: '''"«value.stringValue»"'''
        }
    }

    dispatch private def String createDeclValue(EnumTypeDecl type, JsonValue value) {
        val typePrefix = type.name + '::'
        val valueString = value.stringValue
        return valueString.startsWith(typePrefix) ? valueString : (typePrefix + valueString)
    }

    dispatch private def String createDeclValue(RecordTypeDecl type, JsonValue value) '''
        «type.name» {
            «FOR field : type.fields.filter[f|value.hasMemberValue(f.name)] SEPARATOR ','»
                «field.name» = «field.type.createValue(value.getMemberValue(field.name))»
            «ENDFOR»
        }
    '''

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
