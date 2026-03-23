/*
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
package nl.esi.comma.expressions.functions.tests;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import nl.esi.comma.expressions.functions.DefaultExpressionFunctions;
import nl.esi.comma.expressions.generator.LibraryToExprGenerator;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionVector;

/**
 * Unit tests for {@link LibraryToExprGenerator}.
 *
 * <p>These are plain JUnit 5 tests — no Xtext injection needed because the
 * generator works purely through reflection and string building.
 */
class LibraryToExprGeneratorTest {

    // =========================================================================
    // Type-mapping tests  (toExprType)
    // =========================================================================

    @Test
    void typeMapping_primitives() {
        assertAll(
            () -> assertEquals("bool",   LibraryToExprGenerator.toExprType(boolean.class)),
            () -> assertEquals("bool",   LibraryToExprGenerator.toExprType(Boolean.class)),
            () -> assertEquals("int",    LibraryToExprGenerator.toExprType(long.class)),
            () -> assertEquals("int",    LibraryToExprGenerator.toExprType(Long.class)),
            () -> assertEquals("int",    LibraryToExprGenerator.toExprType(int.class)),
            () -> assertEquals("int",    LibraryToExprGenerator.toExprType(Integer.class)),
            () -> assertEquals("int",    LibraryToExprGenerator.toExprType(short.class)),
            () -> assertEquals("int",    LibraryToExprGenerator.toExprType(byte.class)),
            () -> assertEquals("real",   LibraryToExprGenerator.toExprType(double.class)),
            () -> assertEquals("real",   LibraryToExprGenerator.toExprType(Double.class)),
            () -> assertEquals("real",   LibraryToExprGenerator.toExprType(float.class)),
            () -> assertEquals("real",   LibraryToExprGenerator.toExprType(BigDecimal.class)),
            () -> assertEquals("string", LibraryToExprGenerator.toExprType(String.class)),
            () -> assertEquals("any",    LibraryToExprGenerator.toExprType(Object.class))
        );
    }

    @Test
    void typeMapping_void_returnsNull() {
        assertNull(LibraryToExprGenerator.toExprType(void.class));
        assertNull(LibraryToExprGenerator.toExprType(Void.class));
    }

    @Test
    void typeMapping_rawCollectionAndMap() {
        assertAll(
            () -> assertEquals("any[]",        LibraryToExprGenerator.toExprType(List.class)),
            () -> assertEquals("any[]",        LibraryToExprGenerator.toExprType(Collection.class)),
            () -> assertEquals("any[]",        LibraryToExprGenerator.toExprType(ArrayList.class)),
            () -> assertEquals("map<any, any>", LibraryToExprGenerator.toExprType(Map.class)),
            () -> assertEquals("map<any, any>", LibraryToExprGenerator.toExprType(HashMap.class))
        );
    }

    @Test
    void typeMapping_genericCollectionTypes() throws Exception {
        // List<Long>   → int[]
        var listLong = SampleLibrary.class.getMethod("listOfLong").getGenericReturnType();
        assertEquals("int[]", LibraryToExprGenerator.toExprType(listLong));

        // List<String> → string[]
        var listString = SampleLibrary.class.getMethod("listOfString").getGenericReturnType();
        assertEquals("string[]", LibraryToExprGenerator.toExprType(listString));

        // Collection<?> → any[]  (wildcard)
        var collWild = SampleLibrary.class.getMethod("collectionWild").getGenericReturnType();
        assertEquals("any[]", LibraryToExprGenerator.toExprType(collWild));
    }

    @Test
    void typeMapping_genericMapTypes() throws Exception {
        // Map<String, Long> → map<string, int>
        var mapStringLong = SampleLibrary.class.getMethod("mapStringLong").getGenericReturnType();
        assertEquals("map<string, int>", LibraryToExprGenerator.toExprType(mapStringLong));

        // Map<Object, Object> → map<any, any>
        var mapObjObj = SampleLibrary.class.getMethod("mapObjObj").getGenericReturnType();
        assertEquals("map<any, any>", LibraryToExprGenerator.toExprType(mapObjObj));
    }

