package nl.esi.comma.testspecification.abstspec.generator

import nl.esi.comma.assertthat.assertThat.JsonArray
import nl.esi.comma.assertthat.assertThat.JsonMember
import nl.esi.comma.assertthat.assertThat.JsonObject
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.comma.expressions.expression.Expression

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

    /**
     * parses a json member into a "key:value" string format
     */
    def static String jsonElement(JsonMember elem)  '''"«elem.key»" : «jsonElement(elem.value)»'''

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
}