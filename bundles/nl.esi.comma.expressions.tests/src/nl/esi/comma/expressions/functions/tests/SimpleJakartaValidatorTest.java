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
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Negative;
import jakarta.validation.constraints.NegativeOrZero;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import nl.esi.comma.expressions.functions.SimpleJakartaValidator;
import nl.esi.comma.expressions.functions.SimpleJakartaValidator.ValidationError;
import nl.esi.comma.expressions.functions.SimpleJakartaValidator.ValidationResult;

/**
 * Unit tests for {@link SimpleJakartaValidator}.
 *
 * <p>Tests all Jakarta validation annotations supported by the validator,
 * including both happy path (valid input) and fail path (invalid input) scenarios.
 */
class SimpleJakartaValidatorTest {

    private SimpleJakartaValidator validator;

    @BeforeEach
    void setUp() {
        validator = new SimpleJakartaValidator();
    }

    // =========================================================================
    // Helper methods
    // =========================================================================

    /**
     * Validates a method call and asserts it should be valid.
     */
    private void assertValidation(String methodName, Class<?>[] paramTypes, Object[] args,
            String... expectedMessageParts) throws Exception {
        Method method = SampleAnnotatedLibrary.class.getMethod(methodName, paramTypes);
        ValidationResult result = validator.validate(method, args);

        assertTrue(result.isValid(), result.getErrorMessage());
        assertEquals(0, result.getErrors().size());
    }

    /**
     * Validates a method call and asserts it should be invalid with specific error message.
     */
    private void assertValidationFails(String methodName, Class<?>[] paramTypes, Object[] args,
            String... expectedMessageParts) throws Exception {
        Method method = SampleAnnotatedLibrary.class.getMethod(methodName, paramTypes);
        ValidationResult result = validator.validate(method, args);

        assertFalse(result.isValid());
        String errorMsg = result.getErrorMessage();
        for (String expectedPart : expectedMessageParts) {
            assertTrue(errorMsg.contains(expectedPart),
                    "Expected error message to contain '" + expectedPart + "' but got: " + errorMsg);
        }
    }

    /**
     * Validates a method call and asserts it should be invalid with exactly one error.
     */
    private void assertValidationFailsWithOneError(String methodName, Class<?>[] paramTypes,
            Object[] args, String expectedMessagePart) throws Exception {
        Method method = SampleAnnotatedLibrary.class.getMethod(methodName, paramTypes);
        ValidationResult result = validator.validate(method, args);

        assertFalse(result.isValid());
        assertEquals(1, result.getErrors().size());
        assertTrue(result.getErrorMessage().contains(expectedMessagePart));
    }

    /**
     * Validates return value and asserts it should be valid.
     */
    private void assertReturnValueValid(String methodName, Object returnValue) throws Exception {
        Method method = SampleAnnotatedLibrary.class.getMethod(methodName);
        ValidationResult result = validator.validateReturnValue(method, returnValue);

        assertTrue(result.isValid(), result.getErrorMessage());
    }

    /**
     * Validates return value and asserts it should be invalid with specific error message.
     */
    private void assertReturnValueFails(String methodName, Object returnValue,
            String... expectedMessageParts) throws Exception {
        Method method = SampleAnnotatedLibrary.class.getMethod(methodName);
        ValidationResult result = validator.validateReturnValue(method, returnValue);

        assertFalse(result.isValid());
        String errorMsg = result.getErrorMessage();
        for (String expectedPart : expectedMessageParts) {
            assertTrue(errorMsg.contains(expectedPart),
                    "Expected error message to contain '" + expectedPart + "' but got: " + errorMsg);
        }
    }

    // =========================================================================
    // @NotNull tests
    // =========================================================================

    @Test
    void notNull_happyPath_nonNullValue() throws Exception {
        assertValidation("notNullMethod", new Class[] {String.class}, new Object[] {"valid"});
    }

    @Test
    void notNull_failPath_nullValue() throws Exception {
        assertValidationFailsWithOneError("notNullMethod", new Class[] {String.class},
                new Object[] {null}, "must not be null");
    }

    // =========================================================================
    // @NotEmpty tests
    // =========================================================================

    @Test
    void notEmpty_happyPath_nonEmptyString() throws Exception {
        assertValidation("notEmptyMethod", new Class[] {String.class}, new Object[] {"content"});
    }

    @Test
    void notEmpty_happyPath_nonEmptyCollection() throws Exception {
        assertValidation("notEmptyMethod", new Class[] {String.class},
                new Object[] {new ArrayList<>(List.of("item"))});
    }