    @Test
    void typeMapping_emfExpressionTypes() {
        assertAll(
            () -> assertEquals("any[]",         LibraryToExprGenerator.toExprType(ExpressionVector.class)),
            () -> assertEquals("map<any, any>", LibraryToExprGenerator.toExprType(ExpressionMap.class)),
            () -> assertEquals("any",           LibraryToExprGenerator.toExprType(Expression.class))
        );
    }

    // =========================================================================
    // Generation tests — DefaultExpressionFunctions
    // =========================================================================

    @Test
    void generate_defaultFunctions_containsAllFunctionDeclarations() {
        String output = LibraryToExprGenerator.generate(DefaultExpressionFunctions.class);
        System.out.println(output);

        // Every function from functions.expr must appear in the generated output
        assertAll(
            () -> assertTrue(output.contains("function bool isEmpty("),    "isEmpty"),
            () -> assertTrue(output.contains("function int size("),        "size(collection)"),
            () -> assertTrue(output.contains("function bool contains("),   "contains"),
            () -> assertTrue(output.contains("function bool hasKey("),     "hasKey"),
            () -> assertTrue(output.contains("function real asReal("),     "asReal"),
            () -> assertTrue(output.contains("function string toString("), "toString"),
            () -> assertTrue(output.contains("function bool isEmpty("),    "isEmpty"),
            () -> assertTrue(output.contains("function any[] add("),       "add"),
            () -> assertTrue(output.contains("function any[] at("),        "at"),
            () -> assertTrue(output.contains("function any[] concat("),    "concat"),
            () -> assertTrue(output.contains("function int[] range("),     "range")
        );
    }

    @Test
    void generate_defaultFunctions_overloadsArePresent() {
        String output = LibraryToExprGenerator.generate(DefaultExpressionFunctions.class);

        // range has three overloads
        long rangeCount = output.lines()
            .filter(l -> l.startsWith("function") && l.contains(" range("))
            .count();
        assertEquals(3, rangeCount, "Expected 3 overloads for range");

        // size has two overloads (Collection and Map)
        long sizeCount = output.lines()
            .filter(l -> l.startsWith("function") && l.contains(" size("))
            .count();
        assertEquals(2, sizeCount, "Expected 2 overloads for size");
    }

    @Test
    void generate_defaultFunctions_headerCommentPresent() {
        String output = LibraryToExprGenerator.generate(DefaultExpressionFunctions.class);
        assertTrue(output.startsWith("// Generated by LibraryToExprGenerator from "));
        assertTrue(output.contains(DefaultExpressionFunctions.class.getName()));
    }

    @Test
    void generate_defaultFunctions_onlyFunctionLines() {
        String output = LibraryToExprGenerator.generate(DefaultExpressionFunctions.class);

        // Every non-blank, non-comment line must start with "function "
        output.lines()
            .filter(l -> !l.isBlank())
            .filter(l -> !l.startsWith("//"))
            .forEach(line ->
                assertTrue(line.startsWith("function "),
                    "Unexpected line in output: " + line)
            );
    }

    // =========================================================================
    // Generation tests — custom library
    // =========================================================================

