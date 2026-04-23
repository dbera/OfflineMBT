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
import nl.esi.comma.expressions.functions.DefaultExpressionFunctions
import nl.esi.comma.expressions.functions.ExpressionFunctionsRegistry
import nl.esi.comma.expressions.functions.InMemoryExprResourceRegistry
import org.eclipse.xtext.resource.XtextResourceSet
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

/**
 * Tests that DefaultExpressionFunctions is correctly registered in-memory via
 * InMemoryExprResourceRegistry when addLibraryFunctions is called, and that
 * the generated .expr declarations can be resolved and evaluated using the
 * 'call' syntax from the Expression grammar.
 * 
 * The flow under test:
 *   1. ExpressionFunctionsRegistry.addLibraryFunctions(DefaultExpressionFunctions)
 *      → calls InMemoryExprResourceRegistry.addLibrary(DefaultExpressionFunctions)
 *      → LibraryToExprGenerator produces the .expr content
 *      → stored at inmemory:/expr/nl.esi.comma.expressions.functions.DefaultExpressionFunctions.expr
 *   2. The ExpressionRuntimeModule automatically installs the InMemoryURIHandler
 *      into the injected XtextResourceSet via InMemoryAwareResourceSetProvider.
 *   3. A model parsed with 'call functionName(...)' resolves to the FunctionDecl
 *      declared in the in-memory resource and evaluates correctly.
 */
class DefaultExpressionFunctionsTest extends ExpressionEvaluatorTestBase {

    @Inject ExpressionFunctionsRegistry registry
    @Inject XtextResourceSet resourceSet

    @BeforeEach
    def void setImports() {
        var handler = registry.getURIHandler();
        resourceSet.URIConverter?.URIHandlers?.add(0, handler);
    }

    @Test
    def void defaultFunctions_registeredInMemory_uriExists() {
        val uri = InMemoryExprResourceRegistry.uriFor(DefaultExpressionFunctions)
        Assertions.assertTrue(registry.handlesURI(uri),
            "URI scheme should be 'imr'")
        Assertions.assertNotNull(registry.getContent(uri),
            "Content should be generated for DefaultExpressionFunctions")
    }

    @Test
    def void defaultFunctions_registeredInMemory_contentContainsFunctionDeclarations() {
        val uri = InMemoryExprResourceRegistry.uriFor(DefaultExpressionFunctions)
        val content = registry.getContent(uri)

        Assertions.assertAll(
            [Assertions.assertTrue(content.contains("function bool isEmpty("), "isEmpty")],
            [Assertions.assertTrue(content.contains("function int size("), "size")],
            [Assertions.assertTrue(content.contains("function bool contains("), "contains")],
            [Assertions.assertTrue(content.contains("function real asReal("), "asReal")],
            [Assertions.assertTrue(content.contains("function bool hasKey("), "hasKey")],
            [Assertions.assertTrue(content.contains("function string toString("), "toString")],
            [Assertions.assertTrue(content.contains("function any[] set("), "set")],
            [Assertions.assertTrue(content.contains("function int[] range("), "range")]
        )
    }

    @Test
    def void defaultFunctions_uriHandler_canReadContent() {
        val uri = InMemoryExprResourceRegistry.uriFor(DefaultExpressionFunctions)
        Assertions.assertTrue(registry.getURIHandler.exists(uri, emptyMap),
            "URIHandler should report the in-memory URI as existing")

        val stream = registry.getURIHandler.createInputStream(uri, emptyMap)
        val bytes = stream.readAllBytes
        Assertions.assertTrue(bytes.length > 0, "InputStream should produce non-empty content")
    }

    // -------------------------------------------------------------------------
    // Parsing tests — verify the generated .expr is parseable by Xtext
    // -------------------------------------------------------------------------
    @Test
    def void defaultFunctions_inMemoryResource_parsesWithoutErrors() {
        val uri = InMemoryExprResourceRegistry.uriFor(DefaultExpressionFunctions)
        val res = resourceSet.getResource(uri, true)
        Assertions.assertNotNull(res, "Resource should be loadable from in-memory URI")
        Assertions.assertTrue(res.errors.isEmpty,
            '''In-memory resource has parse errors: «res.errors.map[message].join(", ")»''')
        val model = res.contents.head as ExpressionModel
        Assertions.assertFalse(model.functions.isEmpty,
            "In-memory resource should contain FunctionDecl objects")
    }

    @Test
    def void defaultFunctions_inMemoryResource_containsExpectedFunctionDecls() {
        val uri = InMemoryExprResourceRegistry.uriFor(DefaultExpressionFunctions)
        val res = resourceSet.getResource(uri, true)
        val model = res.contents.head as ExpressionModel
        val names = model.functions.map[name].toSet

        Assertions.assertAll(
            [Assertions.assertTrue(names.contains("isEmpty"), "isEmpty")],
            [Assertions.assertTrue(names.contains("size"), "size")],
            [Assertions.assertTrue(names.contains("contains"), "contains")],
            [Assertions.assertTrue(names.contains("add"), "add")],
            [Assertions.assertTrue(names.contains("asReal"), "asReal")],
            [Assertions.assertTrue(names.contains("abs"), "abs")],
            [Assertions.assertTrue(names.contains("hasKey"), "hasKey")],
            [Assertions.assertTrue(names.contains("deleteKey"), "deleteKey")],
            [Assertions.assertTrue(names.contains("get"), "get")],
            [Assertions.assertTrue(names.contains("at"), "at")],
            [Assertions.assertTrue(names.contains("set"), "set")],
            [Assertions.assertTrue(names.contains("toString"), "toString")],
            [Assertions.assertTrue(names.contains("concat"), "concat")],
            [Assertions.assertTrue(names.contains("range"), "range")]
        )
    }

