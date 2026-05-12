/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.functions.tests;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Stream;

import org.junit.jupiter.api.Test;

import nl.esi.xtext.expressions.generator.LibraryToExprGenerator;
import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionMap;
import nl.esi.xtext.expressions.expression.ExpressionVector;

/**
 * Unit tests for {@link LibraryToExprGenerator}.
 *
 * <p>Tests the two core capabilities:
 * <ol>
 *   <li>{@link LibraryToExprGenerator#generate(java.lang.reflect.Method)} - 
 *       converts a method to a function declaration
 *   </li>
 *   <li>{@link LibraryToExprGenerator#getCustomTypes(java.lang.reflect.Method)} - 
 *       extracts custom types from a method signature
 *   </li>
 * </ol>
 * 
 * <p>These are plain JUnit 5 tests — no Xtext injection needed because the
 * generator works purely through reflection and string building.
 */
class LibraryToExprGeneratorTest {

    // =========================================================================
    // Type-mapping tests (toExprType)
    // =========================================================================
    @Test
    void typeMapping_justPrint() {
        // print the full SampleLibrart as expr.
		Stream.of(SampleLibrary.class.getMethods()).map(LibraryToExprGenerator::getCustomTypes)
				.flatMap(Collection::stream).map(s-> "type "+s).forEach(System.out::println);
		Stream.of(SampleLibrary.class.getMethods()).map(LibraryToExprGenerator::generate).forEach(System.out::println);
    }

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

    // =========================================================================
    // generate(Method) tests — Function declaration generation
    // =========================================================================

    @Test
    void generate_primitiveMethod_correctDeclaration() throws Exception {
        var method = SampleLibrary.class.getMethod("sampleBool", long.class, String.class);
        String result = LibraryToExprGenerator.generate(method);
        
        assertTrue(result.matches("function bool sampleBool\\(int \\w+, string \\w+\\)"));
    }

    @Test
    void generate_genericCollectionMethod_correctDeclaration() throws Exception {
        var method = SampleLibrary.class.getMethod("listOfLong");
        String result = LibraryToExprGenerator.generate(method);
        
        assertEquals("function int[] listOfLong()", result);
    }

    @Test
    void generate_genericMapMethod_correctDeclaration() throws Exception {
        var method = SampleLibrary.class.getMethod("mapStringLong");
        String result = LibraryToExprGenerator.generate(method);
        
        assertEquals("function map<string, int> mapStringLong()", result);
    }

    @Test
    void generate_emfTypeMethod_correctDeclaration() throws Exception {
        var method = SampleLibrary.class.getMethod("emfVectorArg", ExpressionVector.class);
        String result = LibraryToExprGenerator.generate(method);
        
        assertTrue(result.matches("function <T> T\\[\\] emfVectorArg\\(T\\[\\] \\w+\\)"));
    }

    @Test
    void generate_voidMethod_returnsEmptyString() throws Exception {
        var method = SampleLibrary.class.getMethod("voidMethod");
        String result = LibraryToExprGenerator.generate(method);
        
        assertEquals("", result);
    }

    @Test
    void generate_multipleParameters_correctDeclaration() throws Exception {
        var method = SampleLibrary.class.getMethod("multiParam", String.class, long.class, BigDecimal.class);
        String result = LibraryToExprGenerator.generate(method);
        
        assertTrue(result.matches("function string multiParam\\(string \\w+, int \\w+, real \\w+\\)"));
    }

    @Test
    void generate_instanceMethod_correctDeclaration() throws Exception {
        var method = SampleLibrary.class.getMethod("instanceMethod");
        String result = LibraryToExprGenerator.generate(method);
        
        assertEquals("function string instanceMethod()", result);
    }

    @Test
    void generate_genericTemplateMethod_withVectorContext_bindsTypeVariable() throws Exception {
        var method = SampleLibrary.class.getMethod("processVector", ExpressionVector.class);
        String result = LibraryToExprGenerator.generate(method);
        
        // With ExpressionVector context, type variable T is bound to the vector element type
        assertTrue(result.matches("function <T> T processVector\\(T\\[\\] \\w+\\)"));
    }

    @Test
    void generate_genericTemplateMethod_withMapContext_bindsTypeVariables() throws Exception {
        var method = SampleLibrary.class.getMethod("processMap", ExpressionMap.class);
        String result = LibraryToExprGenerator.generate(method);
        
        // With ExpressionMap context, type variables K, V are bound to map key/value types
        assertTrue(result.matches("function <K, V> V processMap\\(map<K, V> \\w+\\)"));
    }