    @Test
    void notEmpty_failPath_emptyString() throws Exception {
        assertValidationFailsWithOneError("notEmptyMethod", new Class[] {String.class},
                new Object[] {""}, "must not be empty");
    }

    @Test
    void notEmpty_failPath_nullValue() throws Exception {
        assertValidationFails("notEmptyMethod", new Class[] {String.class}, new Object[] {null},
                "must not be");
    }

    @Test
    void notEmpty_failPath_emptyCollection() throws Exception {
        assertValidationFails("notEmptyMethod", new Class[] {String.class},
                new Object[] {new ArrayList<>()}, "must not be empty");
    }

    // =========================================================================
    // @NotBlank tests
    // =========================================================================

    @Test
    void notBlank_happyPath_nonBlankString() throws Exception {
        assertValidation("notBlankMethod", new Class[] {String.class}, new Object[] {"content"});
    }

    @Test
    void notBlank_failPath_blankString() throws Exception {
        assertValidationFailsWithOneError("notBlankMethod", new Class[] {String.class},
                new Object[] {"   "}, "must not be blank");
    }

    @Test
    void notBlank_failPath_emptyString() throws Exception {
        assertValidationFails("notBlankMethod", new Class[] {String.class}, new Object[] {""},
                "must not be blank");
    }

    // =========================================================================
    // @Email tests
    // =========================================================================

    @Test
    void email_happyPath_validEmail() throws Exception {
        assertValidation("emailMethod", new Class[] {String.class}, new Object[] {"test@example.com"});
    }

    @Test
    void email_happyPath_nullValue() throws Exception {
        assertValidation("emailMethod", new Class[] {String.class}, new Object[] {null});
    }

    @Test
    void email_failPath_invalidEmail() throws Exception {
        assertValidationFailsWithOneError("emailMethod", new Class[] {String.class},
                new Object[] {"invalid-email"}, "must be a valid email address");
    }

    // =========================================================================
    // @Min tests
    // =========================================================================

    @Test
    void min_happyPath_valueAboveMin() throws Exception {
        assertValidation("minMethod", new Class[] {long.class}, new Object[] {100L});
    }

    @Test
    void min_happyPath_valueEqualToMin() throws Exception {
        assertValidation("minMethod", new Class[] {long.class}, new Object[] {50L});
    }

    @Test
    void min_failPath_valueBelowMin() throws Exception {
        assertValidationFailsWithOneError("minMethod", new Class[] {long.class}, new Object[] {10L},
                "must be greater than or equal to 50");
    }

    // =========================================================================
    // @Max tests
    // =========================================================================

    @Test
    void max_happyPath_valueBelowMax() throws Exception {
        assertValidation("maxMethod", new Class[] {long.class}, new Object[] {100L});
    }

    @Test
    void max_happyPath_valueEqualToMax() throws Exception {
        assertValidation("maxMethod", new Class[] {long.class}, new Object[] {200L});
    }

    @Test
    void max_failPath_valueAboveMax() throws Exception {
        assertValidationFailsWithOneError("maxMethod", new Class[] {long.class}, new Object[] {300L},
                "must be less than or equal to 200");
    }

    // =========================================================================
    // @Size tests
    // =========================================================================

    @Test
    void size_happyPath_validStringLength() throws Exception {
        assertValidation("sizeMethod", new Class[] {String.class}, new Object[] {"hello"});
    }

    @Test
    void size_happyPath_minValidStringLength() throws Exception {
        assertValidation("sizeMethod", new Class[] {String.class}, new Object[] {"hi"});
    }

    @Test
    void size_happyPath_maxValidStringLength() throws Exception {
        assertValidation("sizeMethod", new Class[] {String.class}, new Object[] {"tencharstr"});
    }

    @Test
    void size_failPath_stringTooShort() throws Exception {
        assertValidationFails("sizeMethod", new Class[] {String.class}, new Object[] {"a"},
                "size must be between 2 and 10");
    }

    @Test
    void size_failPath_stringTooLong() throws Exception {
        assertValidationFails("sizeMethod", new Class[] {String.class},
                new Object[] {"this is a very long string"}, "size must be between 2 and 10");
    }

    // =========================================================================
    // @Pattern tests
    // =========================================================================

    @Test
    void pattern_happyPath_matchingPattern() throws Exception {
        assertValidation("patternMethod", new Class[] {String.class}, new Object[] {"abc123"});
    }

    @Test
    void pattern_failPath_nonMatchingPattern() throws Exception {
        assertValidationFails("patternMethod", new Class[] {String.class}, new Object[] {"invalid!!!"},
                "must match pattern");
    }

    // =========================================================================
    // @Positive tests
    // =========================================================================

