package nl.esi.comma.behavior.validation

import java.util.ArrayList
import java.util.HashSet
import java.util.LinkedHashSet
import java.util.Set
import nl.esi.comma.behavior.behavior.BehaviorPackage
import nl.esi.comma.behavior.behavior.InAllStatesBlock
import nl.esi.comma.behavior.behavior.StateMachine
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.utilities.StateMachineUtilities
import nl.esi.comma.behavior.utilities.TransitionComparator
import nl.esi.comma.types.types.TypesPackage
import org.eclipse.xtext.validation.Check

class StateMachineValidator extends TimeConstraintsValidator {
	
	public static final String STATEMACHINE_MISSING_INITIAL_STATE = "statemachine_missing_initial_state"
	public static final String STATEMACHINE_DUPLICATE_INITIAL_STATE = "statemachine_duplicate_initial_state"
	
	/*
	 * Constraints:
	 * - State machine has exactly one initial state
	 */	
	@Check
	def checkInitialState(StateMachine m){
		val sizeInitialStates = m.states.filter(s | s.initial).size()
		if(sizeInitialStates == 0){
			error('The state machine does not have an initial state.', 
				TypesPackage.Literals.NAMED_ELEMENT__NAME, STATEMACHINE_MISSING_INITIAL_STATE)
		} else
			if(sizeInitialStates > 1){
				error('The state machine has more than one initial state.', 
					TypesPackage.Literals.NAMED_ELEMENT__NAME, STATEMACHINE_DUPLICATE_INITIAL_STATE)
			}
	}
	
	/*
	 * Constraints:
	 * - all states are reachable from the initial state
	 */
	@Check
	def checkUnreachableStates(StateMachine m){
		val initialStates = m.states.filter(s | s.initial)
		if(initialStates.size != 1) return
		val initialState = initialStates.get(0)
		val reachable = new LinkedHashSet<nl.esi.comma.behavior.behavior.State>(5)
		reachable.add(initialState)
		closure(reachable, initialState)
		for(s : m.states){
			if(!reachable.contains(s))
				error("Unreachable state", s, TypesPackage.Literals.NAMED_ELEMENT__NAME)
		}
	}
	
	/*
	 * Computes the transitive closure of all states reachable from the state start
	 */
	def void closure(Set<nl.esi.comma.behavior.behavior.State> states, nl.esi.comma.behavior.behavior.State start){
		val transitions = StateMachineUtilities.transitionsForState(start)
		transitions.map[clauses].flatten.map[target].filter[it !== null].forEach[
			if(states.add(it))
				closure(states, it)]
	}
	
	/*
	 * Constraints:
	 * - warnings on structurally identical transitions in the same state or after 
	 *   including the ones from in all states blocks
	 * - warning on duplicate clauses that belong to different transitions in the same state
	 *   when the transitions have the same trigger
	 * 
	 * Rationale: sometimes after copy/paste, a transition can be copied twice in the same state.
	 * This leads to unnecessary non-determinism
	 */
	
	@Check
	def checkOverlappingTransitions(StateMachine sm){
		sm.states.forEach[checkOverlappingTransitionsInState]
	}
	
	def checkOverlappingTransitionsInState(nl.esi.comma.behavior.behavior.State s){
		val comparator = new TransitionComparator
		val allTransitions = StateMachineUtilities::transitionsForState(s)
		val visitedTransitions = new ArrayList<Transition>
		val duplicatesInState = new HashSet<Transition> //contains duplicates within the current state s
		val duplicatesOfInAllStates = new HashSet<Transition> //contains duplicates of transitions in all states block
		var duplicatesFromDifferentAllStates = false 
		
		for(t1 : allTransitions){
			for(t2 : visitedTransitions){
				val clIntersection = comparator.clauseIntersection(t1, t2)
				if(!clIntersection.empty){
					val intersectionSize = clIntersection.size
					val identicalTransitions = intersectionSize == t1.clauses.size && intersectionSize == t2.clauses.size
					if(t1.eContainer === t2.eContainer){
						if(t1.eContainer === s) { //transitions are in the same state
							if(identicalTransitions) duplicatesInState.add(t1)
							else(
								for(cl : clIntersection){
									warning("Clause duplicates another clause in a different transition in the same state", 
										t1, BehaviorPackage.Literals.TRANSITION__CLAUSES, t1.clauses.indexOf(cl))
								}
							)
						}
					}
					else{
						if(t1.eContainer === s) {
							if(identicalTransitions) duplicatesOfInAllStates.add(t1)
							else(
								for(cl : clIntersection){
									warning("Clause duplicates another clause in a transition from in_all_states block", 
										t1, BehaviorPackage.Literals.TRANSITION__CLAUSES, t1.clauses.indexOf(cl))
								}
							)
						}
						else duplicatesFromDifferentAllStates = true
					}
				}
			}
			visitedTransitions.add(t1)
		}
		if(duplicatesFromDifferentAllStates)
			warning("Duplicate clauses in transitions from two different in_all_states blocks", s, TypesPackage.Literals.NAMED_ELEMENT__NAME)
			
		for(t : duplicatesInState){
			warning("Duplicate of a local transition", s, BehaviorPackage.Literals.STATE__TRANSITIONS, s.transitions.indexOf(t))
		}
		
		for(t : duplicatesOfInAllStates){
			warning("Duplicate of a transition from in_all_states block", s, BehaviorPackage.Literals.STATE__TRANSITIONS, s.transitions.indexOf(t))
		}
	}
	
	@Check
	def checkDuplicateTransitionsInAllStatesBlock(InAllStatesBlock block){
		val comparator = new TransitionComparator
		val nrTransitions = block.transitions.size
		for(i : 0..< nrTransitions){
			for(j : i+1 ..< nrTransitions){
				val clIntersection = comparator.clauseIntersection(block.transitions.get(i), block.transitions.get(j))
				if(!clIntersection.empty){
					val intersectionSize = clIntersection.size
					val identicalTransitions = intersectionSize == block.transitions.get(i).clauses.size && intersectionSize == block.transitions.get(j).clauses.size
					if(identicalTransitions){
						warning("Duplicate transition", block, BehaviorPackage.Literals.IN_ALL_STATES_BLOCK__TRANSITIONS, i)
					}
					else{
						for(cl : clIntersection){
							warning("Clause duplicates another clause in a different transition in the same block", 
								block.transitions.get(i), BehaviorPackage.Literals.TRANSITION__CLAUSES, block.transitions.get(i).clauses.indexOf(cl))
						}
					}
				}
			}
		}
	}
}