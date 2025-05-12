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
package nl.esi.comma.expressions.generator.plantuml

import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.types.generator.CommaGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW

class ExpressionsUmlGenerator extends CommaGenerator{	
	
	new(String fileName, IFileSystemAccess fsa) {
		super(fileName, fsa)
	}
	
	def dispatch CharSequence generateExpression(ExpressionAddition expr) 
 	'''«generateExpression(expr.left)» + «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionAnd expr) 
    '''«generateExpression(expr.left)» and «generateExpression(expr.right)»'''
    
    def dispatch CharSequence generateExpression(ExpressionBracket expr) 
    '''(«generateExpression(expr.sub)»)'''

    def dispatch CharSequence generateExpression(ExpressionConstantBool expr) 
    '''«expr.value»'''
    
    def dispatch CharSequence generateExpression(ExpressionConstantReal expr) 
    '''«expr.value»'''

    def dispatch CharSequence generateExpression(ExpressionConstantInt expr) 
    '''«expr.value»'''
    
     def dispatch CharSequence generateExpression(ExpressionConstantString expr) 
    ''''«expr.value»' '''
            
     def dispatch CharSequence generateExpression(ExpressionAny expr) 
    '''*'''
    
    def dispatch CharSequence generateExpression(ExpressionBulkData expr)
    '''bulkdata'''

	def dispatch CharSequence generateExpression(ExpressionDivision expr) 
    '''«generateExpression(expr.left)» / «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionEqual expr) 
    '''«generateExpression(expr.left)» = «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionGeq expr) 
    '''«generateExpression(expr.left)» >= «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionGreater expr) 
    '''«generateExpression(expr.left)» > «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionLeq expr) 
    '''«generateExpression(expr.left)» <= «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionLess expr) 
    '''«generateExpression(expr.left)» < «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionMaximum expr) 
    '''max(«generateExpression(expr.left)», «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionMinimum expr) 
    '''min(«generateExpression(expr.left)», «generateExpression(expr.right)»)'''
    
	 def dispatch CharSequence generateExpression(ExpressionModulo expr) 
    '''(«generateExpression(expr.left)» mod «generateExpression(expr.right)»)'''    
    
     def dispatch CharSequence generateExpression(ExpressionPower expr) 
    '''«generateExpression(expr.left)» ^ «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionMinus expr) 
    '''-«generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionMultiply expr) 
    '''«generateExpression(expr.left)» * «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionNEqual expr) 
    '''«generateExpression(expr.left)» != «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionNot expr) 
    '''not «generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionOr expr) 
    '''«generateExpression(expr.left)» or «generateExpression(expr.right)»'''
    
    def dispatch CharSequence generateExpression(ExpressionPlus expr) 
    '''+«generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionSubtraction expr) 
    '''«generateExpression(expr.left)» - «generateExpression(expr.right)»'''
    
	def dispatch CharSequence generateExpression(ExpressionVariable expr)
    '''«expr.variable.name»'''
    
    def dispatch CharSequence generateExpression(ExpressionEnumLiteral expr)
    '''«expr.type.name»::«expr.literal.name»'''
    
    def dispatch CharSequence generateExpression(ExpressionRecord expr)
    '''«expr.type.name»{«FOR f : expr.fields SEPARATOR ', '»«f.recordField.name» = «generateExpression(f.exp)»«ENDFOR»}'''
    
    def dispatch CharSequence generateExpression(ExpressionRecordAccess expr)
    '''«generateExpression(expr.record)».«expr.field.name»'''
    
    def dispatch CharSequence generateExpression(ExpressionVector expr)
    '''[«FOR e : expr.elements SEPARATOR ', '»«generateExpression(e)»«ENDFOR»]'''
    
    def dispatch CharSequence generateExpression(ExpressionMap expr)
    '''{«FOR e : expr.pairs SEPARATOR ', '»«generateExpression(e.key)» -> «generateExpression(e.value)»«ENDFOR»}'''
    
    def dispatch CharSequence generateExpression(ExpressionMapRW expr)
    '''«generateExpression(expr.map)»[«generateExpression(expr.key)»«IF expr.value !== null»->«generateExpression(expr.value)»«ENDIF»]'''
    
    def dispatch CharSequence generateExpression(ExpressionFunctionCall expr)
    '''«expr.functionName»(«FOR a : expr.args SEPARATOR ', '»«generateExpression(a)»«ENDFOR»)'''
    
    def dispatch CharSequence generateExpression(ExpressionQuantifier expr)
    '''«expr.quantifier»(«expr.iterator.name» in «generateExpression(expr.collection)» : «generateExpression(expr.condition)»)'''
}