    @Test
    void positive_happyPath_positiveNumber() throws Exception {
        assertValidation("positiveMethod", new Class[] {double.class}, new Object[] {42.5});
    }

    @Test
    void positive_failPath_zeroValue() throws Exception {
        assertValidationFails("positiveMethod", new Class[] {double.class}, new Object[] {0.0},
                "must be positive");
    }

    @Test
    void positive_failPath_negativeNumber() throws Exception {
        assertValidationFails("positiveMethod", new Class[] {double.class}, new Object[] {-10.5},
                "must be positive");
    }

    // =========================================================================
    // @PositiveOrZero tests
    // =========================================================================

    @Test
    void positiveOrZero_happyPath_positiveNumber() throws Exception {
        assertValidation("positiveOrZeroMethod", new Class[] {double.class}, new Object[] {42.5});
    }

    @Test
    void positiveOrZero_happyPath_zeroValue() throws Exception {
        assertValidation("positiveOrZeroMethod", new Class[] {double.class}, new Object[] {0.0});
    }

    @Test
    void positiveOrZero_failPath_negativeNumber() throws Exception {
        assertValidationFails("positiveOrZeroMethod", new Class[] {double.class}, new Object[] {-10.5},
                "must be positive or zero");
    }

    // =========================================================================
    // @Negative tests
    // =========================================================================

    @Test
    void negative_happyPath_negativeNumber() throws Exception {
        assertValidation("negativeMethod", new Class[] {double.class}, new Object[] {-42.5});
    }

    @Test
    void negative_failPath_zeroValue() throws Exception {
        assertValidationFails("negativeMethod", new Class[] {double.class}, new Object[] {0.0},
                "must be negative");
    }

    @Test
    void negative_failPath_positiveNumber() throws Exception {
        assertValidationFails("negativeMethod", new Class[] {double.class}, new Object[] {10.5},
                "must be negative");
    }

    // =========================================================================
    // @NegativeOrZero tests
    // =========================================================================

    @Test
    void negativeOrZero_happyPath_negativeNumber() throws Exception {
        assertValidation("negativeOrZeroMethod", new Class[] {double.class}, new Object[] {-42.5});
    }

    @Test
    void negativeOrZero_happyPath_zeroValue() throws Exception {
        assertValidation("negativeOrZeroMethod", new Class[] {double.class}, new Object[] {0.0});
    }

    @Test
    void negativeOrZero_failPath_positiveNumber() throws Exception {
        assertValidationFails("negativeOrZeroMethod", new Class[] {double.class}, new Object[] {10.5},
                "must be negative or zero");
    }

    // =========================================================================
    // @DecimalMin tests
    // =========================================================================

    @Test
    void decimalMin_happyPath_valueAboveMin() throws Exception {
        assertValidation("decimalMinMethod", new Class[] {BigDecimal.class},
                new Object[] {new BigDecimal("100.5")});
    }

    @Test
    void decimalMin_happyPath_valueEqualToMin() throws Exception {
        assertValidation("decimalMinMethod", new Class[] {BigDecimal.class},
                new Object[] {new BigDecimal("50.0")});
    }

    @Test
    void decimalMin_failPath_valueBelowMin() throws Exception {
        assertValidationFails("decimalMinMethod", new Class[] {BigDecimal.class},
                new Object[] {new BigDecimal("10.5")}, "must be greater than or equal to 50.0");
    }

    // =========================================================================
    // @DecimalMax tests
    // =========================================================================

    @Test
    void decimalMax_happyPath_valueBelowMax() throws Exception {
        assertValidation("decimalMaxMethod", new Class[] {BigDecimal.class},
                new Object[] {new BigDecimal("100.5")});
    }

    @Test
    void decimalMax_happyPath_valueEqualToMax() throws Exception {
        assertValidation("decimalMaxMethod", new Class[] {BigDecimal.class},
                new Object[] {new BigDecimal("200.0")});
    }

    @Test
    void decimalMax_failPath_valueAboveMax() throws Exception {
        assertValidationFails("decimalMaxMethod", new Class[] {BigDecimal.class},
                new Object[] {new BigDecimal("250.5")}, "must be less than or equal to 200.0");
    }

    // =========================================================================
    // Multiple validations on one method
    // =========================================================================

    @Test
    void multipleAnnotations_happyPath_allValid() throws Exception {
        assertValidation("multipleAnnotationsMethod", new Class[] {String.class},
                new Object[] {"test@example.com"});
    }

    @Test
    void multipleAnnotations_failPath_null() throws Exception {
        assertValidationFails("multipleAnnotationsMethod", new Class[] {String.class},
                new Object[] {null}, "must not be null");
    }

