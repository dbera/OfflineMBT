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
import nl.esi.comma.actions.actions.PCFragment
import nl.esi.comma.actions.actions.PCFragmentDefinition
import nl.esi.comma.actions.actions.PCFragmentReference
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable

class ActionsUtilities {
	
	def static List<Action> flatten(PCFragment fragment){
		fragment.flattenHelper(new HashSet<PCFragment>)
	}
	
	def static private List<Action> flattenHelper(PCFragment fragment, Set<PCFragment> knownFragments){
		val result = new ArrayList<Action>
		for(c : fragment.components){
			switch(c){
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
	
	def static getAssignment(RecordFieldAssignmentAction action) {
	    var record = action.fieldAccess
	    while (record instanceof ExpressionRecordAccess) {
	        record = record.record
	    }
	    if (record instanceof ExpressionVariable) {
	        return record.variable
	    }
	}

    def static getFields(RecordFieldAssignmentAction action) {
        val fields = newLinkedList()
        var record = action.fieldAccess
        while (record instanceof ExpressionRecordAccess) {
            fields.addFirst(record.field)
            record = record.record
        }
        return fields
    }
}