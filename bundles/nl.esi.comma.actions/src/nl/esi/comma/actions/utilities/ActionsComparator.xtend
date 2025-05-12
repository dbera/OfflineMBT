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

import nl.esi.comma.actions.actions.ActionList
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.InterfaceEventInstance
import nl.esi.comma.actions.actions.Multiplicity
import nl.esi.comma.actions.actions.PCFragmentReference
import nl.esi.comma.actions.actions.ParallelComposition
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.utilities.ExpressionsComparator

import static extension nl.esi.comma.actions.utilities.ActionsUtilities.*

class ActionsComparator extends ExpressionsComparator{
	
	def dispatch boolean compare(AssignmentAction act1, AssignmentAction act2){
		act1.assignment.sameAs(act2.assignment) && act1.exp.sameAs(act2.exp)
	}
	
	def dispatch boolean compare(IfAction act1, IfAction act2){
		act1.guard.sameAs(act2.guard) &&
		act1.thenList.sameAs(act2.thenList) &&
		act1.elseList.sameAs(act2.elseList)
	}
	
	def dispatch boolean compare(RecordFieldAssignmentAction act1, RecordFieldAssignmentAction act2){
		act1.fieldAccess.sameAs(act2.fieldAccess) && act1.exp.sameAs(act2.exp)
	}
	
	def dispatch boolean compare(CommandReply act1, CommandReply act2){
		act1.command.sameAs(act2.command) &&
		compareLists(act1.parameters, act2.parameters)
	}
	
	def dispatch boolean compare(InterfaceEventInstance ev1, InterfaceEventInstance ev2){
		ev1.event === ev2.event && compareLists(ev1.parameters, ev2.parameters)
	}
	
	def dispatch boolean compare(EventCall act1, EventCall act2){
		if(act1.event !== act2.event) return false
		compareLists(act1.parameters, act2.parameters) &&
		act1.occurence == act1.occurence && act1.multiplicity.sameAs(act2.multiplicity)
	}
	
	def dispatch boolean compare(Multiplicity m1, Multiplicity m2){
		m1.lower == m2.lower && m1.upper == m2.upper && 
		m1.upperInf == m2.upperInf
	}
	
	def dispatch boolean compare(ParallelComposition act1, ParallelComposition act2){
		val act1Components = act1.flatten
		val act2Components = act2.flatten
		
		if(act1Components.size != act2Components.size) {
			return false
		}
		return act1Components.forall(c1 | act2Components.exists(c2 | c1.sameAs(c2))) &&
			   act2Components.forall(c2 | act1Components.exists(c1 | c2.sameAs(c1)))
	}
	
	def dispatch boolean compare(PCFragmentReference ref1, PCFragmentReference ref2){
		ref1.fragment === ref2.fragment
	}
	
	def dispatch boolean compare(ActionList list1, ActionList list2){
		compareLists(list1.actions, list2.actions)
	}
}