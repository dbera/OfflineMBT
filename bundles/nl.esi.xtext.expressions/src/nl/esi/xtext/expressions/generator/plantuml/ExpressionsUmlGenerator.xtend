/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.generator.plantuml

import nl.esi.xtext.expressions.expression.ExpressionAddition
import nl.esi.xtext.expressions.expression.ExpressionAnd
import nl.esi.xtext.expressions.expression.ExpressionAny
import nl.esi.xtext.expressions.expression.ExpressionBracket
import nl.esi.xtext.expressions.expression.ExpressionConstantBool
import nl.esi.xtext.expressions.expression.ExpressionConstantInt
import nl.esi.xtext.expressions.expression.ExpressionConstantReal
import nl.esi.xtext.expressions.expression.ExpressionConstantString
import nl.esi.xtext.expressions.expression.ExpressionDivision
import nl.esi.xtext.expressions.expression.ExpressionEnumLiteral
import nl.esi.xtext.expressions.expression.ExpressionEqual
import nl.esi.xtext.expressions.expression.ExpressionFunctionCall
import nl.esi.xtext.expressions.expression.ExpressionGeq
import nl.esi.xtext.expressions.expression.ExpressionGreater
import nl.esi.xtext.expressions.expression.ExpressionLeq
import nl.esi.xtext.expressions.expression.ExpressionLess
import nl.esi.xtext.expressions.expression.ExpressionMap
import nl.esi.xtext.expressions.expression.ExpressionMapRW
import nl.esi.xtext.expressions.expression.ExpressionMaximum
import nl.esi.xtext.expressions.expression.ExpressionMinimum
import nl.esi.xtext.expressions.expression.ExpressionMinus
import nl.esi.xtext.expressions.expression.ExpressionModulo
import nl.esi.xtext.expressions.expression.ExpressionMultiply
import nl.esi.xtext.expressions.expression.ExpressionNEqual
import nl.esi.xtext.expressions.expression.ExpressionNot
import nl.esi.xtext.expressions.expression.ExpressionOr
import nl.esi.xtext.expressions.expression.ExpressionPlus
import nl.esi.xtext.expressions.expression.ExpressionPower
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess
import nl.esi.xtext.expressions.expression.ExpressionSubtraction
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.expressions.expression.ExpressionVector
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.xtext.types.generator.XPlusGenerator

class ExpressionsUmlGenerator extends XPlusGenerator{	
	
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
    '''call «expr.function.name»(«FOR a : expr.args SEPARATOR ', '»«generateExpression(a)»«ENDFOR»)'''
    
}