    @Test
    void generate_genericTemplateMethod_complexVector_bindsMultipleTypes() throws Exception {
        var method = SampleLibrary.class.getMethod("filterVector", ExpressionVector.class, Expression.class);
        String result = LibraryToExprGenerator.generate(method);
        
        // Vector context binds T; Expression in param position becomes T (matches vector element)
        assertTrue(result.matches("function <T> bool filterVector\\(T\\[\\] \\w+, T \\w+\\)"));
    }

    // =========================================================================
    // getCustomTypes(Method) tests — Custom type extraction
    // =========================================================================

    @Test
    void getCustomTypes_noCustomTypes_returnsEmpty() throws Exception {
        var method = SampleLibrary.class.getMethod("sampleBool", long.class, String.class);
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        assertEquals(0, types.size());
    }

    @Test
    void getCustomTypes_singleCustomReturnType_returnsIt() throws Exception {
        var method = SampleLibrary.class.getMethod("processUUID", UUID.class);
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        assertEquals(1, types.size());
        assertEquals("uuid", types.get(0));
    }

    @Test
    void getCustomTypes_customInParameterAndReturn_returnsDeduped() throws Exception {
        var method = SampleLibrary.class.getMethod("uuidToString", UUID.class);
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        assertEquals(1, types.size());
        assertEquals("uuid", types.get(0));
    }

    @Test
    void getCustomTypes_multipleCustomTypes_returnsAll() throws Exception {
        var method = SampleLibrary.class.getMethod("processMultipleCustom", UUID.class, CustomType.class);
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        assertEquals(2, types.size());
        assertTrue(types.contains("uuid"));
        assertTrue(types.contains("customtype"));
    }

    @Test
    void getCustomTypes_customInGenericCollection_returnsCustom() throws Exception {
        var method = SampleLibrary.class.getMethod("listOfUUIDs");
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        // List<UUID> is a collection, so UUID inside is custom
        assertEquals(1, types.size());
        assertEquals("uuid", types.get(0));
    }

    @Test
    void getCustomTypes_voidMethod_returnsEmpty() throws Exception {
        var method = SampleLibrary.class.getMethod("voidMethod");
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        assertEquals(0, types.size());
    }

    @Test
    void getCustomTypes_emfTypesExcluded_empty() throws Exception {
        var method = SampleLibrary.class.getMethod("emfVectorArg", ExpressionVector.class);
        List<String> types = LibraryToExprGenerator.getCustomTypes(method);
        
        // ExpressionVector is an EMF type, not a custom type
        assertEquals(0, types.size());
    }

    // =========================================================================
    // Helper: Sample library with various method signatures
    // =========================================================================

    /** Sample library with representative method signatures for testing. */
    static class SampleLibrary {
        // Primitive and built-in types
        public static boolean sampleBool(long a, String b)                { return false; }
        public static String multiParam(String s, long n, BigDecimal d)   { return s; }

        // Generic collection types
        public static List<Long> listOfLong()                             { return null; }
        public static List<String> listOfString()                         { return null; }
        public static List<UUID> listOfUUIDs()                            { return null; }
        public static Collection<?> collectionWild()                      { return null; }
        
        // Generic map types
        public static Map<String, Long> mapStringLong()                   { return null; }
        public static Map<Object, Object> mapObjObj()                     { return null; }
        
        // EMF expression types
        public static ExpressionVector emfVectorArg(ExpressionVector v)   { return v; }
        public static ExpressionMap emfMapArg(ExpressionMap m)            { return m; }
        public static Expression emfExprArg(Expression e, long index)     { return e; }
        
        // Custom types
        public static UUID processUUID(UUID id)                           { return id; }
        public static String uuidToString(UUID id)                        { return id.toString(); }
        public static CustomType processMultipleCustom(UUID id, CustomType ct) { return ct; }

        // Generic template methods with EMF expression types (proper template binding)
        public static <T> T processVector(ExpressionVector v)             { return null; }
        public static <K, V> V processMap(ExpressionMap m)                { return null; }
        public static <T> boolean filterVector(ExpressionVector v, Expression e) { return false; }

        // These must NOT appear in generated output or have special behavior:
        public static void voidMethod()                                   {}
        
        // Instance method - should be included
        public String instanceMethod()                                    { return null; }
    }

    /** Placeholder for a custom type used in testing. */
    static class CustomType {
    }
}
