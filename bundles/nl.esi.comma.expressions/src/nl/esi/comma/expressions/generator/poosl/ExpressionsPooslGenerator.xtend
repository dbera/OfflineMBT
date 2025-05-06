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
package nl.esi.comma.expressions.generator.poosl

import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionBulkData
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
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW
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
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.validation.ExpressionValidator
import nl.esi.comma.types.generator.poosl.TypesPooslGenerator
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.generator.IFileSystemAccess

abstract class ExpressionsPooslGenerator extends TypesPooslGenerator {
	protected static final String VAR_NAME_PREFIX = "commaVar_" //prefix for global variables
	protected static final String TVAR_NAME_PREFIX = "commaTVar_" //prefix for transition parameters
	protected static final String QVAR_NAME_PREFIX = "commaQVar_" //prefix for quantifier iterator variables
	
	new(String fileName, IFileSystemAccess fsa) {
		super(fileName, fsa)
	}
	
	def dispatch CharSequence generateExpression(ExpressionAddition expr) 
 	'''(«generateExpression(expr.left)» + «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionAnd expr) 
    '''(«generateExpression(expr.left)» & «generateExpression(expr.right)»)'''
    
    def dispatch CharSequence generateExpression(ExpressionBracket expr) 
    '''(«generateExpression(expr.sub)») '''

    def dispatch CharSequence generateExpression(ExpressionConstantBool expr) 
    '''«expr.value»'''
    
    def dispatch CharSequence generateExpression(ExpressionConstantReal expr) 
    '''«expr.value»f'''

    def dispatch CharSequence generateExpression(ExpressionConstantInt expr) 
    '''«expr.value»'''
    
    def dispatch CharSequence generateExpression(ExpressionConstantString expr) 
    '''"«expr.value»"'''
    
    def dispatch CharSequence generateExpression(ExpressionAny expr) 
    '''new(«COMMA_PREFIX»Any)'''

	def dispatch CharSequence generateExpression(ExpressionDivision expr) 
    '''(«generateExpression(expr.left)» / «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionEqual expr) 
    '''(«generateExpression(expr.left)» = «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionGeq expr) 
    '''(«generateExpression(expr.left)» >= «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionGreater expr) 
    '''(«generateExpression(expr.left)» > «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionLeq expr) 
    '''(«generateExpression(expr.left)» <= «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionLess expr) 
    '''(«generateExpression(expr.left)» < «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionMaximum expr) 
    '''((«generateExpression(expr.left)») max(«generateExpression(expr.right)»))'''

    def dispatch CharSequence generateExpression(ExpressionMinimum expr) 
    '''((«generateExpression(expr.left)») min(«generateExpression(expr.right)»))'''

    def dispatch CharSequence generateExpression(ExpressionMinus expr) 
    '''(-«generateExpression(expr.sub)»)'''

    def dispatch CharSequence generateExpression(ExpressionModulo expr) 
    '''((«generateExpression(expr.left)») modulo(«generateExpression(expr.right)»))'''

    def dispatch CharSequence generateExpression(ExpressionMultiply expr) 
    '''(«generateExpression(expr.left)» * «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionNEqual expr) 
    '''(«generateExpression(expr.left)» != «generateExpression(expr.right)»)'''

    def dispatch CharSequence generateExpression(ExpressionNot expr) 
    '''(«generateExpression(expr.sub)» not)'''

    def dispatch CharSequence generateExpression(ExpressionOr expr) 
    '''(«generateExpression(expr.left)» | «generateExpression(expr.right)»)'''
    
    def dispatch CharSequence generateExpression(ExpressionPlus expr) 
    '''«generateExpression(expr.sub)»'''

    def dispatch CharSequence generateExpression(ExpressionPower expr) 
    '''((«generateExpression(expr.left)») power(«generateExpression(expr.right)»))'''

    def dispatch CharSequence generateExpression(ExpressionSubtraction expr) 
    '''(«generateExpression(expr.left)» - «generateExpression(expr.right)»)'''
    
    def dispatch CharSequence generateExpression(ExpressionVariable expr){
    	val varRef = generateVariableReference(expr)
    	if(TypeUtilities::isStructuredType(expr.variable.type))
    		'''«varRef» deepCopy'''
    	else
    		varRef
    }
    
