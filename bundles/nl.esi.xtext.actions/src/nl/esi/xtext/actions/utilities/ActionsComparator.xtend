/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.actions.utilities

import nl.esi.xtext.actions.actions.ActionList
import nl.esi.xtext.actions.actions.AssignmentAction
import nl.esi.xtext.actions.actions.IfAction
import nl.esi.xtext.actions.actions.Multiplicity
import nl.esi.xtext.actions.actions.PCFragmentReference
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.expressions.utilities.ExpressionsComparator

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
	
	def dispatch boolean compare(Multiplicity m1, Multiplicity m2){
		m1.lower == m2.lower && m1.upper == m2.upper && 
		m1.upperInf == m2.upperInf
	}
	
	def dispatch boolean compare(PCFragmentReference ref1, PCFragmentReference ref2){
		ref1.fragment === ref2.fragment
	}
	
	def dispatch boolean compare(ActionList list1, ActionList list2){
		compareLists(list1.actions, list2.actions)
	}
}