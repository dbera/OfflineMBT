package nl.esi.comma.behavior.utilities

import nl.esi.comma.actions.utilities.ActionsComparator
import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.NonTriggeredTransition
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import java.util.Set
import java.util.HashSet
import java.util.List

class TransitionComparator extends ActionsComparator{
	
	def boolean sameTransition(Transition t1, Transition t2){
		if(t1.guard !== null && t2.guard !== null){
			if(! t1.guard.sameAs(t2.guard)) return false
		}
		else{
			if(t1.guard !== null || t2.guard !== null) return false
		}
		compareListsAsSets(t1.clauses, t2.clauses)
	}
	
	def dispatch boolean compare(Clause c1, Clause c2){
		if(! c1.actions.sameAs(c2.actions)) return false
		if(c1.target !== null && c2.target !== null) return c1.target === c2.target
		true
	}
	
	def dispatch boolean compare(NonTriggeredTransition t1, NonTriggeredTransition t2){
		sameTransition(t1, t2)
	}
	
	def dispatch boolean compare(TriggeredTransition t1, TriggeredTransition t2){
		if(t1.trigger !== t2.trigger) return false
		if(! compareLists(t1.parameters, t2.parameters)) return false
		sameTransition(t1, t2)
	}
	
	//returns all the clauses in t1 that are equivalent to a clause in t2
	def Set<Clause> clauseIntersection(Transition t1, Transition t2){
		val empty = new HashSet<Clause>
		if(t1 === null || t2 === null) return empty
		if(t1 instanceof TriggeredTransition)
			if(t2 instanceof TriggeredTransition){
				if(t1.trigger !== t2.trigger) return empty
				if(! compareLists(t1.parameters, t2.parameters)) return empty
				if(!t1.guard.sameAs(t2.guard)) return empty
				return clauseIntersection(t1.clauses, t2.clauses)
			}
		if(t1 instanceof NonTriggeredTransition)
			if(t2 instanceof NonTriggeredTransition){
				if(!t1.guard.sameAs(t2.guard)) return empty
				return clauseIntersection(t1.clauses, t2.clauses)
			}
				
		empty
	}
	
	def Set<Clause> clauseIntersection(List<Clause> l1, List<Clause> l2){
		val result = new HashSet<Clause>
		for(c : l1){
			if(!result.exists(c1 | c.sameAs(c1)) && l2.exists(c1 | c.sameAs(c1))){
				result.add(c)
			}
		}
		result
	}
}