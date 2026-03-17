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
            bool r = call isEmpty(xs)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    // Second validate on the same ExpressionFnCall identity hits the methodCache.
    @Test
    def void registeredFunction_validCall_cacheHit_noValidationError() {
        val result = parse('''
            int[] xs = <int[]>[]
            bool r = call isEmpty(xs)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void registeredFunction_wrongArgCount_validationError() {
        val result = parse('''
            function int size()
            int r = call size()
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('No matching overload found for size.'),
            '''Expected "No matching overload found for size." but got: «ex.message»''')
    }

    @Test
    def void registeredFunction_incompatibleArgType_validationError() {
        // 'isEmpty' expects a vector; bool has no converter to ExpressionVector.
        val result = parse('''
            function bool isEmpty(bool v)
            bool r = call isEmpty(true)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('No matching overload found for isEmpty.'),
            '''Expected "No matching overload found for isEmpty." but got: «ex.message»''')
    }

    @Test
    def void unregisteredFunction_validDeclaredCall_noValidationError() {
        val result = parse('''
            function bool myFn(bool x)
            bool r = call myFn(true)
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void unregisteredFunction_wrongArgCount_validationError() {
        val result = parse('''
            function bool myFn(bool x)
            bool r = call myFn()
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('Function myFn expects 1 arguments.'),
            '''Expected "Function myFn expects 1 arguments." but got: «ex.message»''')
    }

    @Test
    def void unregisteredFunction_wrongArgType_validationError() {
        val result = parse('''
            function bool myFn(int x)
            bool r = call myFn(true)
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('Function myFn expects argument 1 to be of type int.'),
            '''Expected "Function myFn expects argument 1 to be of type int." but got: «ex.message»''')
    }
    
    private def ExpressionModel parse(String model) {
        val result = parseHelper.parse(model)
        assertNotNull(result)
        assertTrue(result.eResource.errors.isEmpty,
            '''Parse errors: «result.eResource.errors.join(", ")»''')
        return result
    }
    
}