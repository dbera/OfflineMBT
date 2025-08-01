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
package nl.esi.comma.abstracttestspecification.generator.to.concrete

import java.util.HashMap
import java.util.Map
import nl.esi.comma.assertthat.assertThat.JsonArray
import nl.esi.comma.assertthat.assertThat.JsonMember
import nl.esi.comma.assertthat.assertThat.JsonObject
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.comma.assertthat.assertThat.JsonExpression
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionMinus;

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
    def static String toXMLElement(JsonObject jsonObject, Map<String,String> rename)
        '''
        «FOR aMember: jsonObject.members»
        «toXMLElement(aMember, rename)»
        «ENDFOR»
        '''
    def static String toXMLElement(JsonArray jsonObject, Map<String,String> rename)
        '''
        «FOR aMember: jsonObject.values»
        «toXMLElement(aMember, rename)»
        «ENDFOR»
        '''

    /**
     * parses a json member into a "key:value" string format
     */
    def static String jsonElement(JsonMember elem)  '''"«elem.key»" : «jsonElement(elem.value)»'''
    def static String toXMLElement(JsonMember elem, Map<String,String> rename)  
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
        if (elem instanceof JsonExpression)    return AssertionsHelper.expression(elem.expr)
        if (elem instanceof JsonArray)  return jsonElement(elem as JsonArray)
        if (elem instanceof JsonObject) return jsonElement(elem as JsonObject) 
        throw new RuntimeException("Not supported");
    }
    def static boolean isBasicType(JsonValue elem) {
        switch (elem) {
            JsonExpression: {
                val expr = elem.expr
                switch (expr) {
                    ExpressionConstantString: true
                    ExpressionConstantBool: true
                    ExpressionConstantReal: true
                    ExpressionConstantInt: true
                    ExpressionMinus: {
                        val sub = expr.sub
                        switch (sub){
                            ExpressionConstantReal: true
                            ExpressionConstantInt: true
                            default: throw new RuntimeException("Not supported")
                        }
                    }
                    default: throw new RuntimeException("Not supported")
                }
            }
            JsonObject: return false 
            JsonArray: return false 
            default: throw new RuntimeException("Not supported")
        }
    }
    def static String toXMLElement(JsonValue elem) { return toXMLElement(elem, new HashMap<String,String>()); }
    def static String toXMLElement(JsonValue elem, Map<String,String> rename) {
        switch (elem) {
            JsonObject: return toXMLElement(elem, rename)
            JsonArray: return toXMLElement(elem, rename)
            JsonExpression: {
                val expr = elem.expr
                switch (expr) {
                    ExpressionConstantString: expr.value
                    ExpressionConstantBool: expr.value.toString
                    ExpressionConstantReal: expr.value.toString
                    ExpressionConstantInt: expr.value.toString
                    ExpressionMinus: {
                        val sub = expr.sub
                        switch (sub){
                            ExpressionConstantReal: '-'+sub.value.toString
                            ExpressionConstantInt: '-'+sub.value.toString
                            default: throw new RuntimeException("Not supported")
                        }
                    }
                    default: throw new RuntimeException("Not supported")
                }
            }
            default: throw new RuntimeException("Not supported")
        }
    }
}