package nl.esi.comma.behavior.validation

import java.util.HashSet
import nl.esi.comma.behavior.behavior.BehaviorPackage
import nl.esi.comma.behavior.behavior.EventInState
import org.eclipse.xtext.validation.Check
import nl.esi.comma.actions.actions.EventPattern
import nl.esi.comma.actions.actions.ParameterizedEvent
import org.eclipse.xtext.EcoreUtil2
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.actions.actions.ActionsPackage

class EventsValidator extends StateMachineValidator {
	
	@Check
	def checkEventForDuplicatedStates(EventInState ev){
		var states = new HashSet<String>
		for(s : ev.state){
			if(!states.add(s.name)){
				warning("Duplicated state", BehaviorPackage.Literals.EVENT_IN_STATE__STATE, ev.state.indexOf(s))
			}
		}	
	}
	
	/*
	 * Constraints:
	 * - when used in constraints, the actual parameters in event patterns are either variables or if not,
	 *   the expression cannot contain variables
	 * Rationale: variable binding cannot happen if this constraint does not hold
	 */
	@Check
	def checkParametersForVariables(EventPattern event){
		if(! (event.eContainer instanceof EventInState)) {return}
		if(event instanceof ParameterizedEvent)
			for(parameter : event.parameters.filter[it | ! (it instanceof ExpressionVariable)]){
				if (! EcoreUtil2.getAllContentsOfType(parameter, ExpressionVariable).empty) {
						error('Parameter cannot be an expression containing variables.',
							ActionsPackage.Literals.PARAMETERIZED_EVENT__PARAMETERS, event.parameters.indexOf(parameter))
				}
			}
	}
}