    @Test
    void multipleAnnotations_failPath_invalidEmail() throws Exception {
        assertValidationFails("multipleAnnotationsMethod", new Class[] {String.class},
                new Object[] {"not-an-email"}, "must be a valid email address");
    }

    // =========================================================================
    // Cache tests
    // =========================================================================

    @Test
    void cache_initiallyEmpty() {
        assertEquals(0, validator.getCacheSize());
    }

    @Test
    void cache_populatesAfterValidation() throws Exception {
        assertValidation("notNullMethod", new Class[] {String.class}, new Object[] {"valid"});

        assertTrue(validator.getCacheSize() > 0);
    }

    @Test
    void cache_clearWorks() throws Exception {
        assertValidation("notNullMethod", new Class[] {String.class}, new Object[] {"valid"});
        assertTrue(validator.getCacheSize() > 0);

        validator.clearCache();
        assertEquals(0, validator.getCacheSize());
    }

    // =========================================================================
    // Return value constraint tests
    // =========================================================================

    @Test
    void returnNotNull_happyPath_nonNullValue() throws Exception {
        assertReturnValueValid("returnNotNullMethod", "valid");
    }

    @Test
    void returnNotNull_failPath_nullValue() throws Exception {
        assertReturnValueFails("returnNotNullMethod", null, "must not be null");
    }

    @Test
    void returnEmail_happyPath_validEmail() throws Exception {
        assertReturnValueValid("returnEmailMethod", "test@example.com");
    }

    @Test
    void returnEmail_failPath_invalidEmail() throws Exception {
        assertReturnValueFails("returnEmailMethod", "invalid-email", "must be a valid email address");
    }

    @Test
    void returnPositive_happyPath_positiveNumber() throws Exception {
        assertReturnValueValid("returnPositiveMethod", 42.5);
    }

    @Test
    void returnPositive_failPath_zeroValue() throws Exception {
        assertReturnValueFails("returnPositiveMethod", 0.0, "must be positive");
    }

    @Test
    void returnPositiveOrZero_happyPath_zeroValue() throws Exception {
        assertReturnValueValid("returnPositiveOrZeroMethod", 0.0);
    }

    @Test
    void returnPositiveOrZero_failPath_negativeNumber() throws Exception {
        assertReturnValueFails("returnPositiveOrZeroMethod", -5.0, "must be positive or zero");
    }

    @Test
    void returnNegative_happyPath_negativeNumber() throws Exception {
        assertReturnValueValid("returnNegativeMethod", -10.5);
    }

    @Test
    void returnNegative_failPath_positiveNumber() throws Exception {
        assertReturnValueFails("returnNegativeMethod", 10.5, "must be negative");
    }

    @Test
    void returnNegativeOrZero_happyPath_zeroValue() throws Exception {
        assertReturnValueValid("returnNegativeOrZeroMethod", 0.0);
    }

    @Test
    void returnNegativeOrZero_failPath_positiveNumber() throws Exception {
        assertReturnValueFails("returnNegativeOrZeroMethod", 5.0, "must be negative or zero");
    }

    @Test
    void returnMin_happyPath_valueAboveMin() throws Exception {
        assertReturnValueValid("returnMinMethod", 100L);
    }

    @Test
    void returnMin_failPath_valueBelowMin() throws Exception {
        assertReturnValueFails("returnMinMethod", 10L, "must be greater than or equal to 50");
    }

    @Test
    void returnMax_happyPath_valueBelowMax() throws Exception {
        assertReturnValueValid("returnMaxMethod", 150L);
    }

    @Test
    void returnMax_failPath_valueAboveMax() throws Exception {
        assertReturnValueFails("returnMaxMethod", 250L, "must be less than or equal to 200");
    }

    @Test
    void returnSize_happyPath_validLength() throws Exception {
        assertReturnValueValid("returnSizeMethod", "hello");
    }

    @Test
    void returnSize_failPath_tooShort() throws Exception {
        assertReturnValueFails("returnSizeMethod", "a", "size must be between 2 and 10");
    }

    @Test
    void returnNotBlank_happyPath_nonBlankString() throws Exception {
        assertReturnValueValid("returnNotBlankMethod", "content");
    }

    @Test
    void returnNotBlank_failPath_blankString() throws Exception {
        assertReturnValueFails("returnNotBlankMethod", "   ", "must not be blank");
    }

    @Test
    void returnNotEmpty_happyPath_nonEmptyString() throws Exception {
        assertReturnValueValid("returnNotEmptyMethod", "content");
    }

