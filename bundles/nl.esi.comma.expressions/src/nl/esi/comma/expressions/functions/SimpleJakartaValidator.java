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
package nl.esi.comma.expressions.functions;

import java.lang.annotation.Annotation;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.BiFunction;

import org.apache.commons.validator.routines.EmailValidator;

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

/**
 * Bridge class that validates Jakarta validation annotations using Apache Commons Validation.
 * Implements caching to avoid repeated reflection lookups.
 *
 * <p>Supported annotations are registered in a  map ({@link #RULE_FACTORIES})
 * that maps each annotation type to a factory producing a {@link ValidationRule}.
 */
public class SimpleJakartaValidator {

    /**
     * A factory that creates a {@link ValidationRule} from a concrete annotation
     * instance and the parameter name it annotates.
     */
    @FunctionalInterface
    private interface RuleFactory extends BiFunction<Annotation, String, ValidationRule> {}

    /** Immutable registry of all supported Jakarta annotation handlers. */
    private static final Map<Class<? extends Annotation>, RuleFactory> RULE_FACTORIES;

    static {
        var factories = new LinkedHashMap<Class<? extends Annotation>, RuleFactory>();

        factories.put(NotNull.class, (a, name) ->
            (value, idx) -> value == null ? new ValidationError(idx, name, "must not be null") : null);

        factories.put(NotEmpty.class, (a, name) -> (value, idx) -> {
            if (value == null) return new ValidationError(idx, name, "must not be null");
            if (value instanceof String s && s.isEmpty()) return new ValidationError(idx, name, "must not be empty");
            if (value instanceof Collection<?> c && c.isEmpty()) return new ValidationError(idx, name, "must not be empty");
            if (value instanceof Map<?, ?> m && m.isEmpty()) return new ValidationError(idx, name, "must not be empty");
            return null;
        });

        factories.put(NotBlank.class, (a, name) -> (value, idx) -> {
            if (value == null) return new ValidationError(idx, name, "must not be null");
            if (value instanceof String s && s.trim().isEmpty()) return new ValidationError(idx, name, "must not be blank");
            return null;
        });

        factories.put(Email.class, (a, name) -> {
            var ev = EmailValidator.getInstance();
            return (value, idx) -> {
                if (value == null) return null;
                if (!(value instanceof String)) return new ValidationError(idx, name, "must be a string for email validation");
                if (!ev.isValid((String) value)) return new ValidationError(idx, name, "must be a valid email address");
                return null;
            };
        });

        factories.put(Min.class, (a, name) -> {
            long min = ((Min) a).value();
            return (value, idx) -> {
                if (value == null) return null;
                if (value instanceof Number n && n.longValue() < min)
                    return new ValidationError(idx, name, String.format("must be greater than or equal to %d", min));
                return null;
            };
        });

        factories.put(Max.class, (a, name) -> {
            long max = ((Max) a).value();
            return (value, idx) -> {
                if (value == null) return null;
                if (value instanceof Number n && n.longValue() > max)
                    return new ValidationError(idx, name, String.format("must be less than or equal to %d", max));
                return null;
            };
        });

        factories.put(Size.class, (a, name) -> {
            int min = ((Size) a).min();
            int max = ((Size) a).max();
            return (value, idx) -> {
                if (value == null) return null;
                int size = 0;
                if (value instanceof String s) size = s.length();
                else if (value instanceof Collection<?> c) size = c.size();
                else if (value instanceof Map<?, ?> m) size = m.size();
                else if (value.getClass().isArray()) size = java.lang.reflect.Array.getLength(value);
                if (size < min || size > max)
                    return new ValidationError(idx, name, String.format("size must be between %d and %d", min, max));
                return null;
            };
        });

        factories.put(Pattern.class, (a, name) -> {
            var pa = (Pattern) a;
            var compiled = java.util.regex.Pattern.compile(pa.regexp());
            return (value, idx) -> {
                if (value == null) return null;
                if (!(value instanceof String)) return new ValidationError(idx, name, "must be a string for pattern matching");
                if (!compiled.matcher((String) value).matches())
                    return new ValidationError(idx, name, String.format("must match pattern '%s'", pa.regexp()));
                return null;
            };
        });

        factories.put(Positive.class, (a, name) -> numericSign(name, v -> v <= 0, "must be positive"));
        factories.put(PositiveOrZero.class, (a, name) -> numericSign(name, v -> v < 0, "must be positive or zero"));
        factories.put(Negative.class, (a, name) -> numericSign(name, v -> v >= 0, "must be negative"));
        factories.put(NegativeOrZero.class, (a, name) -> numericSign(name, v -> v > 0, "must be negative or zero"));

        factories.put(DecimalMin.class, (a, name) -> {
            var dm = (DecimalMin) a;
            double min = Double.parseDouble(dm.value());
            boolean inclusive = dm.inclusive();
            return (value, idx) -> {
                if (value == null) return null;
                if (value instanceof Number n) {
                    double v = n.doubleValue();
                    if (inclusive && v < min) return new ValidationError(idx, name,
                        String.format("must be greater than or equal to %s", dm.value()));
                    if (!inclusive && v <= min) return new ValidationError(idx, name,
                        String.format("must be greater than %s", dm.value()));
                }
                return null;
            };
        });

        factories.put(DecimalMax.class, (a, name) -> {
            var dm = (DecimalMax) a;
            double max = Double.parseDouble(dm.value());
            boolean inclusive = dm.inclusive();
            return (value, idx) -> {
                if (value == null) return null;
                if (value instanceof Number n) {
                    double v = n.doubleValue();
                    if (inclusive && v > max) return new ValidationError(idx, name,
                        String.format("must be less than or equal to %s", dm.value()));
                    if (!inclusive && v >= max) return new ValidationError(idx, name,
                        String.format("must be less than %s", dm.value()));
                }
                return null;
            };
        });

        RULE_FACTORIES = Collections.unmodifiableMap(factories);
    }

