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
package nl.esi.comma.testspecification.abstspec.generator;

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
import nl.esi.comma.expressions.expression.ExpressionPlus;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;

/**
 *
 */
public class AssertionsHelper {

	/**
	 * Filters all GenericScriptBlock items from an EList of DataAssertionItem
	 * @param assertionItemsList
	 * @return List of GenericScriptBlock objects
	 */
//	public static List<GenericScriptBlock> getScriptCalls(EList<DataAssertionItem> assertionItemsList) {

	/**
	 * Parses a list of GenericScriptBlock objects into string format.
	 * @param assertList
	 * @return String representation of a list of assertions.
	 */
//	public static String printScriptCall(List<GenericScriptBlock> scriptcallList) {
	/**
	 * Parses a script call block into a string, as in the reference.kvp format.
	 * This string representation includes a script call identifier, the path to the script,
	 * and a list of input parameters.
	 * Input parameters are formed by a type,
	 * and assigned value which may be a list, dictionary or key-value pair.
	 * @param asrt Script call block to be parsed into string
	 * @return string representation of a script call block
	 */
//	public static String parseScriptCall(GenericScriptBlock scrptcall) {

	/**
	 * Parses input parameters of a script-call, which include.
	 * - the script ID, derived from the variable to which the script result will be assigned
	 * - the path to the script to be executed
	 * - the list of input parameters,
	 * - its length, given the observed output is a string/array/map (has-size).
	 *
	 * @param params
	 * @param scrptparams
	 */
//	private static void extractScriptParameters(ScriptParametersCustom params, List<String> scrptparams) {
//	private static void extractScriptParameters_OUTPUT(String param, List<String> scrptparams) {
//	private static void extractScriptParameters_OTHERS(Expression param, List<String> scrptparams) {

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
			return Integer.toString(e.getLiteral().getValue().getValue());
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
