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
package nl.esi.comma.inputspecification.generator.java

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
import nl.esi.comma.expressions.expression.Field
import nl.esi.comma.types.types.VectorTypeConstructor

class StateMachineExpressions 
{
	def static CharSequence generateDim(ExpressionVector vec) {
		var dimTxt = ''''''
		if(vec.typeAnnotation.type instanceof VectorTypeConstructor) {
			var vType = vec.typeAnnotation.type as VectorTypeConstructor
			if(vType.dimensions !== null)
				for(dim : vType.dimensions) {
					dimTxt = dimTxt + '''[]'''
				}
		}
		dimTxt
	}
	//TODO: Find a solution for this!
	def static dispatch CharSequence generateExpression(ExpressionAny expr, CharSequence ref)
	'''ANY'''
	
	def static dispatch CharSequence generateExpression(ExpressionRecordAccess expr, CharSequence ref)      
	'''«generateExpression(expr.record, ref)».«expr.field.name»'''

	// Removed Prefix: «getContainingInterfaceofType(expr.type)»::
	def static dispatch CharSequence generateExpression(ExpressionRecord expr, CharSequence ref)
	'''new «expr.type.name»(«IF !generateRecExpression(expr, ref).toString.contains('''ANY''')»«generateRecExpression(expr, ref)»«ENDIF»)'''
	//'''new «expr.type.name»(«FOR f : expr.fields SEPARATOR ", "»«generateExpression(f, ref)»«ENDFOR»)''' 

	//«JavaGeneratorUtilities::generateJavaTypeInitializer()»
	def static dispatch CharSequence generateRecExpression(ExpressionRecord expr, CharSequence ref)
	'''«FOR f : expr.fields SEPARATOR ", "»«IF generateExpression(f, ref).toString.contains('''ANY''')»«JavaGeneratorUtilities::generateJavaTypeInitializer(f.recordField.type.type)»«ELSE»«generateExpression(f, ref)»«ENDIF»«ENDFOR»'''

	def static dispatch CharSequence generateExpression(Field expr, CharSequence ref)
	'''«generateExpression(expr.exp, ref)»'''

	def static dispatch CharSequence generateExpression(ExpressionVector expr, CharSequence ref)
	'''new «JavaGeneratorUtilities::generateJavaDataType(expr.typeAnnotation.type.type)»«generateDim(expr)»{«FOR elm : expr.elements SEPARATOR " ,"»«IF elm instanceof ExpressionVector»«generateExpression(elm as ExpressionVector, ref)»«ELSE»«generateExpression(elm, ref)»«ENDIF»«ENDFOR»}''' 

	def static dispatch CharSequence generateExpression(ExpressionVariable expr, CharSequence ref)
	'''«IF JavaGeneratorUtilities::isStateMachineVariable(expr.variable)»«ref»«expr.variable.name»«ELSE»«expr.variable.name»«ENDIF»'''

	// Removed Prefix: «getContainingInterfaceofType(expr.type)»::
	def static dispatch CharSequence generateExpression(ExpressionEnumLiteral expr, CharSequence ref)      
	'''«expr.type.name».«expr.literal.name»''' 

	def static dispatch CharSequence generateExpression(ExpressionConstantString expr, CharSequence ref)      
	'''"«expr.value»"''' 

	def static dispatch CharSequence generateExpression(ExpressionConstantReal expr, CharSequence ref)      
	'''«expr.value»''' 

	def static dispatch CharSequence generateExpression(ExpressionConstantBool expr, CharSequence ref)      
	'''«expr.value»''' 

	def static dispatch CharSequence generateExpression(ExpressionNEqual expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» != «generateExpression(expr.right, ref)»)''' 
	
		def static dispatch CharSequence generateExpression(ExpressionEqual expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» == «generateExpression(expr.right, ref)»)''' 
	
		def static dispatch CharSequence generateExpression(ExpressionOr expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» || «generateExpression(expr.right, ref)»)''' 
	
		def static dispatch CharSequence generateExpression(ExpressionAnd expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» && «generateExpression(expr.right, ref)»)''' 
	
	def static dispatch CharSequence generateExpression(ExpressionGeq expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» >= «generateExpression(expr.right, ref)»)''' 

	def static dispatch CharSequence generateExpression(ExpressionGreater expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» > «generateExpression(expr.right, ref)»)''' 

	def static dispatch CharSequence generateExpression(ExpressionLeq expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» <= «generateExpression(expr.right, ref)»)''' 

	def static dispatch CharSequence generateExpression(ExpressionLess expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» < «generateExpression(expr.right, ref)»)''' 