    /** Helper that builds a sign-check rule to avoid repetition for Positive/Negative variants. */
    private static ValidationRule numericSign(String paramName,
            java.util.function.DoublePredicate violates, String message) {
        return (value, idx) -> {
            if (value == null) return null;
            if (value instanceof Number n && violates.test(n.doubleValue()))
                return new ValidationError(idx, paramName, message);
            return null;
        };
    }

    // -------------------------------------------------------------------------
    // Instance state
    // -------------------------------------------------------------------------

    /** Cache: Method → (parameterIndex → rules). Built once per method. */
    private final Map<Method, Map<Integer, List<ValidationRule>>> validationCache = new ConcurrentHashMap<>();

    /**
     * Validates method parameters against Jakarta validation annotations.
     */
    public ValidationResult validate(Method method, Object[] args) {
        ValidationResult result = new ValidationResult();

        Map<Integer, List<ValidationRule>> parameterValidations =
            validationCache.computeIfAbsent(method, this::buildValidationRules);

        for (Map.Entry<Integer, List<ValidationRule>> entry : parameterValidations.entrySet()) {
            int paramIndex = entry.getKey();
            if (args == null || paramIndex >= args.length) continue;

            Object value = args[paramIndex];
            for (ValidationRule rule : entry.getValue()) {
                ValidationError error = rule.validate(value, paramIndex);
                if (error != null) result.addError(error);
            }
        }
        return result;
    }

    /**
     * Validates return value against Jakarta validation annotations on the return type.
     *
     */
    public ValidationResult validateReturnValue(Method method, Object returnValue) {
        ValidationResult result = new ValidationResult();
        for (Annotation annotation : method.getAnnotatedReturnType().getAnnotations()) {
            ValidationRule rule = createValidationRule(annotation, "return value");
            if (rule != null) {
                ValidationError error = rule.validate(returnValue, -1);
                if (error != null) result.addError(error);
            }
        }
        return result;
    }

    /**
     * Builds validation rules for a method by inspecting parameter annotations.
     * Called only once per method (cached).
     */
    private Map<Integer, List<ValidationRule>> buildValidationRules(Method method) {
        Map<Integer, List<ValidationRule>> rules = new LinkedHashMap<>();
        Parameter[] parameters = method.getParameters();
        for (int i = 0; i < parameters.length; i++) {
            List<ValidationRule> paramRules = new ArrayList<>();
            for (Annotation annotation : parameters[i].getAnnotations()) {
                ValidationRule rule = createValidationRule(annotation, parameters[i].getName());
                if (rule != null) paramRules.add(rule);
            }
            if (!paramRules.isEmpty()) rules.put(i, paramRules);
        }
        return rules;
    }

    /**
     * Creates a validation rule by looking up the annotation type in the strategy map.
     *
     * @return a rule, or {@code null} if the annotation is not a supported Jakarta constraint
     */
    private static ValidationRule createValidationRule(Annotation annotation, String paramName) {
        RuleFactory factory = RULE_FACTORIES.get(annotation.annotationType());
        return factory != null ? factory.apply(annotation, paramName) : null;
    }

    /** Clears the validation cache. Useful for testing or dynamic class reloading. */
    public void clearCache() {
        validationCache.clear();
    }

    /** Returns the current cache size. */
    public int getCacheSize() {
        return validationCache.size();
    }

    // Functional interface for validation rules
    @FunctionalInterface
    private interface ValidationRule {
        ValidationError validate(Object value, int parameterIndex);
    }

    /**
     * Represents a validation error.
     */
    public static class ValidationError {
        private final int parameterIndex;
        private final String parameterName;
        private final String message;

        public ValidationError(int parameterIndex, String parameterName, String message) {
            this.parameterIndex = parameterIndex;
            this.parameterName = parameterName;
            this.message = message;
        }

        public int getParameterIndex() {
            return parameterIndex;
        }

        public String getParameterName() {
            return parameterName;
        }

        public String getMessage() {
            return message;
        }

        @Override
        public String toString() {
            return String.format("Parameter '%s' (index %d): %s", 
                parameterName, parameterIndex, message);
        }
    }

    /**
     * Contains the result of validation.
     */
    public static class ValidationResult {
        private final List<ValidationError> errors;

        public ValidationResult() {
            this.errors = new ArrayList<>();
        }

        void addError(ValidationError error) {
            errors.add(error);
        }

        public boolean isValid() {
            return errors.isEmpty();
        }

        public List<ValidationError> getErrors() {
            return Collections.unmodifiableList(errors);
        }

        public String getErrorMessage() {
            if (isValid()) {
                return "Validation successful";
            }
            StringBuilder sb = new StringBuilder("Validation failed:\n");
            for (ValidationError error : errors) {
                sb.append("  - ").append(error.toString()).append("\n");
            }
            return sb.toString();
        }

        @Override
        public String toString() {
            return getErrorMessage();
        }
    }
}