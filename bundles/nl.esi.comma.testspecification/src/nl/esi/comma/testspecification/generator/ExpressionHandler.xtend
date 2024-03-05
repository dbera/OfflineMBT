package nl.esi.comma.testspecification.generator

import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionVariable
import java.util.regex.Pattern
import java.util.HashMap
import java.util.List

class ExpressionHandler 
{
	def dispatch KeyValue generateInitAssignmentAction(AssignmentAction action, 
		HashMap<String, List<String>> mapLocalDataVarToDataInstance, 
		HashMap<String, List<String>> mapLocalStepInstance
	) 
	{
		var mapLHStoRHS = new KeyValue

		mapLHStoRHS.key =  action.assignment.name
		mapLHStoRHS.value = ExpressionsParser::generateExpression(action.exp, '''''').toString

		// replace references to global variables with FAST syntax
		for(elm : mapLocalDataVarToDataInstance.keySet) {
			if(mapLHStoRHS.value.contains(elm)) {
				mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm, "global.params['" + elm + "']")
			}	
		}
		return mapLHStoRHS
	}
	
	def dispatch KeyValue generateInitAssignmentAction(RecordFieldAssignmentAction action, 
		HashMap<String, List<String>> mapLocalDataVarToDataInstance, 
		HashMap<String, List<String>> mapLocalStepInstance
	) {
		return generateInitRecordAssignment(action.fieldAccess as ExpressionRecordAccess, action.exp, '''''', 
			mapLocalDataVarToDataInstance, mapLocalStepInstance
		)
	}

	def generateInitRecordAssignment(ExpressionRecordAccess eRecAccess, 
		Expression exp, CharSequence ref, 
		HashMap<String, List<String>> mapLocalDataVarToDataInstance, 
		HashMap<String, List<String>> mapLocalStepInstance
	) {
		var mapLHStoRHS = new KeyValue
		
        var record = eRecAccess.record
        var field = eRecAccess.field
        var recExp = ''''''
             
        while(! (record instanceof ExpressionVariable)) {
        	if(recExp.empty) recExp = '''«(record as ExpressionRecordAccess).field.name»'''
            else recExp = '''«(record as ExpressionRecordAccess).field.name».''' + recExp
            record = (record as ExpressionRecordAccess).record
        }
		// System.out.println(" Record Exp: " + recExp)
		val varExp = record as ExpressionVariable
		// System.out.println(" Var Exp: " + varExp.variable.name)
		mapLHStoRHS.key = field.name
		mapLHStoRHS.value = ExpressionsParser::generateExpression(exp, ref).toString
		mapLHStoRHS.refVal.add(mapLHStoRHS.value)
		
		// check references to Step outputs and replace with FAST syntax
		for(elm : mapLocalStepInstance.keySet) {
			if(mapLHStoRHS.value.contains(elm+".output")) {
				mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm+".output", "steps.out['" + elm + "']")
				
				mapLHStoRHS.refKey.add(elm)  // reference to step
				//mapLHStoRHS.refVal.add(mapLHStoRHS.value) // commented out to prevent duplicates

				// Custom String Updates for FAST Syntax Peculiarities! TODO investigate solution?
				// map-var['key'] + "[0]" -> map-var['key'][0] 
				mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(Pattern.quote("] + \"["), "][") // ("\\] + \"\\[","\\]\\[")
				mapLHStoRHS.value = mapLHStoRHS.value.replaceAll("\\]\"","]")
			}
		}
		
		// replace references to global variables with FAST syntax
		for(elm : mapLocalDataVarToDataInstance.keySet) {
			if(mapLHStoRHS.value.contains(elm)) {
				mapLHStoRHS.value = mapLHStoRHS.value.replaceAll(elm, "global.params['" + elm + "']")
			}
		}
		
		// name of variable instance: varExp.variable.name
		return mapLHStoRHS
	}
	// End Expression Handler //

	def dispatch KeyValue getLHS(AssignmentAction action) {
		var kv = new KeyValue
		kv.key = action.assignment.name
		kv.value = new String
		return kv
	}
	
	def dispatch KeyValue getLHS(RecordFieldAssignmentAction action) {
		return getLHSRecAssignment(action.fieldAccess as ExpressionRecordAccess, action.exp)
	}
	
	def KeyValue getLHSRecAssignment(ExpressionRecordAccess eRecAccess, Expression exp) {
		var record = eRecAccess.record
        var field = eRecAccess.field
        var recExp = ''''''
             
        while(! (record instanceof ExpressionVariable)) {
        	if(recExp.empty) recExp = '''«(record as ExpressionRecordAccess).field.name»'''
            else recExp = '''«(record as ExpressionRecordAccess).field.name».''' + recExp
            record = (record as ExpressionRecordAccess).record
        }
		val varExp = record as ExpressionVariable
		var kv = new KeyValue
		kv.key = varExp.variable.name
		kv.value = recExp
		return kv
	}
}