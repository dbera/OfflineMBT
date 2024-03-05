package nl.esi.comma.actions.generator.dezyne

import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.expressions.generator.dezyne.ExpressionsToDezyne
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.actions.actions.IfAction

class ActionsToDezyne extends ExpressionsToDezyne {
	def dispatch CharSequence generateAction(
		AssignmentAction a) '''«a.assignment.name» = «generateExpression(a.exp)»; '''

	def dispatch CharSequence generateAction(RecordFieldAssignmentAction a) ''''''

	def dispatch CharSequence generateAction(IfAction a) '''if «generateExpression(a.guard)» 
	   then «FOR act : a.thenList.actions»«generateAction(act)»«ENDFOR»«IF a.elseList !== null» 
	   else «FOR act : a.elseList.actions»«generateAction(act)» «ENDFOR»«ENDIF»'''
}
