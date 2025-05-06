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
package nl.esi.comma.actions.utilities

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Set
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.PCElement
import nl.esi.comma.actions.actions.PCFragment
import nl.esi.comma.actions.actions.PCFragmentDefinition
import nl.esi.comma.actions.actions.PCFragmentReference
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.utilities.ExpressionsComparator

class ActionsUtilities {
	
	def static EventPatternMultiplicity getNormalizedMultiplicity(EventCall ec){
		var result = new EventPatternMultiplicity
		if(ec.occurence !== null){
			switch(ec.occurence){
		 		case "?" : {result.lower = 0}
		 		case "*" : {result.lower = 0 result.upper = -1}
		 		case "+" : {result.lower = 1 result.upper = -1}
		 	}
		}else if(ec.multiplicity !== null){
			val m = ec.multiplicity
			if(m.upperInf !== null){
				result.upper = -1
				result.lower = m.lower
			}else{
				result.lower = m.lower
				result.upper = m.upper
			}
		}
		result
	}
	
	def static List<Action> flatten(PCFragment fragment){
		fragment.flattenHelper(new HashSet<PCFragment>)
	}
	
	def static private List<Action> flattenHelper(PCFragment fragment, Set<PCFragment> knownFragments){
		val result = new ArrayList<Action>
		for(c : fragment.components){
			switch(c){
				EventCall |
				CommandReply : result.add(c)
				PCFragmentReference : if (knownFragments.add(c.fragment)) result.addAll(c.fragment.flattenHelper(knownFragments))
			}
		}
		result
	}
	
	def static HashSet<PCFragmentDefinition> allReferencedFragments(PCFragmentDefinition fd, HashSet<PCFragmentDefinition> knownFragments){
		for(c : fd.components.filter(PCFragmentReference)){
			if(knownFragments.add(c.fragment)){
				knownFragments.addAll(allReferencedFragments(c.fragment, knownFragments))
			}
		}
		knownFragments
	}
	
	def static boolean overlaps(EventCall call, PCElement other){
		if(call === null || other === null) return false
		if(other instanceof EventCall){
			if(call.event !== other.event) return false
			if(call.parameters.size !== other.parameters.size) return false
			for(i : 0..< call.parameters.size){
				val p1 = call.parameters.get(i)
				val p2 = other.parameters.get(i)
				val comp = new ExpressionsComparator
				if(!(p1 instanceof ExpressionAny) &&
				   !(p2 instanceof ExpressionAny) &&
				   ! comp.compare(p1, p2)) return false
			}
			return true
		}
		return false
	}
}