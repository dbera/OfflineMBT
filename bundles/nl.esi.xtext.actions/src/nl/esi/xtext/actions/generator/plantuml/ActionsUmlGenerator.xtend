/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.actions.generator.plantuml

import nl.esi.xtext.actions.actions.AssignmentAction
import nl.esi.xtext.actions.actions.IfAction
import nl.esi.xtext.actions.actions.PCFragmentReference
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.actions.utilities.EventPatternMultiplicity

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