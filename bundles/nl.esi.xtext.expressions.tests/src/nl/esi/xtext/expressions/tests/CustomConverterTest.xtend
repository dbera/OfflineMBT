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

import com.google.inject.Inject
import java.util.Optional
import java.util.UUID
import nl.esi.xtext.expressions.conversion.IExpressionConverter
import nl.esi.xtext.expressions.evaluation.IEvaluationContext
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionModel
import nl.esi.xtext.expressions.functions.ExpressionFunctionsRegistry
import nl.esi.xtext.types.types.Type
import org.eclipse.xtext.resource.XtextResourceSet
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

/**
 * Tests that custom converters can be registered and used to handle
 * domain-specific Java types (in this case, UUID) in function calls.
 * 
 * The flow under test:
 *   1. A SampleLibrary with functions that use UUID is registered
 *   2. A UUIDConverter is provided to convert between Expression and UUID
 *   3. Function calls with string expressions are converted to UUIDs
 *   4. Function results (UUIDs) are converted back to string expressions
 */
class CustomConverterTest extends ExpressionEvaluatorTestBase {

    @Inject ExpressionFunctionsRegistry registry
    @Inject XtextResourceSet resourceSet

    boolean initialized
    @BeforeEach
    def void setup() {
        if (initialized ) return 
        
        var handler = registry.getURIHandler()
        resourceSet.URIConverter?.URIHandlers?.add(0, handler)
        
        // Register the sample library
        registry.addLibraryFunctions(SampleLibraryWithUUID)
        // Add the converter
        registry.addConverter(new UUIDConverter)
        initialized = true
        
    }

    @Test
    def void sampleLibrary_registeredInMemory_uriExists() {
        val uri = ExpressionFunctionsRegistry.EXPR_URI
        Assertions.assertTrue(registry.handlesURI(uri),
            "URI scheme should be 'imr' for sample library")
        val content = registry.getContent(uri)
        println(content)
        Assertions.assertNotNull(content,
            "Content should be generated for SampleLibraryWithUUID")
    }

    @Test
    def void sampleLibrary_contentContainsFunctionDeclarations() {
        val uri = ExpressionFunctionsRegistry.EXPR_URI
        val content = registry.getContent(uri)

        Assertions.assertAll(
            [Assertions.assertTrue(content.contains("function uuid fromString("), "fromString")],
            [Assertions.assertTrue(content.contains("function string uuidToString("), "uuidToString")],
            [Assertions.assertTrue(content.contains("function bool isValidUUID("), "isValidUUID")]
        )
    }

    @Test
    def void sampleLibrary_inMemoryResource_parsesWithoutErrors() {
        val uri = ExpressionFunctionsRegistry.EXPR_URI
        val res = resourceSet.getResource(uri, true)
        Assertions.assertNotNull(res, "Resource should be loadable from in-memory URI")
        Assertions.assertTrue(res.errors.isEmpty,
            '''In-memory resource has parse errors: «res.errors.map[message].join(", ")»''')
        val model = res.contents.head as ExpressionModel
        Assertions.assertFalse(model.functions.isEmpty,
            "In-memory resource should contain FunctionDecl objects")
    }

    @Test
    def void call_uuidToString_convertsUUIDToString() {
        assertEval('''
            uuid id = "550e8400-e29b-41d4-a716-446655440000"
            string result = "550e8400-e29b-41d4-a716-446655440000"
        ''', '''
            uuid id = "550e8400-e29b-41d4-a716-446655440000"
            string result = uuidToString(id)
        ''')
    }

    @Test
    def void call_isValidUUID_withValidUUID_returnsTrue() {
        assertEval('''
            bool result = true
        ''', '''
            bool result = isValidUUID("550e8400-e29b-41d4-a716-446655440000")
        ''')
    }

    @Test
    def void call_isValidUUID_withInvalidUUID_returnsFalse() {
        assertEval('''
            bool result = false
        ''', '''
            bool result = isValidUUID("not-a-valid-uuid")
        ''')
    }

    @Test
    def void call_isValidUUID_withEmptyString_returnsFalse() {
        assertEval('''
            bool result = false
        ''', '''
            bool result = isValidUUID("")
        ''')
    }
}

/**
 * Sample library with UUID-related functions.
 * This demonstrates how a library might use custom Java types
 * that require converters to work with the expression language.
 */
class SampleLibraryWithUUID {
    
    /**
     * Formats a UUID string (no-op, but demonstrates UUID handling).
     */
    def static UUID fromString(String uuid) {
        UUID.fromString(uuid)
    }

    /**
     * Converts a UUID to its string representation.
     */
    def static String uuidToString(UUID uuid) {
        uuid.toString
    }

    /**
     * Validates that a string is a valid UUID format.
     */
    def static boolean isValidUUID(String uuid) {
        try {
            UUID.fromString(uuid)
            return true
        }
        catch (Exception e) {
            return false
        }
    }

}

/**
 * Custom converter for UUID type.
 * Converts between Expression (string literals) and java.util.UUID objects.
 */
class UUIDConverter implements IExpressionConverter {

    override Optional<Object> toObject(Expression expression, Class<?> targetType) {
        // Only convert to UUID type
        if (!targetType.equals(UUID)) {
            return Optional.empty()
        }
        
        // Handle null
        if (expression === null) {
            return Optional.empty()
        }

        var context = IEvaluationContext.EMPTY;
        // Convert string expression to UUID
        try {
            val value = context.asString(expression)
            if (value === null || value.empty) {
                return Optional.empty()
            }
            val uuid = UUID.fromString(value)
            return Optional.of(uuid)
        } catch (IllegalArgumentException e) {
            // Invalid UUID format
            return Optional.empty()
        }
    }

    override Optional<Expression> toExpression(Object object, Type type) {
        // Only convert UUID objects
        if (!(object instanceof UUID)){
            return Optional.empty()
        }
        
        // Check if target type is string-like
        var context = IEvaluationContext.EMPTY;
        val result = context.toExpression(object.toString)
        if (result !== null) {
            return Optional.of(result)
        }
        return Optional.empty()
    }
}
