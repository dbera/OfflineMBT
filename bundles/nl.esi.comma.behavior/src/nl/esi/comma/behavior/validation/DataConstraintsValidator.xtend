package nl.esi.comma.behavior.validation

import java.util.HashSet
import nl.esi.comma.actions.actions.ActionsPackage
import nl.esi.comma.behavior.behavior.BehaviorPackage
import nl.esi.comma.behavior.behavior.DataConstraint
import nl.esi.comma.behavior.behavior.DataConstraintEvent
import nl.esi.comma.behavior.behavior.DataConstraintsBlock
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Variable
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.validation.Check

class DataConstraintsValidator extends EventsValidator {
		
	/*
	 * Constraints:
	 * - data constraints have unique names
	 * - variables in data constraint block have unique names
	 */
	@Check
	def checkDuplicatesInDataConstraints(DataConstraintsBlock dcBlock){
		checkForNameDuplications(dcBlock.dataConstraints, "data constraint", null)
		checkForNameDuplications(dcBlock.vars, "variable", null)
	}
	
	/*
	 * Constraints:
	 * - a variable can be used at most once in a value binding position
	 * - all variables used in a condition must have been bound to a value
	 */
	@Check
	def checkDataConstraint(DataConstraint dc){
		val boundVars = new HashSet<Variable>
		for(step : dc.steps){
			EcoreUtil2::getAllContentsOfType(step, ExpressionVariable).forEach[
				if(it.variable !== null){
					if(!boundVars.add(it.variable)){
						error('The variable is already bound to a value.', it, ExpressionPackage.Literals.EXPRESSION_VARIABLE__VARIABLE)
					}
				}
			]
		}
		EcoreUtil2.getAllContentsOfType(dc.condition, ExpressionVariable)
		.filter[it.variable !== null && (it.variable.eContainer instanceof DataConstraintsBlock)]
		.forEach[
			if(!boundVars.contains(it.variable)){
				error('The variable is not previously bound to a value.', it, ExpressionPackage.Literals.EXPRESSION_VARIABLE__VARIABLE)
			}]
	}
	
	/*
	 * Constraints:
	 * - warning on unused variables
	 */
	@Check
	def checkUnusedVariables(DataConstraintsBlock dcb){
		val usedVars = EcoreUtil2.getAllContentsOfType(dcb, ExpressionVariable)
					   .map[variable].filter[it !== null && it.eContainer instanceof DataConstraintsBlock].toSet
		for(v : dcb.vars){
			if(!usedVars.contains(v)){
				warning('Variable not used.', ActionsPackage.Literals.VARIABLE_DECL_BLOCK__VARS, dcb.vars.indexOf(v))
			}
		}
	}
	
	@Check 
	def checkConditionType(DataConstraint dc){
		if(dc.condition !== null){
			if( !identical(dc.condition.typeOf, boolType)){
				error('Condition has to be of boolean type.', BehaviorPackage.Literals.DATA_CONSTRAINT__CONDITION)
			}
		}
	}
	
	/*
	 * Constraints:
	 * - variables are not allowed in negated events
	 */
	@Check
	def checkVarsInNegation(DataConstraintEvent e){
		if(e.negated.equals("no")){
			for(v : EcoreUtil2::getAllContentsOfType(e, ExpressionVariable)){
				error("Variables cannot be used in negated events.", v, ExpressionPackage.Literals.EXPRESSION_VARIABLE__VARIABLE)
			}
		}
	}
}