    /*
     * All variables appear in the generated POOSL code with their name preceded by a prefix
     * derived from the variable scope
     */
    def CharSequence generateVariableReference(ExpressionVariable expr){
    	switch(expr.variable.commaScope){
    		case GLOBAL: if(expr.commaScope == CommaScope::GLOBAL || expr.commaScope == CommaScope::QUANTIFIER) 
    						'''«VAR_NAME_PREFIX»«expr.variable.name»'''
    					 else
    						'''stateOfDecisionClass get_«VAR_NAME_PREFIX»«expr.variable.name»'''
    		case TRANSITION : '''«TVAR_NAME_PREFIX»«expr.variable.name»'''
    		case QUANTIFIER : '''«QVAR_NAME_PREFIX»«expr.variable.name»'''
    	}
    }
    
    def dispatch CharSequence generateExpression(ExpressionEnumLiteral expr)
    '''new(«COMMA_PREFIX»EnumerationValue) init setLiteral("«expr.type.name»::«expr.literal.name»")'''
    
    def dispatch CharSequence generateExpression(ExpressionBulkData expr)
    '''new(«COMMA_PREFIX»BulkData) setSize(«expr.size»)'''
    
    def dispatch CharSequence generateExpression(ExpressionRecord expr)
    '''new(«determineRecordTypePrefix(expr.type)»«expr.type.name») «FOR f : expr.fields»set_«f.recordField.name»(«generateExpression(f.exp)») «ENDFOR»'''
    
    def dispatch CharSequence generateExpression(ExpressionRecordAccess expr)
    '''«generateExpression(expr.record)» get_«expr.field.name»()'''
    
    def dispatch CharSequence generateExpression(ExpressionVector expr)
    '''new(«COMMA_PREFIX»Vector) init «FOR e : expr.elements»add(«generateExpression(e)») «ENDFOR»'''
    
    //TODO if we have a variable of type vector we will have a copy of it. This is a reason to perform 
    //deepCopy in a context, if needed
    def dispatch CharSequence generateExpression(ExpressionFunctionCall expr)
    '''
    «IF expr.functionName.equals('isEmpty')»«generateExpression(expr.args.get(0))» isEmpty«ENDIF»
    «IF expr.functionName.equals('size')»«generateExpression(expr.args.get(0))» size«ENDIF»
    «IF expr.functionName.equals('contains')»«generateExpression(expr.args.get(0))» includes(«generateExpression(expr.args.get(1))»)«ENDIF»
    «IF expr.functionName.equals('add')»«generateExpression(expr.args.get(0))» deepCopy add(«generateExpression(expr.args.get(1))»)«ENDIF»
    «IF expr.functionName.equals('asReal')»((«generateExpression(expr.args.get(0))») asFloat)«ENDIF»
    «IF expr.functionName.equals('abs')»((«generateExpression(expr.args.get(0))») abs)«ENDIF»
    «IF expr.functionName.equals('length')»((«generateExpression(expr.args.get(0))») getSize)«ENDIF»
    «IF expr.functionName.equals('hasKey')»((«generateExpression(expr.args.get(0))») includesKey(«generateExpression(expr.args.get(1))»))«ENDIF»
    «IF expr.functionName.equals('deleteKey')»(«generateExpression(expr.args.get(0))» clone removeAt(«generateExpression(expr.args.get(1))»))«ENDIF»
    '''
    
    def dispatch CharSequence generateExpression(ExpressionMap expr)
	'''new(Map) clear«FOR p : expr.pairs» putAt(«generateExpression(p.key)», «generateExpression(p.value)»)«ENDFOR»'''
	
	def dispatch CharSequence generateExpression(ExpressionMapRW expr)
	'''«IF expr.value !== null»«generateMapUpdate(expr)»«ELSE»«generateMapAccess(expr)»«ENDIF»'''
	
	def CharSequence generateMapUpdate(ExpressionMapRW expr)
	'''«generateExpression(expr.map)» clone putAt(«generateExpression(expr.key)», «generateExpression(expr.value)»)'''
	
	def CharSequence generateMapAccess(ExpressionMapRW expr){
		var mapType = ExpressionValidator.typeOf(expr.map)
		'''if «generateExpression(expr.map)» includesKey(«generateExpression(expr.key)») then «generateExpression(expr.map)» at(«generateExpression(expr.key)») else «generateDefaultValue(TypeUtilities::getValueType(mapType))» fi'''
	}
	
    //utility function do determine the scope of an expression
	//concrete languages that use Expressions sub-language are expected to override the definition
	def abstract CommaScope getCommaScope(EObject o) 
		
}