    // -------------------------------------------------------------------------
    // Evaluation tests — use 'call' syntax to invoke functions from the
    // generated in-memory resource and verify results
    // -------------------------------------------------------------------------
    static val TYPES = '''
        record T {
            int ti
            real tr
            bool tb
            string ts
            int[] tis
            string[] tss
            map<int, string> ti2s
        }
    '''

    @Test
    def void call_isEmpty_onEmptyVector_returnsTrue() {
        assertEval('''
            «TYPES»
            bool result = true
        ''', '''
            «TYPES»
            bool result = call isEmpty(<int[]> [])
        ''')
    }

    @Test
    def void call_isEmpty_onNonEmptyVector_returnsFalse() {
        assertEval('''
            «TYPES»
            bool result = false
        ''', '''
            «TYPES»
            bool result = call isEmpty(<int[]> [1, 2, 3])
        ''')
    }

    @Test
    def void call_size_onVector_returnsCount() {
        assertEval('''
            «TYPES»
            int result = 3
        ''', '''
            «TYPES»
            int result = call size(<int[]> [10, 20, 30])
        ''')
    }

    @Test
    def void call_contains_matchingElement_returnsTrue() {
        assertEval('''
            «TYPES»
            bool result = true
        ''', '''
            «TYPES»
            bool result = call contains(<string[]> ["a", "b", "c"], "b")
        ''')
    }

    @Test
    def void call_contains_missingElement_returnsFalse() {
        assertEval('''
            «TYPES»
            bool result = false
        ''', '''
            «TYPES»
            bool result = call contains(<string[]> ["a", "b", "c"], "z")
        ''')
    }

    @Test
    def void call_asReal_convertsIntToReal() {
        assertEval('''
            «TYPES»
            real result = 42.0
        ''', '''
            «TYPES»
            real result = call asReal(42)
        ''')
    }

    @Test
    def void call_abs_onNegativeInt_returnsPositive() {
        assertEval('''
            «TYPES»
            int result = 7
        ''', '''
            «TYPES»
            int result = call abs(-7)
        ''')
    }

    @Test
    def void call_abs_onNegativeReal_returnsPositive() {
        assertEval('''
            «TYPES»
            real result = 3.14
        ''', '''
            «TYPES»
            real result = call abs(-3.14)
        ''')
    }

    @Test
    def void call_hasKey_existingKey_returnsTrue() {
        assertEval('''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one" } }
            bool result = true
        ''', '''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one" } }
            bool result = call hasKey(t.ti2s, 1)
        ''')
    }

    @Test
    def void call_hasKey_missingKey_returnsFalse() {
        assertEval('''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one" } }
            bool result = false
        ''', '''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one" } }
            bool result = call hasKey(t.ti2s, 99)
        ''')
    }

    @Test
    def void call_toString_convertsLongToString() {
        assertEval('''
            «TYPES»
            string result = "123"
        ''', '''
            «TYPES»
            string result = call toString(123)
        ''')
    }

    @Test
    def void call_range_singleArg_producesRange() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [0, 1, 2]
        ''', '''
            «TYPES»
            int[] result = call range(3)
        ''')
    }

    @Test
    def void call_range_startEnd_producesRange() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [2, 3, 4]
        ''', '''
            «TYPES»
            int[] result = call range(2, 5)
        ''')
    }

    @Test
    def void call_range_startEndStep_producesRange() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [0, 2, 4]
        ''', '''
            «TYPES»
            int[] result = call range(0, 6, 2)
        ''')
    }

    @Test
    def void call_add_appendsElement() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [1, 2, 3]
        ''', '''
            «TYPES»
            int[] result = call add(<int[]> [1, 2], 3)
        ''')
    }

    @Test
    def void call_range_stepGreaterThanOne_skipsElements() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [1, 4, 7]
        ''', '''
            «TYPES»
            int[] result = call range(1, 9, 3)
        ''')
    }

    @Test
    def void call_range_negativeStep_countsDown() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [5, 3, 1]
        ''', '''
            «TYPES»
            int[] result = call range(5, 0, -2)
        ''')
    }

    @Test
    def void call_get_existingIndex_returnsElement() {
        assertEval('''
            «TYPES»
            int result = 20
        ''', '''
            «TYPES»
            int result = call get(<int[]> [10, 20, 30], 1)
        ''')
    }

    @Test
    def void call_at_replacesElement() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [10, 99, 30]
        ''', '''
            «TYPES»
            int[] result = call at(<int[]> [10, 20, 30], 1, 99)
        ''')
    }

    @Test
    def void call_concat_appendsVectors() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [1, 2, 3, 4]
        ''', '''
            «TYPES»
            int[] result = call concat(<int[]> [1, 2], <int[]> [3, 4])
        ''')
    }

    @Test
    def void call_size_onMap_returnsCount() {
        assertEval('''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one", 2 -> "two" } }
            int result = 2
        ''', '''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one", 2 -> "two" } }
            int result = call size(t.ti2s)
        ''')
    }

    @Test
    def void call_deleteKey_removesEntry() {
        assertEval('''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one", 2 -> "two" } }
            map<int, string> result = <map<int, string>> { 2 -> "two" }
        ''', '''
            «TYPES»
            T t = T { ti2s = <map<int, string>> { 1 -> "one", 2 -> "two" } }
            map<int, string> result = call deleteKey(t.ti2s, 1)
        ''')
    }

    @Test
    def void call_set_replacesElement() {
        assertEval('''
            «TYPES»
            int[] result = <int[]> [10, 42, 30]
        ''', '''
            «TYPES»
            int[] result = call set(<int[]> [10, 20, 30], 1, 42)
        ''')
    }

}
