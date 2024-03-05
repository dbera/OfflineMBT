package nl.esi.comma.actions.generator.poosl

import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.generator.poosl.ExpressionsPooslGenerator
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.expressions.generator.poosl.CommaScope

abstract class ActionsPooslGenerator extends ExpressionsPooslGenerator {
	
	new(String fileName, IFileSystemAccess fsa) {
		super(fileName, fsa)
	}
	
	def dispatch CharSequence generateAction(AssignmentAction a){
		switch(a.assignment.commaScope){
			case GLOBAL : 
				if(a.commaScope == CommaScope::GLOBAL)
					'''«VAR_NAME_PREFIX»«a.assignment.name» := «generateExpression(a.exp)»'''
				else
					'''stateOfDecisionClass set_«VAR_NAME_PREFIX»«a.assignment.name»(«generateExpression(a.exp)»)'''
			case TRANSITION : '''«TVAR_NAME_PREFIX»«a.assignment.name» := «generateExpression(a.exp)»'''
			case QUANTIFIER : '''Not allowed'''
		}
	}
	
	def dispatch CharSequence generateAction(IfAction ifact)
 	'''
	if «generateExpression(ifact.guard)» then
		«FOR a : ifact.thenList.actions SEPARATOR '; '»
		«generateAction(a)»
		«ENDFOR»
		«IF ifact.elseList !== null »
		else
		«FOR a : ifact.elseList.actions SEPARATOR '; '»
		«generateAction(a)»
		«ENDFOR»
		«ENDIF»
	fi'''
	
	def dispatch CharSequence generateAction(RecordFieldAssignmentAction a){
		val navigationExp = a.fieldAccess as ExpressionRecordAccess
		var record = navigationExp.record
		var field = navigationExp.field
		
		var getters = ''''''
		
		while(! (record instanceof ExpressionVariable) ){
			getters = '''get_«(record as ExpressionRecordAccess).field.name» ''' + getters 
			record = (record as ExpressionRecordAccess).record
		}
		val varExp = record as ExpressionVariable
		val variableInPOOSL = '''«generateVariableReference(varExp)» '''
		variableInPOOSL + getters + '''set_«field.name»(«generateExpression(a.exp)»)'''
	}
}