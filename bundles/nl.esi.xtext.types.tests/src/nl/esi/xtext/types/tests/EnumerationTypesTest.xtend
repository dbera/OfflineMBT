/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.tests

import com.google.inject.Inject
import nl.esi.xtext.types.types.TypesModel
import nl.esi.xtext.common.lang.utilities.EcoreUtil3
import nl.esi.xtext.common.lang.utilities.EcoreUtil3.ValidationException
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(TypesInjectorProvider)
class EnumerationTypesTest {

    @Inject ParseHelper<TypesModel> parseHelper

    private def TypesModel parse(String model) {
        val result = parseHelper.parse(model)
        assertNotNull(result)
        assertTrue(result.eResource.errors.isEmpty,
            '''Parse errors: «result.eResource.errors.join(", ")»''')
        return result
    }

    // -----------------------------------------------------------------------
    // Literals without explicit values
    // -----------------------------------------------------------------------

    @Test
    def void enumWithoutValues_valid() {
        val result = parse('''
            enum Color { RED GREEN BLUE }
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void enumWithoutValues_duplicateLiteral_validationError() {
        val result = parse('''
            enum Color { RED RED }
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('RED'), '''Expected duplicate name error for RED, got: «ex.message»''')
    }

    @Test
    // checkMinimumEnumLiterals: at least 1 literal required
    def void enumWithoutValues_noLiterals_validationError() {
        val result = parse('''
            enum Color {}
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('Color'), '''Expected minimum literals error for Color, got: «ex.message»''')
    }

    // -----------------------------------------------------------------------
    // Literals with explicit values
    // -----------------------------------------------------------------------

    @Test
    def void enumWithValues_valid() {
        val result = parse('''
            enum Color { RED=0 GREEN=1 BLUE=2 }
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    def void enumWithValues_nonContiguous_valid() {
        val result = parse('''
            enum Color { RED=0 GREEN=5 BLUE=10 }
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    // checkEnumLiteralValues: each value must be greater than the previous
    def void enumWithValues_equalValue_validationError() {
        val result = parse('''
            enum Color { RED=1 GREEN=1 }
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('greater than the previous'),
            '''Expected increasing value error, got: «ex.message»''')
    }

    @Test
    // checkEnumLiteralValues: each value must be greater than the previous
    def void enumWithValues_decreasingValue_validationError() {
        val result = parse('''
            enum Color { RED=5 GREEN=3 }
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('greater than the previous'),
            '''Expected increasing value error, got: «ex.message»''')
    }

    @Test
    def void enumWithValues_duplicateLiteral_validationError() {
        val result = parse('''
            enum Color { RED=0 RED=1 }
        ''')
        print(result.eResource.errors)
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('RED'), '''Expected duplicate name error for RED, got: «ex.message»''')
    }

    // -----------------------------------------------------------------------
    // Mixed: some literals with values, some without
    // -----------------------------------------------------------------------

    @Test
    def void enumMixed_valid() {
        val result = parse('''
            enum Color { RED GREEN=5 BLUE }
        ''')
        assertDoesNotThrow [EcoreUtil3.validate(result)]
    }

    @Test
    // checkEnumLiteralValues: explicit value must exceed last (implicit or explicit) value
    def void enumMixed_explicitValueNotGreaterThanImplicit_validationError() {
        val result = parse('''
            enum Color { RED GREEN BLUE=1 }
        ''')
        val ex = assertThrows(ValidationException) [EcoreUtil3.validate(result)]
        assertTrue(ex.message.contains('greater than the previous'),
            '''Expected increasing value error, got: «ex.message»''')
    }
}