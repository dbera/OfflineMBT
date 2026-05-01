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
package nl.esi.comma.expressions.tests

import com.google.inject.Inject
import nl.esi.comma.expressions.expression.ExpressionModel
import nl.esi.xtext.common.lang.utilities.EcoreUtil3
import nl.esi.xtext.common.lang.utilities.EcoreUtil3.ValidationException
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(ExpressionInjectorProvider)
class ExpressionFunctionsValidation {

    @Inject ParseHelper<ExpressionModel> parseHelper

    @Test
    def void registeredFunction_validCall_noValidationError() {
        val result = parse('''
            int[] xs = <int[]>[]
            bool r = isEmpty(xs)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void duplicate_types_noValidationError() {
        val result = parse('''
            type aType
            type aType
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    // Second validate on the same model verifies repeated validation is stable.
    @Test
    def void registeredFunction_validCall_revalidate_noValidationError() {
        val result = parse('''
            int[] xs = <int[]>[]
            bool r = isEmpty(xs)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void registeredFunction_wrongArgCount_validationError() {
        val result = parse('''
            int r = size()
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('No Function size declared with 0 arguments'),
            '''Expected "No Function size declared with 0 arguments" but got: «ex.message»''')
    }

    @Test
    def void registeredFunction_incompatibleArgType_validationError() {
        // 'isEmpty' expects a vector; bool has no converter to ExpressionVector.
        val result = parse('''
            bool r = isEmpty(true)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('Function isEmpty expects argument 1 to be of type any[]'),
            '''Expected "Function isEmpty expects 1 arguments to be of any[]" but got: «ex.message»''')
    }

    @Test
    def void unregisteredFunction_validDeclaredCall_noValidationError() {
        val result = parse('''
            function bool myFn(bool x)
            bool r = myFn(true)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void unregisteredFunction_wrongArgCount_validationError() {
        val result = parse('''
            function bool myFn(bool x)
            bool r = myFn()
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('No Function myFn declared with 0 arguments'),
            '''Expected "No Function myFn declared with 0 arguments : «ex.message»''')
    }

    @Test
    def void unregisteredFunction_wrongArgType_validationError() {
        val result = parse('''
            function bool myFn(int x)
            bool r = myFn(true)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('Function myFn expects argument 1 to be of type int.'),
            '''Expected "Function myFn expects argument 1 to be of type int." but got: «ex.message»''')
    }

    // ========================================================================
    // Function overload tests - by number of arguments
    // ========================================================================

    @Test
    def void functionOverload_zeroArgs_noValidationError() {
        val result = parse('''
            function int overloaded()
            function int overloaded(int x)
            function int overloaded(int x, int y)
            int r = overloaded()
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void functionOverload_oneArg_noValidationError() {
        val result = parse('''
            function int overloaded()
            function int overloaded(int x)
            function int overloaded(int x, int y)
            int r = overloaded(5)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void functionOverload_twoArgs_noValidationError() {
        val result = parse('''
            function int overloaded()
            function int overloaded(int x)
            function int overloaded(int x, int y)
            int r = overloaded(5, 10)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void functionOverload_threeArgs_notDeclared_validationError() {
        val result = parse('''
            function int overloaded()
            function int overloaded(int x)
            function int overloaded(int x, int y)
            int r = overloaded(5, 10, 15)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('No Function overloaded declared with 3 arguments'),
            '''Expected "No Function overloaded declared with 3 arguments" but got: «ex.message»''')
    }

    @Test
    def void functionOverload_multipleOverloads_differentTypes_noValidationError() {
        val result = parse('''
            function int compute(int x)
            function bool compute(bool x)
            function string compute(string x)
            int r1 = compute(5)
            bool r2 = compute(true)
            string r3 = compute("test")
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void functionOverload_mixedArgCounts_allValid_noValidationError() {
        val result = parse('''
            function int calc()
            function int calc(int a)
            function int calc(int a, int b)
            function int calc(int a, int b, int c)
            int r0 = calc()
            int r1 = calc(1)
            int r2 = calc(1, 2)
            int r3 = calc(1, 2, 3)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void functionOverload_wrongArgCount_betweenOverloads_validationError() {
        // Function has 1-arg and 3-arg overloads, but not 2-arg
        val result = parse('''
            function int process(int x)
            function int process(int x, int y, int z)
            int r = process(1, 2)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('No Function process declared with 2 arguments'),
            '''Expected "No Function process declared with 2 arguments" but got: «ex.message»''')
    }

    @Test
    def void functionOverload_sameArgCount_differentTypes_wrongType_validationError() {
        val result = parse('''
            function int transform(int x)
            function bool transform(bool x)
            int r = transform(true)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('''Type mismatch: declared type 'int' does not match the expected type 'bool' '''),
            '''Expected "Type mismatch: declared type 'int' does not match the expected type 'bool'" but got: «ex.message»''')
    }

    @Test
    def void functionOverload_variadicStyle_sequentialArgCounts_noValidationError() {
        // Simulates variadic behavior by declaring overloads for 0, 1, 2, 3, 4 args
        val result = parse('''
            function int sum()
            function int sum(int a)
            function int sum(int a, int b)
            function int sum(int a, int b, int c)
            function int sum(int a, int b, int c, int d)
            int r = sum(1, 2, 3)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }
    
    private def ExpressionModel parse(String model) {
        val result = parseHelper.parse(model)
        assertNotNull(result)
        assertTrue(result.eResource.errors.isEmpty,
            '''Parse errors: «result.eResource.errors.join(", ")»''')
        return result
    }
    
}