    @Test
    void returnNotEmpty_failPath_emptyString() throws Exception {
        assertReturnValueFails("returnNotEmptyMethod", "", "must not be empty");
    }

    @Test
    void returnPattern_happyPath_matchingPattern() throws Exception {
        assertReturnValueValid("returnPatternMethod", "abc123");
    }

    @Test
    void returnPattern_failPath_nonMatchingPattern() throws Exception {
        assertReturnValueFails("returnPatternMethod", "invalid!!!", "must match pattern");
    }

    @Test
    void returnDecimalMin_happyPath_valueAboveMin() throws Exception {
        assertReturnValueValid("returnDecimalMinMethod", new BigDecimal("100.5"));
    }

    @Test
    void returnDecimalMin_failPath_valueBelowMin() throws Exception {
        assertReturnValueFails("returnDecimalMinMethod", new BigDecimal("10.5"),
                "must be greater than or equal to 50.0");
    }

    @Test
    void returnDecimalMax_happyPath_valueBelowMax() throws Exception {
        assertReturnValueValid("returnDecimalMaxMethod", new BigDecimal("150.5"));
    }

    @Test
    void returnDecimalMax_failPath_valueAboveMax() throws Exception {
        assertReturnValueFails("returnDecimalMaxMethod", new BigDecimal("250.5"),
                "must be less than or equal to 200.0");
    }

    @Test
    void returnMultipleAnnotations_happyPath_validEmail() throws Exception {
        assertReturnValueValid("returnMultipleAnnotationsMethod", "test@example.com");
    }

    @Test
    void returnMultipleAnnotations_failPath_null() throws Exception {
        assertReturnValueFails("returnMultipleAnnotationsMethod", null, "must not be null");
    }

    @Test
    void returnMultipleAnnotations_failPath_invalidEmail() throws Exception {
        assertReturnValueFails("returnMultipleAnnotationsMethod", "not-an-email",
                "must be a valid email address");
    }

    // =========================================================================
    // Helper: Sample library with annotated methods
    // =========================================================================

    /**
     * Sample library containing methods with various Jakarta validation annotations.
     * Used for testing the SimpleJakartaValidator.
     */
    static class SampleAnnotatedLibrary {
        public static void notNullMethod(@NotNull String value) {}

        public static void notEmptyMethod(@NotEmpty String value) {}

        public static void notBlankMethod(@NotBlank String value) {}

        public static void emailMethod(@Email String value) {}

        public static void minMethod(@Min(50) long value) {}

        public static void maxMethod(@Max(200) long value) {}

        public static void sizeMethod(@Size(min = 2, max = 10) String value) {}

        public static void patternMethod(@Pattern(regexp = "^[a-zA-Z0-9]+$") String value) {}

        public static void positiveMethod(@Positive double value) {}

        public static void positiveOrZeroMethod(@PositiveOrZero double value) {}

        public static void negativeMethod(@Negative double value) {}

        public static void negativeOrZeroMethod(@NegativeOrZero double value) {}

        public static void decimalMinMethod(@DecimalMin("50.0") BigDecimal value) {}

        public static void decimalMaxMethod(@DecimalMax("200.0") BigDecimal value) {}

        public static void multipleAnnotationsMethod(@NotNull @Email String value) {}

        // ===== Return type constraint methods =====

        @NotNull
        public static String returnNotNullMethod() { return "valid"; }

        @Email
        public static String returnEmailMethod() { return "test@example.com"; }

        @Positive
        public static double returnPositiveMethod() { return 42.5; }

        @PositiveOrZero
        public static double returnPositiveOrZeroMethod() { return 0.0; }

        @Negative
        public static double returnNegativeMethod() { return -10.5; }

        @NegativeOrZero
        public static double returnNegativeOrZeroMethod() { return 0.0; }

        @Min(50)
        public static long returnMinMethod() { return 100L; }

        @Max(200)
        public static long returnMaxMethod() { return 150L; }

        @Size(min = 2, max = 10)
        public static String returnSizeMethod() { return "hello"; }

        @NotBlank
        public static String returnNotBlankMethod() { return "content"; }

        @NotEmpty
        public static String returnNotEmptyMethod() { return "content"; }

        @Pattern(regexp = "^[a-zA-Z0-9]+$")
        public static String returnPatternMethod() { return "abc123"; }

        @DecimalMin("50.0")
        public static BigDecimal returnDecimalMinMethod() { return new BigDecimal("100.5"); }

        @DecimalMax("200.0")
        public static BigDecimal returnDecimalMaxMethod() { return new BigDecimal("150.5"); }

        @NotNull
        @Email
        public static String returnMultipleAnnotationsMethod() { return "test@example.com"; }
    }
}
