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
package nl.esi.comma.expressions.generator.dezyne
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionPower
import java.util.List
import java.util.ArrayList
import nl.esi.comma.expressions.generator.plantuml.ExpressionsUmlGenerator

class ExpressionsToDezyne {
	
	ExpressionsUmlGenerator expressionToComMA = new ExpressionsUmlGenerator("", null)
	public List<CharSequence> expressionErrors = new ArrayList
	def dispatch CharSequence generateExpression(ExpressionAddition expr) 
 	'''«generateExpression(expr.left)» + «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionAnd expr) 
    '''«generateExpression(expr.left)» && «generateExpression(expr.right)»'''
    
    def dispatch CharSequence generateExpression(ExpressionBracket expr) 
    '''(«generateExpression(expr.sub)»)'''

    def dispatch CharSequence generateExpression(ExpressionConstantBool expr) 
    '''«expr.value»'''
    
    def dispatch CharSequence generateExpression(ExpressionConstantReal expr) 
    '''«expr.value»'''

    def dispatch CharSequence generateExpression(ExpressionConstantInt expr) 
    '''«expr.value»'''
    
     def dispatch CharSequence generateExpression(ExpressionConstantString expr) 
    '''"«expr.value»" '''
            
     def dispatch CharSequence generateExpression(ExpressionAny expr){
     	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression any is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
     }

	def dispatch CharSequence generateExpression(ExpressionDivision expr){
		var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression division is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
    }

    def dispatch CharSequence generateExpression(ExpressionEqual expr) 
    '''«generateExpression(expr.left)» == «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionGeq expr) 
    '''«generateExpression(expr.left)» >= «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionGreater expr) 
    '''«generateExpression(expr.left)» > «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionLeq expr) 
    '''«generateExpression(expr.left)» <= «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionLess expr) 
    '''«generateExpression(expr.left)» < «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionMaximum expr) {
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression maximum is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
    }

    def dispatch CharSequence generateExpression(ExpressionMinimum expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression minimum is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
    } 
    
	 def dispatch CharSequence generateExpression(ExpressionModulo expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression modulo is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
    } 
    
     def dispatch CharSequence generateExpression(ExpressionPower expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression power is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
    }

    def dispatch CharSequence generateExpression(ExpressionMinus expr) 
    '''-«generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionMultiply expr) {
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''expression multiply is not supported in Dezyne - check this expresssion: «expString»''')
    	return expString
    }

    def dispatch CharSequence generateExpression(ExpressionNEqual expr) 
    '''«generateExpression(expr.left)» != «generateExpression(expr.right)»'''

    def dispatch CharSequence generateExpression(ExpressionNot expr) 
    '''! «generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionOr expr) 
    '''«generateExpression(expr.left)» || «generateExpression(expr.right)»'''
    
    def dispatch CharSequence generateExpression(ExpressionPlus expr) 
    '''+«generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionSubtraction expr) 
    '''«generateExpression(expr.left)» - «generateExpression(expr.right)»'''
    
	def dispatch CharSequence generateExpression(ExpressionVariable expr)
    '''«expr.variable.name»'''
    
    def dispatch CharSequence generateExpression(ExpressionEnumLiteral expr)
    '''«expr.type.name».«expr.literal.name»'''
    
    def dispatch CharSequence generateExpression(ExpressionRecord expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''Expression on record is not supported in Dezyne - check this expresssion: «expString»''')
    	return '''«expString»'''
    }
    
    def dispatch CharSequence generateExpression(ExpressionRecordAccess expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''Expression on record is not supported in Dezyne - check this expresssion: «expString»''')
    	return '''«expString»'''
    }
    
    def dispatch CharSequence generateExpression(ExpressionVector expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''Expression vector is not supported in Dezyne - check this expresssion: «expString»''')
    	return '''«expString»'''
    }
    def dispatch CharSequence generateExpression(ExpressionFunctionCall expr)
    '''«expr.functionName»(«FOR a : expr.args SEPARATOR ', '»«generateExpression(a)»«ENDFOR»)'''
    
    def dispatch CharSequence generateExpression(ExpressionQuantifier expr){
    	var expString = expressionToComMA.generateExpression(expr)
    	expressionErrors.add('''Expression quantifier is not supported in Dezyne - check this expresssion: «expString»''')
    	return '''«expString»'''

    }
}