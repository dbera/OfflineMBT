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

import java.util.Arrays
import java.util.Collections
import java.util.Set
import nl.esi.comma.expressions.conversion.DefaultExpressionsConverter
import nl.esi.comma.expressions.conversion.IExpressionConvertersProvider
import nl.esi.comma.expressions.functions.ExpressionFunctionsRegistry
import nl.esi.comma.expressions.functions.IExpressionFunctionLibrariesProvider
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

/**
 * Tests for {@link ExpressionFunctionsRegistry} focusing on duplicate
 * signature detection. When a library class is registered twice, the
 * registry should detect that methods with the same name and parameter
 * types already exist and reject the duplicates (logging an error)
 * without crashing.
 */
class ExpressionFunctionsRegistryTest {
    
    static class TestLibrary1 {
        static def void test(int a){
            
        }
    }

    static class TestLibrary2 {
        static def void test(int a){
            
        }
    }

    val convertersProvider = new IExpressionConvertersProvider() {
        override get() {
            return Set.of(new DefaultExpressionsConverter())
        }
    }

    val sameLibraryTwice = new IExpressionFunctionLibrariesProvider() {
        override get() {
            return Collections.unmodifiableSet(#{TestLibrary1, TestLibrary2})
        }
    }

    @Test
    def void duplicateLibrary_doesNotAddDuplicateMethods() {
        // Create providers: one that returns converters (empty set), 
        // one that returns the same library class twice
        val registry = new ExpressionFunctionsRegistry(convertersProvider, sameLibraryTwice)

        // Verify that only one instance of each method is registered
        // despite providing the library twice
        for (entry : registry.functions.entrySet) {
            val overloads = entry.value
            for (var i = 0; i < overloads.size; i++) {
                for (var j = i + 1; j < overloads.size; j++) {
                    val a = overloads.get(i).parameterTypes
                    val b = overloads.get(j).parameterTypes
                    Assertions.assertFalse(
                        Arrays.equals(a, b),
                        '''Duplicate signature detected for "«entry.key»(«a.map[simpleName].join(", ")»)"'''
                    )
                }
            }
        }
    }

    @Test
    def void duplicateSignature_isRejected() {

        val registry = new ExpressionFunctionsRegistry(convertersProvider, sameLibraryTwice)

        // Verify that for every registered function, no two overloads share
        // the same parameter types (i.e. the duplicate check works).
        for (entry : registry.functions.entrySet) {
            val overloads = entry.value
            for (var i = 0; i < overloads.size; i++) {
                for (var j = i + 1; j < overloads.size; j++) {
                    val a = overloads.get(i).parameterTypes
                    val b = overloads.get(j).parameterTypes
                    Assertions.assertFalse(
                        Arrays.equals(a, b),
                        '''Duplicate signature detected for "«entry.key»(«a.map[simpleName].join(", ")»)"'''
                    )
                }
            }
        }
    }
}