	def static dispatch CharSequence generateExpression(ExpressionAddition expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» + «generateExpression(expr.right, ref)»)''' 
 
	def static dispatch CharSequence generateExpression(ExpressionSubtraction expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» - «generateExpression(expr.right, ref)»)'''      
	
	def static dispatch CharSequence generateExpression(ExpressionMultiply expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» * «generateExpression(expr.right, ref)»)'''      
	
	def static dispatch CharSequence generateExpression(ExpressionDivision expr, CharSequence ref)      
	'''(«generateExpression(expr.left, ref)» / «generateExpression(expr.right, ref)»)'''     
	 
	def static dispatch CharSequence generateExpression(ExpressionMaximum expr, CharSequence ref)      
	'''max(«generateExpression(expr.left, ref)», «generateExpression(expr.right, ref)»)''' 
	 
	def static dispatch CharSequence generateExpression(ExpressionMinimum expr, CharSequence ref)      
	'''min(«generateExpression(expr.left, ref)», «generateExpression(expr.right, ref)»)'''      
	
	def static dispatch CharSequence generateExpression(ExpressionModulo expr, CharSequence ref)      
	'''(fmod(«generateExpression(expr.left, ref)», «generateExpression(expr.right, ref)») >= 
	0 ? fmod(«generateExpression(expr.left, ref)», «generateExpression(expr.right, ref)») : 
	fmod(«generateExpression(expr.left, ref)», «generateExpression(expr.right, ref)») + 
	«generateExpression(expr.right, ref)»)
	''' 
	def static dispatch CharSequence generateExpression(ExpressionPower expr, CharSequence ref)      
	'''pow(«generateExpression(expr.left, ref)», «generateExpression(expr.right, ref)»)'''

	def static dispatch CharSequence generateExpression(ExpressionMinus expr, CharSequence ref)      
	'''(-«generateExpression(expr.sub, ref)»)''' 
 
	def static dispatch CharSequence generateExpression(ExpressionPlus expr, CharSequence ref)      
	'''(+«generateExpression(expr.sub, ref)»)'''
	
	def static dispatch CharSequence generateExpression(ExpressionNot expr, CharSequence ref)
	'''(!«generateExpression(expr.sub, ref)»)'''
	
	def static dispatch CharSequence generateExpression(ExpressionBracket expr, CharSequence ref)      
	'''(«generateExpression(expr.sub, ref)») '''      
	
	def static dispatch CharSequence generateExpression(ExpressionConstantInt expr, CharSequence ref)      
	'''«expr.value»'''	


    def static dispatch CharSequence generateExpression(ExpressionFunctionCall expr, CharSequence ref)
    {
    	if(expr.functionName.equals('size')) 
    		return '''(«generateExpression(expr.args.get(0), ref)».length)'''
    	else if(expr.functionName.equals('remove')) 
    		return '''smVarContainer.remove(«generateExpression(expr.args.get(0), ref)», «generateExpression(expr.args.get(1), ref)»)'''
    	else if(expr.functionName.equals('isEmpty')) 
    		return '''(«generateExpression(expr.args.get(0), ref)».length == 0)'''
    	else if(expr.functionName.equals('contains')) 
    		return '''smVarContainer.contains(«generateExpression(expr.args.get(0), ref)», «generateExpression(expr.args.get(1), ref)»)'''
    	else if(expr.functionName.equals('add')) 
    		return '''smVarContainer.add(«generateExpression(expr.args.get(0), ref)», «generateExpression(expr.args.get(1), ref)»)'''
    	else if(expr.functionName.equals('asReal')) 
    		return '''(double)(«generateExpression(expr.args.get(0), ref)»)'''
    	else if(expr.functionName.equals('abs')) 
    		return '''Math.abs(«generateExpression(expr.args.get(0), ref)»)'''
    	else 
    		return '''UNSUPPORTED FUNCTION NAME: «expr.functionName»'''
    }
    
	/*    
    '''
    «IF expr.functionName.equals('size')»(«generateExpression(expr.args.get(0), ref)».length)«ENDIF»
    «IF expr.functionName.equals('remove')»smVarContainer.remove(«generateExpression(expr.args.get(0), ref)», «generateExpression(expr.args.get(1), ref)»)«ENDIF»
    «IF expr.functionName.equals('isEmpty')»(«generateExpression(expr.args.get(0), ref)».length == 0)«ENDIF»
    «IF expr.functionName.equals('contains')»smVarContainer.contains(«generateExpression(expr.args.get(0), ref)», «generateExpression(expr.args.get(1), ref)»)«ENDIF»
    «IF expr.functionName.equals('add')»smVarContainer.add(«generateExpression(expr.args.get(0), ref)», «generateExpression(expr.args.get(1), ref)»)«ENDIF»
    «IF expr.functionName.equals('asReal')»(double)(«generateExpression(expr.args.get(0), ref)»)«ENDIF»
    «IF expr.functionName.equals('abs')»Math.abs(«generateExpression(expr.args.get(0), ref)»)«ENDIF»
    '''
    */
    
    def static dispatch CharSequence generateExpression(ExpressionQuantifier expr, CharSequence ref)
    '''
		USE_REMOVE_INSTEAD
	'''

/*
    def static dispatch CharSequence generateExpression(ExpressionFunctionCall expr, CharSequence ref)
    '''
    «IF expr.functionName.equals('size')»static_cast<int>(«generateExpression(expr.args.get(0), ref)».size())«ENDIF»
    «IF expr.functionName.equals('remove')»«generateExpression(expr.args.get(0), ref)».erase(std::remove(«generateExpression(expr.args.get(0), ref)».begin(), «generateExpression(expr.args.get(0), ref)».end(), «generateExpression(expr.args.get(1), ref)»), «generateExpression(expr.args.get(0), ref)».end())«ENDIF»
    «IF expr.functionName.equals('isEmpty')»«generateExpression(expr.args.get(0), ref)».empty()«ENDIF»
    «IF expr.functionName.equals('contains')»(std::find(«generateExpression(expr.args.get(0), ref)».begin(), «generateExpression(expr.args.get(0), ref)».end(), «generateExpression(expr.args.get(1), ref)») != «generateExpression(expr.args.get(0), ref)».end())«ENDIF»
    «IF expr.functionName.equals('add')»«generateExpression(expr.args.get(0), ref)».push_back(«generateExpression(expr.args.get(1), ref)»)«ENDIF»
    «IF expr.functionName.equals('asReal')»static_cast<double>(«generateExpression(expr.args.get(0), ref)»)«ENDIF»
    «IF expr.functionName.equals('abs')»«generateExpression(expr.args.get(0), ref)».abs()«ENDIF»
    '''
    def static dispatch CharSequence generateExpression(ExpressionQuantifier expr, CharSequence ref)
    '''
    USE_REMOVE_INSTEAD
    '''
 
*/

	
	// TODO: Obsolete for new comMA Version, All vars are Global
	/* def static isStateMachineVariable(Variable v)
	{
		return true
		/* 
		if(getContainingStateMachine(v) != "UNDEFINED") { 
			// System.out.println("RETURNING: TRUE") 
			return true
		}
		else {
			// System.out.println("RETURNING: FALSE")
			return false
		}*/
	// }

	/*def static isStateMachineVariable(Variable v)
	{
		var cIntf = EcoreUtil2.getContainerOfType(v, Interface);
		if(cIntf !== null)
		{
			if(cIntf.vars.findFirst[ e | e.name.equals(v.name)] !== null)
			{
				return true
			}	
		}
		return false
	}*/
	
	// TODO: Obsolete for new comMA Version
	/*
	def static getContainingStateMachine(Variable e)
	{
		var cIntfName = "UNDEFINED"
		var cIntf = EcoreUtil2.getContainerOfType(e, Interface);
		if(cIntf !== null)
		{
			// cIntfName = cIntf.name
			if(cIntf.vars.findFirst[ v | v.name == e.name] !== null)
			{
				cIntfName = "DEFINED"
			}
		}
		// System.out.println("DEBUG: "+e+" ==> "+cIntfName)
		cIntfName
	}
	*/

/*
	def static dispatch getContainingInterfaceofType(RecordTypeDecl e)
	{
		var cIntfName = "UNDEFINED"
		var cIntf = EcoreUtil2.getContainerOfType(e, Signature);
		if(cIntf !== null)
		{
			cIntfName = cIntf.name
		}
		cIntfName
	}

	def static dispatch getContainingInterfaceofType(EnumTypeDecl e)
	{
		var cIntfName = "UNDEFINED"
		var cIntf = EcoreUtil2.getContainerOfType(e, Signature);
		if(cIntf !== null)
		{
			cIntfName = cIntf.name
		}
		cIntfName
	}
	*/
}
