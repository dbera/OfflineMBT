package nl.esi.comma.inputspecification.generator.java

import java.util.ArrayList
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Expression

class JavaGeneratorUtilities 
{
	def static CharSequence generateJavaTypeInitializer(TypeDecl typ) {
		if(typ instanceof SimpleTypeDecl) {
			if(generateJavaDataType(typ).toString.equals("String")) return '''"EMPTY"'''
			if(generateJavaDataType(typ).toString.equals("double")) return '''0.0'''
			if(generateJavaDataType(typ).toString.equals("boolean")) return '''true'''
			if(generateJavaDataType(typ).toString.equals("int")) return '''0'''
			return '''new «generateJavaDataType(typ)»()'''
		}
		else if(typ instanceof EnumTypeDecl) return '''null'''
		else if(typ instanceof VectorTypeDecl) return '''new «generateJavaDataType(typ)»{}'''
		else return '''new «generateJavaDataType(typ)»()'''
	}
		
	def static CharSequence generateJavaDataType(TypeDecl type) {
		if(type instanceof SimpleTypeDecl) {
			if(type.base !== null) return '''«generateSimpleJavaDataType(type.base)»'''
			else return '''«generateSimpleJavaDataType(type)»'''
		}
		else if(type instanceof VectorTypeDecl) {
			//if(type.constructor.dimensions!== null) return '''«FOR dim : type.constructor.dimensions»vector<«ENDFOR»«type.constructor.type.name»«FOR dim : type.constructor.dimensions»>«ENDFOR»'''
			//else return '''vector<«type.constructor.type.name»>'''
			if(type.constructor.dimensions!== null) 
				return '''«generateJavaDataType(type.constructor.type)»«FOR dim : type.constructor.dimensions»[]«ENDFOR»'''
			else 
				return '''«generateJavaDataType(type.constructor.type)»[]'''
		}
		else return '''«type.name»'''
	}

	def static generateSimpleJavaDataType(SimpleTypeDecl type) {
		if(type.name.equals("string")) return "String"
		else if(type.name.equals("real")) return "double"
		else if(type.name.equals("bool")) return "boolean"
		else return type.name
	}

	def static boolean isStringPresetInList(ArrayList<String> sList, String str) {
		//System.out.println("DEBUG LIST: "+sList)
		//System.out.println("DEBUG STR: "+str)
		for(elm : sList) {
			if(elm.equals(str))
				return true;
		}
		return false;
	}

	def static generateRecordAssignmentWithSetter(ExpressionRecordAccess eRecAccess, Expression exp, CharSequence ref) {
		var record = eRecAccess.record
		var field = eRecAccess.field
		var recExp = ''''''
		
		while(! (record instanceof ExpressionVariable)) {
			if(recExp.empty) recExp = '''«(record as ExpressionRecordAccess).field.name»'''
			//else recExp = recExp + '''.«(record as ExpressionRecordAccess).field.name»'''
			else recExp = '''«(record as ExpressionRecordAccess).field.name».''' + recExp
			record = (record as ExpressionRecordAccess).record
		}
		
		val varExp = record as ExpressionVariable

		if(recExp.empty)
			return '''
				«IF field.type.type instanceof VectorTypeDecl»
					«IF JavaGeneratorUtilities::isStateMachineVariable(varExp.variable)»
						«ref»«varExp.variable.name».«field.name» = new «JavaGeneratorUtilities::generateJavaDataType(field.type.type)» «StateMachineExpressions::generateExpression(exp, ref)»;
					«ELSE»
						«varExp.variable.name».«field.name» = new «JavaGeneratorUtilities::generateJavaDataType(field.type.type)» «StateMachineExpressions::generateExpression(exp, ref)»;
					«ENDIF»
				«ELSE»
					«IF JavaGeneratorUtilities::isStateMachineVariable(varExp.variable)»
						«ref»«varExp.variable.name».«field.name» = «StateMachineExpressions::generateExpression(exp, ref)»;
					«ELSE»
						«varExp.variable.name».«field.name» = «StateMachineExpressions::generateExpression(exp, ref)»;
					«ENDIF»
				«ENDIF»
			  '''
		else		
			return '''
				«IF JavaGeneratorUtilities::isStateMachineVariable(varExp.variable)»
					«ref»«varExp.variable.name».«recExp».«field.name» = «StateMachineExpressions::generateExpression(exp, ref)»;
				«ELSE»
					«varExp.variable.name».«recExp».«field.name» = «StateMachineExpressions::generateExpression(exp, ref)»;
				«ENDIF»
			  '''
	}


	def static isStateMachineVariable(Variable v)
	{
		return false
	}
}