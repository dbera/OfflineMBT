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
package nl.esi.comma.expressions.generator

import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.types.generator.TypesCommaGenerator
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionFnCall
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionBracket

class ExpressionsCommaGenerator extends TypesCommaGenerator {
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantBool e)
	'''«e.value»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantString e)
	'''"«e.value»"'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantInt e)
	'''«e.value»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantReal e)
	'''«e.value»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionEnumLiteral e)
		'''«typeToComMASyntax(e.type) + "::" + e.literal.name»'''

	def dispatch CharSequence exprToComMASyntax(ExpressionAny e)
		'''"*"'''
	
	// Added DB for CG. 19.06.2025
	def dispatch CharSequence exprToComMASyntax(ExpressionNot e)
        '''!«exprToComMASyntax(e.getSub())»'''

    // Added DB for CG. 19.06.2025
    def dispatch CharSequence exprToComMASyntax(ExpressionBracket e)
        '''(«exprToComMASyntax(e.sub)»)'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionAddition e)
		'''«exprToComMASyntax(e.getLeft())» + «exprToComMASyntax(e.getRight())»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionSubtraction e)
		'''«exprToComMASyntax(e.getLeft())» - «exprToComMASyntax(e.getRight())»'''	
	
	def dispatch CharSequence exprToComMASyntax(ExpressionMultiply e)
		'''«exprToComMASyntax(e.getLeft())» * «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionDivision e)
		'''«exprToComMASyntax(e.getLeft())» / «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionModulo e)
		'''«exprToComMASyntax(e.getLeft())» mod «exprToComMASyntax(e.getRight())»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionMinimum e)
		'''«exprToComMASyntax(e.getLeft())» min «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionMaximum e)
		'''«exprToComMASyntax(e.getLeft())» max «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionPower e)
		'''«exprToComMASyntax(e.getLeft())» ^ «exprToComMASyntax(e.getRight())»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionGreater e)
		'''«exprToComMASyntax(e.getLeft())» > «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionLess e)
		'''«exprToComMASyntax(e.getLeft())» < «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionLeq e)
		'''«exprToComMASyntax(e.getLeft())» <= «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionGeq e)
		'''«exprToComMASyntax(e.getLeft())» >= «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionEqual e)
		'''«exprToComMASyntax(e.getLeft())» == «exprToComMASyntax(e.getRight())»'''
		
	def dispatch CharSequence exprToComMASyntax(ExpressionNEqual e)
		'''«exprToComMASyntax(e.getLeft())» != «exprToComMASyntax(e.getRight())»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionAnd e)
		'''«exprToComMASyntax(e.getLeft())» AND «exprToComMASyntax(e.getRight())»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionOr e)
		'''«exprToComMASyntax(e.getLeft())» OR «exprToComMASyntax(e.getRight())»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionRecord e)
	'''«typeToComMASyntax(e.type)»{«FOR f : e.fields SEPARATOR ', '»«f.recordField.name» = «exprToComMASyntax(f.exp)»«ENDFOR»}'''

	def dispatch CharSequence exprToComMASyntax(ExpressionRecordAccess e)
	'''«exprToComMASyntax(e.getRecord())».«e.getField().getName()»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionVariable e)
	'''«e.getVariable().getName()»'''

    // Added DB for CG. 19.06.2025
    def dispatch CharSequence exprToComMASyntax(ExpressionFnCall e)
    {
        var str = new String();
        for(Expression arg : e.getArgs()) {
            if(!str.isEmpty()) str += ", ";
            str += exprToComMASyntax(arg);
        }
        var fnName = e.getFunction().getName();
        fnName = fnName.replaceAll("_DOT_", ".");
        fnName = fnName.replaceAll("_PTR_", ".");
        fnName = fnName.replaceAll("_SCOPE_", "::");
        fnName = fnName.replaceAll("_REF_", "->");
        return fnName + "(" + str + ")";
    }

	def dispatch CharSequence exprToComMASyntax(ExpressionFunctionCall e)
	'''«getFunctionText(e)»'''

	def CharSequence getFunctionText(ExpressionFunctionCall e) {
			if (e.getFunctionName().equals("add")) {
				return String.format("add(%s,%s)", exprToComMASyntax(e.getArgs().get(0)), exprToComMASyntax(e.getArgs().get(1)))
			} else if (e.getFunctionName().equals("size")) {
				return String.format("size(%s)", exprToComMASyntax(e.getArgs().get(0)))
			} else if (e.getFunctionName().equals("isEmpty")) {
				return String.format("isEmpty(%s)", exprToComMASyntax(e.getArgs().get(0)))
			} else if (e.getFunctionName().equals("contains")) {
				return String.format("contains(%s,%s)", exprToComMASyntax(e.getArgs().get(1)), exprToComMASyntax(e.getArgs().get(0)))
			} else if (e.getFunctionName().equals("abs")) {
				return String.format("abs(%s)", exprToComMASyntax(e.getArgs().get(0)))
			} else if (e.getFunctionName().equals("asReal")) {
				return String.format("asReal(%s)", exprToComMASyntax(e.getArgs().get(0)))
			} else if (e.getFunctionName().equals("hasKey")) {
				var map = exprToComMASyntax(e.getArgs().get(0));
				var key = exprToComMASyntax(e.getArgs().get(1));
				return String.format("hasKey(%s,%s)", key, map);
			} else if (e.getFunctionName().equals("get")) { // added 18.08.2024
				var lst = exprToComMASyntax(e.getArgs().get(0));
				var idx = exprToComMASyntax(e.getArgs().get(1));
				return String.format("get(%s,%s)", lst, idx);
			} else if (e.getFunctionName().equals("deleteKey")) {
				var map = exprToComMASyntax(e.getArgs().get(0));
				var key = exprToComMASyntax(e.getArgs().get(1));
				return String.format("deleteKey(%s,%s)", map, key);
			} else if (e.getFunctionName().equals("at")) {
                var lst = exprToComMASyntax(e.getArgs().get(0));
                var idx = exprToComMASyntax(e.getArgs().get(1));
                var v = exprToComMASyntax(e.getArgs().get(2));
                return String.format("at(%s,%s,%s)", lst, idx, v);
            }	
	}

	def dispatch CharSequence exprToComMASyntax(ExpressionVector e)
	'''<«typeToComMASyntax(e.typeAnnotation.type)»>[«FOR el : e.elements SEPARATOR ', '»«exprToComMASyntax(el)»«ENDFOR»]'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionMap e)
	'''<«typeToComMASyntax(e.typeAnnotation.type)»>{«FOR el : e.pairs SEPARATOR ', '»«exprToComMASyntax(el.key)» -> «exprToComMASyntax(el.value)»«ENDFOR»}'''

	def dispatch CharSequence exprToComMASyntax(ExpressionMapRW e)
	'''«exprToComMASyntax(e.map)»[«exprToComMASyntax(e.key)»«IF e.value !== null»->«exprToComMASyntax(e.value)»«ENDIF»]'''
}