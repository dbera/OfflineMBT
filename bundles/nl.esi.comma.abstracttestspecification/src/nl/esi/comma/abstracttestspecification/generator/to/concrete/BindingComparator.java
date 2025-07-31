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
package nl.esi.comma.abstracttestspecification.generator.to.concrete;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding;
import nl.esi.comma.assertthat.assertThat.JsonArray;
import nl.esi.comma.assertthat.assertThat.JsonExpression;
import nl.esi.comma.assertthat.assertThat.JsonMember;
import nl.esi.comma.assertthat.assertThat.JsonObject;
import nl.esi.comma.assertthat.assertThat.JsonValue;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionMinus;

public class BindingComparator implements Comparator<Binding>{
	
	CompareJsonValues compareJson = new CompareJsonValues();
	
	@Override
	public int compare(Binding o1, Binding o2) {
		return compareJson.compare(o1.getJsonvals(), o2.getJsonvals());
	}
}

class CompareJsonValues implements Comparator<JsonValue>{
	
	@Override 
    public int compare(JsonValue o1, JsonValue o2) {
        if (o1 instanceof JsonExpression && o2 instanceof JsonExpression) {
        	Expression e1 = ((JsonExpression)o1).getExpr();
			Expression e2 = ((JsonExpression)o2).getExpr();
			return compareExpressions(e1, e2);
        } else if (o1 instanceof JsonObject && o2 instanceof JsonObject){
        	Map<String, List<JsonMember>> v1 = ((JsonObject) o1).getMembers().stream().collect(Collectors.groupingBy(JsonMember::getKey));
        	Map<String, List<JsonMember>> v2 = ((JsonObject) o2).getMembers().stream().collect(Collectors.groupingBy(JsonMember::getKey));
        	if(!v1.keySet().equals(v2.keySet())) return -1;
        	for (String k1 : v1.keySet()) {
        		if (v1.get(k1).size() != 1) return -1;
        		if (v2.get(k1).size() != 1) return -1;
        		JsonMember i1 = v1.get(k1).getFirst();
        		JsonMember i2 = v2.get(k1).getFirst();
        		return this.compare(i1.getValue(), i2.getValue());
            }
        } else if (o1 instanceof JsonArray && o2 instanceof JsonArray){
        	List<JsonValue> a1 = ((JsonArray) o1).getValues().stream().collect(Collectors.toList());
        	List<JsonValue> a2 = ((JsonArray) o2).getValues().stream().collect(Collectors.toList());
                for (JsonValue i1 : a1) {
                    var somethingEqual = false;
                    for (JsonValue i2 : a2) {
                    	if (compare(i1,i2) == 0){
                    	    somethingEqual = true; break;
                    	}
                    }
                    if (!somethingEqual) return -1;
                }
                return 0;
        }
        return -1;
    }

    public static int compareExpressions(Expression e1, Expression e2) {
        if (e1 instanceof ExpressionConstantString && e2 instanceof ExpressionConstantString) {
            return compareStrings((ExpressionConstantString) e1, (ExpressionConstantString) e2);
        }
        if (e1 instanceof ExpressionConstantBool && e2 instanceof ExpressionConstantBool) {
            return compareBooleans((ExpressionConstantBool) e1, (ExpressionConstantBool) e2);
        }
        if (e1 instanceof ExpressionConstantReal && e2 instanceof ExpressionConstantReal) {
            return compareDoubles((ExpressionConstantReal) e1, (ExpressionConstantReal) e2);
        }
        if (e1 instanceof ExpressionConstantInt && e2 instanceof ExpressionConstantInt) {
            return compareLongs((ExpressionConstantInt) e1, (ExpressionConstantInt) e2);
        }
        if (e1 instanceof ExpressionMinus && e2 instanceof ExpressionMinus) {
            return compareMinus((ExpressionMinus) e1, (ExpressionMinus) e2);
        }
        throw new IllegalArgumentException("Unsupported expression types: " + e1.getClass() + ", " + e2.getClass());
    }

    private static int compareStrings(ExpressionConstantString e1, ExpressionConstantString e2) { 
    	return e1.getValue().compareTo(e2.getValue());
    }

    private static int compareBooleans(ExpressionConstantBool e1, ExpressionConstantBool e2) {
        return Boolean.compare(e1.isValue(), e2.isValue());
    }

    private static int compareDoubles(ExpressionConstantReal e1, ExpressionConstantReal e2) {
        return Double.compare(e1.getValue(), e2.getValue());
    }

    private static int compareLongs(ExpressionConstantInt e1, ExpressionConstantInt e2) {
        return Long.compare(e1.getValue(), e2.getValue());
    }

    private static int compareMinus(ExpressionMinus e1, ExpressionMinus e2) {
        // Assuming Expression implements Comparable or you have a way to compare them
        return compareExpressions(e1.getSub(), e2.getSub());
    }

}
