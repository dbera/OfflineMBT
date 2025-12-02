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
package nl.esi.comma.testspecification.generator.to.fast;

import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import nl.esi.comma.assertthat.assertThat.GenericScriptBlock;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionBracket;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral;
import nl.esi.comma.expressions.expression.ExpressionMapRW;
import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionNullLiteral;
//import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionPlus;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.types.types.EnumElement;
import nl.esi.comma.types.types.EnumTypeDecl;

/**
 *
 */
public class AssertionsHelper {

	/**
	 * Parses an expression into the kvp format
	 * *TODO* Adapt expression helper to FAST format
	 * @param expression expression to be parsed
	 * @return
	 */
	static String expression(Expression expression, String prefix) { 
		return expression(expression, (String t) -> String.format("%s%s",prefix,t)); 
	}
	static String expression(Expression expression) { return expression(expression, (String t) -> t); }

	static String expression(Expression expression, Function<String, String> variablePrefix) {
		if (expression instanceof ExpressionBracket e) {
			return String.format("%s", expression(e.getSub(),variablePrefix));
		} else if (expression instanceof ExpressionConstantInt e) {
			return Long.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantString pexpr) {
			return String.format("'%s'", pexpr.getValue());
		} else if (expression instanceof ExpressionConstantReal e) {
			return Double.toString(e.getValue());
		} else if (expression instanceof ExpressionEnumLiteral e) {
			EnumElement e_lite = e.getLiteral();
			if (e.getLiteral().getValue() != null) {
				return Integer.toString(e_lite.getValue().getValue());
	        }
			EnumTypeDecl e_type = e.getType();
	        return Integer.toString(e_type.getLiterals().indexOf(e_lite));
		} else if (expression instanceof ExpressionNullLiteral) {
			return "null";
		} else if (expression instanceof ExpressionConstantBool e) {
			return e.isValue() ? "True" : "False";
		} else if (expression instanceof ExpressionMinus e) {
			return String.format("-%s", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionPlus e) {
			return expression(e.getSub(), variablePrefix);
		} else if (expression instanceof ExpressionRecordAccess e) {
			String map = expression(e.getRecord(), variablePrefix);
			return String.format("%s['%s']", map, e.getField().getName());
		} else if (expression instanceof ExpressionVariable v) {
	        EObject vari = v.getVariable().eContainer();
	        if (vari instanceof GenericScriptBlock) return variablePrefix.apply("");
	        else return String.format("['%s']", variablePrefix.apply(v.getVariable().getName()));
		} else if (expression instanceof ExpressionVector e) {
			return String.format("[%s]", e.getElements().stream().map(ee -> expression (ee, variablePrefix)).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW) {
			ExpressionMapRW e = (ExpressionMapRW) expression;
			String map = expression(e.getMap(), variablePrefix);
			String key = expression(e.getKey(), variablePrefix);
			if (e.getValue() == null) {
				return String.format("%s[%s]", map, key);
			}
		}
		throw new RuntimeException("Not supported");
	}

}
