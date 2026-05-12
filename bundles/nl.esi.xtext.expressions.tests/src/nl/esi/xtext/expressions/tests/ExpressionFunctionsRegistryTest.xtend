/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.tests

import java.util.Arrays
import java.util.Collections
import java.util.Set
import nl.esi.xtext.expressions.conversion.DefaultExpressionsConverter
import nl.esi.xtext.expressions.conversion.IExpressionConvertersProvider
import nl.esi.xtext.expressions.functions.ExpressionFunctionsRegistry
import nl.esi.xtext.expressions.functions.IExpressionFunctionLibrariesProvider
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
        
        static def Object returnsObject(){
            return null
        }
    }

    static class TestLibrary2 {
        static def void test(int a){
            
        }
    }
    
    static class TestLibraryNonTemplatizable {
        static def Object badMethod(){
            return null
        }
        
        static def void voidMethod(){
            
        }
        
        static def String goodMethod(){
            return "ok"
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

    val nonTemplatizableLibrary = new IExpressionFunctionLibrariesProvider() {
        override get() {
            return Collections.unmodifiableSet(#{TestLibraryNonTemplatizable})
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

    @Test
    def void nonTemplatizable_objectReturnType_isRejected() {
        // Create registry with library containing non-templatizable methods
        val registry = new ExpressionFunctionsRegistry(convertersProvider, nonTemplatizableLibrary)

        // Methods returning Object or void should not be registered
        Assertions.assertFalse(
            registry.hasFunction("badMethod"),
            "Method returning Object should be rejected as non-templatizable"
        )
        Assertions.assertFalse(
            registry.hasFunction("voidMethod"),
            "Method returning void should be rejected as non-templatizable"
        )

        // Methods with valid return types should be registered
        Assertions.assertTrue(
            registry.hasFunction("goodMethod"),
            "Method returning String should be successfully registered"
        )
    }
}
