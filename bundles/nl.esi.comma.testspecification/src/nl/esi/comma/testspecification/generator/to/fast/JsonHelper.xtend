/**
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
package nl.esi.comma.testspecification.generator.to.fast

import nl.esi.comma.assertthat.assertThat.JsonArray
import nl.esi.comma.assertthat.assertThat.JsonMember
import nl.esi.comma.assertthat.assertThat.JsonObject
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.testspecification.testspecification.TSJsonMember
import nl.esi.comma.testspecification.testspecification.TSJsonObject
import nl.esi.comma.testspecification.testspecification.TSJsonArray
import nl.esi.comma.testspecification.testspecification.TSJsonValue
import nl.esi.comma.testspecification.testspecification.TSJsonString
import nl.esi.comma.testspecification.testspecification.TSJsonBool
import nl.esi.comma.testspecification.testspecification.TSJsonFloat
import nl.esi.comma.testspecification.testspecification.TSJsonLong
import java.util.Map
import java.util.HashMap

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
    def static String jsonElement(JsonObject jsonObject) {
        return '''
        {
            «FOR aMember: jsonObject.members SEPARATOR ","»
                «jsonElement(aMember)»
            «ENDFOR»
        }'''
    }
    def static String toXMLElement(TSJsonObject jsonObject, Map<String,String> rename)
        '''
        «FOR aMember: jsonObject.members»
        «toXMLElement(aMember, rename)»
        «ENDFOR»
        '''
    def static String toXMLElement(TSJsonArray jsonObject, Map<String,String> rename)
        '''
        «FOR aMember: jsonObject.values»
        «toXMLElement(aMember, rename)»
        «ENDFOR»
        '''

    /**
     * parses a json member into a "key:value" string format
     */
    def static String jsonElement(JsonMember elem)  '''"«elem.key»" : «jsonElement(elem.value)»'''
    def static String toXMLElement(TSJsonMember elem, Map<String,String> rename)  
        '''
        «val elemKey = rename.getOrDefault(elem.key,elem.key)»
        «IF (isBasicType(elem.value) && elem.value !== null)  »
        <«elemKey»>«toXMLElement(elem.value, rename)»</«elemKey»>
        «ELSE»
        <«elemKey»>
            «toXMLElement(elem.value, rename)»
        </«elemKey»>
        «ENDIF»
        '''

    /**
     * Parses an array of json elements into string format.
     */
    def static String jsonElement(JsonArray elem) {
        return '''
        [
            «FOR element : elem.values SEPARATOR ","»
            	«jsonElement(element)»
            «ENDFOR»
        ]'''
    }

    /**
     * Parses a json value, which can be an expression, or a json array or object.
     * Anything else will throw an exception
     * @param elem
     * @return
     */
    def static String jsonElement(JsonValue elem) {
        if (elem.expr instanceof Expression)    return AssertionsHelper.expression(elem.expr)
        if (elem.jsonArr instanceof JsonArray)  return jsonElement(elem.jsonArr)
        if (elem.jsonObj instanceof JsonObject) return jsonElement(elem.jsonObj) 
        throw new RuntimeException("Not supported");
    }
    def static boolean isBasicType(TSJsonValue elem) {
        switch (elem) {
            TSJsonString: return true
            TSJsonBool:   return true
            TSJsonFloat:  return true
            TSJsonLong:  return true
            TSJsonObject: return false 
            TSJsonArray: return false 
        	default: throw new RuntimeException("Not supported")
    	}
	}
    def static String toXMLElement(TSJsonValue elem) { return toXMLElement(elem, new HashMap<String,String>()); }
    def static String toXMLElement(TSJsonValue elem, Map<String,String> rename) {
        switch (elem) {
            TSJsonString: return elem.value
            TSJsonBool:   return elem.value.toString
            TSJsonFloat:  return elem.value.toString
            TSJsonLong:  return elem.value.toString
            TSJsonObject: return toXMLElement(elem, rename)
            TSJsonArray: return toXMLElement(elem, rename)
        	default: throw new RuntimeException("Not supported")
    	}
    }
}