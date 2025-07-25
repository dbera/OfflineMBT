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
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonArray;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonBool;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonElements;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonExpression;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonFloat;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonLong;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonMember;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonObject;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonString;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.JsonValue;

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
        if (o1 instanceof JsonString && o2 instanceof JsonString) {
        	String v1 = ((JsonString) o1).getValue();
        	String v2 = ((JsonString) o2).getValue();
        	return v1.compareTo(v2);
        }
        if (o1 instanceof JsonBool && o2 instanceof JsonBool) {
        	boolean v1 = ((JsonBool) o1).isValue();
        	boolean v2 = ((JsonBool) o2).isValue();
	        return Boolean.compare(v1, v2);
        }
        if (o1 instanceof JsonFloat && o2 instanceof JsonFloat) {
        	double v1 = ((JsonFloat) o1).getValue();
        	double v2 = ((JsonFloat) o2).getValue();
        	return Double.compare(v1, v2);
        }
        if (o1 instanceof JsonLong && o2 instanceof JsonLong) {
        	double v1 = ((JsonFloat) o1).getValue();
        	double v2 = ((JsonFloat) o2).getValue();
        	return Double.compare(v1, v2);
        }
        if (o1 instanceof JsonObject && o2 instanceof JsonObject){
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
        }
        if (o1 instanceof JsonArray && o2 instanceof JsonArray){
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
}
