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

package nl.esi.comma.constraints.generator.cpn;

import java.util.function.Function;

import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess;
import nl.esi.xtext.expressions.expression.ExpressionVariable;

// Same shape as SnakesHelper.expression, but prints model syntax as it appears in a TSpec
public class ReferenceHelper {

    public static String expression(Expression expression) {
        return expression(expression, Function.identity());
    }

    public static String expression(Expression expression, Function<String, String> variableRename) {
        if (expression instanceof ExpressionVariable e) {
            return String.format("%s", variableRename.apply(e.getVariable().getName()));
        } else if (expression instanceof ExpressionRecordAccess e) {
            String record = expression(e.getRecord(), variableRename);
            return String.format("%s.%s", record, e.getField().getName());
        }

        throw new RuntimeException("Not supported");
    }
}