    @Test
    void generate_customLibrary_correctDeclarations() {
        String output = LibraryToExprGenerator.generate(SampleLibrary.class);

        assertAll(
            () -> assertTrue(output.contains("function int[] listOfLong("),              "listOfLong"),
            () -> assertTrue(output.contains("function string[] listOfString("),         "listOfString"),
            () -> assertTrue(output.contains("function map<string, int> mapStringLong("), "mapStringLong"),
            () -> assertTrue(output.contains("function bool sampleBool("),               "sampleBool"),
            () -> assertTrue(output.contains("function real sampleReal("),               "sampleReal"),
            () -> assertTrue(output.contains("function string sampleString("),           "sampleString"),
            // EMF types
            () -> assertTrue(output.contains("function any[] emfVectorArg(any[]"),      "emfVectorArg"),
            () -> assertTrue(output.contains("function map<any, any> emfMapArg(map<any, any>"), "emfMapArg"),
            () -> assertTrue(output.contains("function any emfExprArg(any"),             "emfExprArg"),
            // instance method
            () -> assertTrue(output.contains("function string instanceMethod("),         "instanceMethod")
        );
    }

    @Test
    void generate_customLibrary_voidMethodIsSkipped() {
        String output = LibraryToExprGenerator.generate(SampleLibrary.class);
        assertFalse(output.contains("voidMethod"), "void method must not appear in output");
    }

    @Test
    void generate_customLibrary_privateMethodIsSkipped() {
        String output = LibraryToExprGenerator.generate(SampleLibrary.class);
        assertFalse(output.contains("privateMethod"), "private method must not appear in output");
    }

    @Test
    void generate_customLibrary_instanceMethodIsIncluded() {
        String output = LibraryToExprGenerator.generate(SampleLibrary.class);
        assertTrue(output.contains("instanceMethod"), "public instance method must appear in output");
    }

    @Test
    void generate_emptyLibrary_onlyHeaderLine() {
        String output = LibraryToExprGenerator.generate(EmptyLibrary.class);
        long nonCommentLines = output.lines()
            .filter(l -> !l.isBlank() && !l.startsWith("//"))
            .count();
        assertEquals(0, nonCommentLines, "Empty library should produce no function declarations");
    }

    // =========================================================================
    // IFileSystemAccessAdapter tests
    // =========================================================================

    @Test
    void generate_withAdapter_writesToGivenPath() {
        Map<String, String> captured = new HashMap<>();
        LibraryToExprGenerator.generate(SampleLibrary.class, "out/sample.expr", captured::put);

        assertTrue(captured.containsKey("out/sample.expr"));
        assertTrue(captured.get("out/sample.expr").contains("function bool sampleBool("));
    }

    @Test
    void generate_withAdapter_autoNamedFile() {
        Map<String, String> captured = new HashMap<>();
        LibraryToExprGenerator.generate(SampleLibrary.class, captured::put);

        String expectedName = SampleLibrary.class.getSimpleName().toLowerCase() + ".expr";
        assertTrue(captured.containsKey(expectedName),
            "Expected file name: " + expectedName + ", got: " + captured.keySet());
    }

    // =========================================================================
    // Helper: small library used across several tests
    // =========================================================================

    /** Minimal library with a representative spread of types and visibility. */
    static class SampleLibrary {
        public static List<Long>              listOfLong()                            { return null; }
        public static List<String>            listOfString()                          { return null; }
        public static Collection<?>           collectionWild()                        { return null; }
        public static Map<String, Long>       mapStringLong()                         { return null; }
        public static Map<Object, Object>     mapObjObj()                             { return null; }
        public static boolean                 sampleBool(long a, String b)            { return false; }
        public static BigDecimal              sampleReal(BigDecimal x)                { return x; }
        public static String                  sampleString(String s, long n)          { return s; }
        // EMF expression types
        public static ExpressionVector        emfVectorArg(ExpressionVector v)        { return v; }
        public static ExpressionMap           emfMapArg(ExpressionMap m)              { return m; }
        public static Expression              emfExprArg(Expression e, long index)    { return e; }

        // These must NOT appear in generated output:
        public static void                    voidMethod()                            {}
        @SuppressWarnings("unused")
        private static String                 privateMethod()                         { return null; }
        public        String                  instanceMethod()                        { return null; }
    }

    /** Library with no eligible methods. */
    static class EmptyLibrary {
        public static void onlyVoid() {}
    }
}
