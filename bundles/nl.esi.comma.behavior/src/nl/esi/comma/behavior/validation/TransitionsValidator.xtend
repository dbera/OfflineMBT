package nl.esi.comma.behavior.validation

import nl.esi.comma.behavior.behavior.BehaviorPackage
import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.validation.Check
import nl.esi.comma.behavior.utilities.TransitionComparator
import static extension nl.esi.comma.types.utilities.TypeUtilities.*

class TransitionsValidator extends AbstractBehaviorValidator {
	
	public static final String CLAUSE_MISSING_NEXT_STATE = "statemachine_missing_next_state"	
	
	def register(AbstractBehaviorValidator registrar) {
		// not needed for classes used as ComposedCheck
	}
	
	/*
	 * Constraints:
	 * - clauses in transitions defined in states have always a next state
	 */
	@Check
	def checkMissingNextState(Clause c) {
		if(c.target !== null || !(c.eContainer.eContainer instanceof nl.esi.comma.behavior.behavior.State)) return;
		
		//missing next state and defined in a state
		//because of many possible forms of the clause (actions no actions, etc.)
		//the decision where to show the error is more intricate
		val sourceText = NodeModelUtils.getNode(c).text
		if(sourceText.contains("next state")){
			error("Missing next state", BehaviorPackage.Literals.CLAUSE__TARGET, CLAUSE_MISSING_NEXT_STATE,	null)
		}
		else{
			if(c.actions !== null) {
				error("Missing next state", c.eContainer, BehaviorPackage.Literals.TRANSITION__CLAUSES, 
					(c.eContainer as Transition).clauses.indexOf(c), CLAUSE_MISSING_NEXT_STATE, null)
			}else{
				val state = c.eContainer.eContainer as nl.esi.comma.behavior.behavior.State
				error("Transition clause missing next state", state, BehaviorPackage.Literals.STATE__TRANSITIONS, 
					state.transitions.indexOf(c.eContainer), CLAUSE_MISSING_NEXT_STATE, null)
			}
		}
	}
	
	/*
	 * Constraints:
	 * - the trigger in a transition must match its definition in the signature
	 *   (type and number of parameters)
	 */
	@Check
	def checkTriggerSignature(TriggeredTransition t) {
		if(t.trigger === null) return;
		if (t.parameters.size() != t.trigger.parameters.size()) {
			error('Wrong number of parameters in the trigger.', BehaviorPackage.Literals.TRIGGERED_TRANSITION__TRIGGER)
			return
		}
		// number of params Ok, check the types
		for (p : t.parameters) {
			if (!identical(p.type.typeObject, t.trigger.parameters.get(t.parameters.indexOf(p)).type.typeObject)) {
				error('The type of parameter does not match the type in the trigger signature.',
					BehaviorPackage.Literals.TRIGGERED_TRANSITION__PARAMETERS, t.parameters.indexOf(p))
			}
		}
	}
	
	/*
	 * Constraints:
	 * - parameter names in a trigger are unique
	 * - transition guard is of type Boolean
	 */
	@Check
	def checkForDuplicatedParameterName(TriggeredTransition t){
		checkForNameDuplications(t.parameters, "parameter", null)
	}
	
	@Check
	def typeCheckTransitionGuard(Transition t){
		if(t.guard !== null){
			if(!identical(t.guard.typeOf, boolType)){
				error("Guard expression has to be of type boolean.",BehaviorPackage.Literals.TRANSITION__GUARD)
			}
		}		
	}
	
	/*
	 * Constraints:
	 * - warning on structurally identical clauses in a transition
	 */
	 @Check
	 def checkDuplicateClauses(Transition t){
	 	val comparator = new TransitionComparator
	 	for(i : 0..< t.clauses.size){
	 		for(j : (i + 1)..< t.clauses.size){
	 			if(comparator.sameAs(t.clauses.get(i), t.clauses.get(j))){
	 				warning("Duplicate clause", BehaviorPackage.Literals.TRANSITION__CLAUSES, j)
	 			}
	 		} 
	 	}
	 }
}
