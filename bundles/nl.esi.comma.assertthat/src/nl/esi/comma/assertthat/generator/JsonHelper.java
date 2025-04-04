/*
 * Copyright (c) 2021 Contributors to the Eclipse Foundation
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.comma.assertthat.generator;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;

import nl.esi.comma.actions.actions.Action;
import nl.esi.comma.actions.actions.AssignmentAction;
import nl.esi.comma.actions.actions.CommandReply;
import nl.esi.comma.actions.actions.EventCall;
import nl.esi.comma.actions.actions.ForAction;
import nl.esi.comma.actions.actions.IfAction;
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction;
import nl.esi.comma.assertthat.assertThat.JsonArray;
import nl.esi.comma.assertthat.assertThat.JsonElements;
import nl.esi.comma.assertthat.assertThat.JsonMember;
import nl.esi.comma.assertthat.assertThat.JsonObject;
import nl.esi.comma.assertthat.assertThat.JsonValue;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionAddition;
import nl.esi.comma.expressions.expression.ExpressionAnd;
import nl.esi.comma.expressions.expression.ExpressionAny;
import nl.esi.comma.expressions.expression.ExpressionBracket;
import nl.esi.comma.expressions.expression.ExpressionBulkData;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionDivision;
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral;
import nl.esi.comma.expressions.expression.ExpressionEqual;
import nl.esi.comma.expressions.expression.ExpressionFunctionCall;
import nl.esi.comma.expressions.expression.ExpressionGeq;
import nl.esi.comma.expressions.expression.ExpressionGreater;
import nl.esi.comma.expressions.expression.ExpressionLeq;
import nl.esi.comma.expressions.expression.ExpressionLess;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionMapRW;
import nl.esi.comma.expressions.expression.ExpressionMaximum;
import nl.esi.comma.expressions.expression.ExpressionMinimum;
import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionModulo;
import nl.esi.comma.expressions.expression.ExpressionMultiply;
import nl.esi.comma.expressions.expression.ExpressionNEqual;
import nl.esi.comma.expressions.expression.ExpressionNot;
import nl.esi.comma.expressions.expression.ExpressionOr;
import nl.esi.comma.expressions.expression.ExpressionPlus;
import nl.esi.comma.expressions.expression.ExpressionPower;
import nl.esi.comma.expressions.expression.ExpressionQuantifier;
import nl.esi.comma.expressions.expression.ExpressionRecord;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.expression.ExpressionSubtraction;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.expressions.expression.QUANTIFIER;
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator;

/**
 * Parser for json elements, objects, and arrays
 */
class JsonHelper {

	/**
	 * Parses a json object, which includes a series of string-typed keys, and 
	 * a json value (which can be another json object, an array or expression)
	 * @param elem
	 * @return
	 */
	public static String jsonElement(JsonObject elem) {
		String jsonFormat = "{\r\n%s\r\n}";

		List<String> membersListStr = new ArrayList<>();
		for (JsonMember jsonMember : elem.getMembers()) {
			membersListStr.add(jsonElement(jsonMember));
		}
		String listFormatted = String.join(",",membersListStr);
		
		String jsonFormatted = jsonFormat.formatted(listFormatted);
		return jsonFormatted;
	}

	/**
	 * parses a json member into a "key:value" string format
	 * @param elem
	 * @return
	 */
	public static String jsonElement(JsonMember elem) {
		String jsonFormat = "\"%s\" : %s";
		String jsonFormatted = jsonFormat.formatted(elem.getKey(), jsonElement(elem.getValue()));
		return jsonFormatted;
	}
	
	/**
	 * Parses an array of json elements into string.
	 * @param elem
	 * @return
	 */
	public static String jsonElement(JsonArray elem) {
		String jsonFormat = "[%s]";
		List<String> membersListStr = new ArrayList<>();
		for (JsonValue jsonValue : elem.getValues()) {
			membersListStr.add(jsonElement(jsonValue));
		}
		String listFormatted = String.join(",",membersListStr);
		
		String jsonFormatted = jsonFormat.formatted(listFormatted);
		return jsonFormatted;
	}

	
	/**
	 * Parses a json value, which can be an expression, or a json array or object.
	 * Anything else will throw an exception
	 * @param elem
	 * @return
	 */
	public static String jsonElement(JsonValue elem) {
		if (elem.getExpr() instanceof Expression) { return AssertionsHelper.expression(elem.getExpr(), t->t); }
		if (elem.getJsonArr() instanceof JsonArray) { return jsonElement(elem.getJsonArr()); }
		if (elem.getJsonObj() instanceof JsonObject) { return jsonElement(elem.getJsonObj()); } 
		
		throw new RuntimeException("Not supported");
	}
	
	/**
	 * Parses a json value, which can be an expression, or a json array or object.
	 * Anything else will throw an exception
	 * @param elem
	 * @return
	 */
	public static String jsonElement(JsonElements elem) {
		if (elem instanceof JsonObject) { return jsonElement((JsonObject)elem); } 
		if (elem instanceof JsonMember) { return jsonElement((JsonMember)elem); } 
		if (elem instanceof JsonArray) { return jsonElement((JsonArray)elem); }
		
		throw new RuntimeException("Not supported");
	}
	
}

