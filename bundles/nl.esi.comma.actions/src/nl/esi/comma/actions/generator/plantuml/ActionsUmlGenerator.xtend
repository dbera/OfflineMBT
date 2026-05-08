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
package nl.esi.comma.actions.generator.plantuml

import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.PCFragmentReference
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.actions.utilities.EventPatternMultiplicity

import static nl.esi.xtext.common.lang.utilities.EcoreUtil3.*

class ActionsUmlGenerator { //ExpressionsUmlGenerator {
	
	/*new(String fileName, IFileSystemAccess fsa) {
		//super(fileName, fsa)
	}*/
		
	def dispatch CharSequence generateAction(AssignmentAction a)
	'''«a.assignment.name» := «serialize(a.exp)» '''
	
	def dispatch CharSequence generateAction(RecordFieldAssignmentAction a)
	'''«serialize(a.fieldAccess)» := «serialize(a.exp)» '''
	
	def dispatch CharSequence generateAction(IfAction a)
	'''if «serialize(a.guard)» then «FOR act : a.thenList.actions»«generateAction(act)»«ENDFOR»«IF a.elseList !== null» else «FOR act : a.elseList.actions»«generateAction(act)» «ENDFOR»«ENDIF»fi '''
	
	def dispatch CharSequence generateAction(PCFragmentReference a)
	'''fragment «a.fragment.name»'''
	
	def printMultiplicity(EventPatternMultiplicity m){
		if(m.lower == m.upper) return (if (m.lower == 1)'''''' else'''[«m.lower»]''')
		if(m.upper == -1){
			if(m.lower == 0) return '''[*]'''
			if(m.lower == 1) return '''[+]'''
			else return '''[«m.lower»-*]'''
		}else{
			if(m.lower == 0 && m.upper == 1) return '''[?]'''
			else return '''[«m.lower»-«m.upper»]'''
		}
	}
}