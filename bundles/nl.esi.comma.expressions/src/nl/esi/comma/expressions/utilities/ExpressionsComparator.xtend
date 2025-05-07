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
package nl.esi.comma.expressions.utilities

import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBinary
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionUnary
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.utilities.TypesComparator
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW

class ExpressionsComparator extends TypesComparator {
	
	def dispatch boolean compare(Variable v1, Variable v2){
		v1.name == v2.name && v1.type.sameAs(v2.type)
	}
	
	def dispatch boolean compare(ExpressionBinary exp1, ExpressionBinary exp2){
		exp1.left.sameAs(exp2.left) && exp1.right.sameAs(exp2.right)
	}
	
	def dispatch boolean compare(ExpressionUnary exp1, ExpressionUnary exp2){
		exp1.sub.sameAs(exp2.sub)
	}
	
	def dispatch boolean compare(ExpressionRecordAccess exp1, ExpressionRecordAccess exp2){
		exp1.record.sameAs(exp2.record) && (exp1.field === exp2.field)
	}
	
	def dispatch boolean compare(ExpressionBracket exp1, ExpressionBracket exp2){
		exp1.sub.sameAs(exp2.sub)
	}
	
	def dispatch boolean compare(ExpressionConstantBool exp1, ExpressionConstantBool exp2){
		exp1.value == exp2.value
	}
	
	def dispatch boolean compare(ExpressionConstantInt exp1, ExpressionConstantInt exp2){
		exp1.value == exp2.value
	}
	
	def dispatch boolean compare(ExpressionConstantReal exp1, ExpressionConstantReal exp2){
		exp1.value == exp2.value
	}
	
	def dispatch boolean compare(ExpressionConstantString exp1, ExpressionConstantString exp2){
		exp1.value == exp2.value
	}
	
	def dispatch boolean compare(ExpressionEnumLiteral exp1, ExpressionEnumLiteral exp2){
		exp1.type === exp2.type && exp1.literal === exp2.literal
	}
	
	def dispatch boolean compare(ExpressionVariable exp1, ExpressionVariable exp2){
		exp1.variable.sameAs(exp2.variable)
	}
	
	def dispatch boolean compare(ExpressionRecord exp1, ExpressionRecord exp2){
		if(exp1.type !== exp2.type) return false
		compareLists(exp1.fields.map[exp], exp2.fields.map[exp])
	}
	
	def dispatch boolean compare(ExpressionVector exp1, ExpressionVector exp2){
		if(! exp1.typeAnnotation.type.sameAs(exp2.typeAnnotation.type)) return false
		exp1.elements.compareLists(exp2.elements) 
	}
	
	def dispatch boolean compare(ExpressionMap exp1, ExpressionMap exp2){
		if(! exp1.typeAnnotation.type.sameAs(exp2.typeAnnotation.type)) return false
		exp1.pairs.compareLists(exp2.pairs) 
	}
	
	def dispatch boolean compare(nl.esi.comma.expressions.expression.Pair exp1, nl.esi.comma.expressions.expression.Pair exp2){
		exp1.key.sameAs(exp2.key) &&
		exp1.value.sameAs(exp2.value)
	}
	
	def dispatch boolean compare(ExpressionMapRW exp1, ExpressionMapRW exp2){
		exp1.map.sameAs(exp2.map) &&
		exp1.key.sameAs(exp2.key) &&
		exp1.value.sameAs(exp2.value)
	}
	
	def dispatch boolean compare(ExpressionBulkData exp1, ExpressionBulkData exp2){
		exp1.size == exp2.size
	}
	
	def dispatch boolean compare(ExpressionAny exp1, ExpressionAny exp2){
		true
	}
	
	def dispatch boolean compare(ExpressionFunctionCall exp1, ExpressionFunctionCall exp2){
		if(exp1.functionName != exp2.functionName) return false
		compareLists(exp1.args, exp2.args)
	}
	
	def dispatch boolean compare(ExpressionQuantifier exp1, ExpressionQuantifier exp2){
		exp1.quantifier === exp2.quantifier &&
		exp1.iterator.sameAs(exp2.iterator) &&
		exp1.collection.sameAs(exp2.collection) &&
		exp1.condition.sameAs(exp2.condition)
	}
}