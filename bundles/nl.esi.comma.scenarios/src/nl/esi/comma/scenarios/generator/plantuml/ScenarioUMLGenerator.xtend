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
package nl.esi.comma.scenarios.generator.plantuml

import java.util.List
import nl.esi.comma.actions.generator.plantuml.ActionsUmlGenerator
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess

class ScenarioUMLGenerator extends ActionsUmlGenerator {
	
	//var generateSpecFlow = true
	//val String _path = "..\\test-gen\\ScenariosToSpecFlowTest\\feature"

	//var coMap = new HashMap<String, ArrayList<String>>
	//var siMap = new HashMap<String, ArrayList<String>>
	//var niMap = new HashMap<String, ArrayList<String>>

	new(String fileName, IFileSystemAccess fsa) {
		//super(fileName, fsa)
	}
	
	//	ScenariosToSpecFlowTest\\feature
	//	SequenceDiagrams\\scenario
	
	def doGenerateUML(List<Scenarios> scenariosList, String path, IFileSystemAccess fsa) {
//		for(scenarios : scenariosList){
//		}
		//fsa.generateFile(_path + "generatedScenarios.feature", featureText)		
	}

	def ScenarioToUML(Scenario s)
	{
		/*var isNoteOpen = false;
		'''
		@startuml
		title Scenario «s.name»
		«FOR event : s.events»
			«IF event instanceof EventPattern && isNoteOpen»
				end note
				«{isNoteOpen = false ""}»
			«ENDIF»
			«IF event instanceof EventPattern»
				«toUML(event, true)»
			«ENDIF»
			«IF event instanceof InfoResult»
			«IF !isNoteOpen»
			note left
			«ENDIF»
			«{isNoteOpen = true ""}»
				«FOR e : event.elm»
					«e»
				«ENDFOR»
			«ENDIF»
		«ENDFOR»
		«IF isNoteOpen»
			end note
			«{isNoteOpen = false ""}»
		«ENDIF»
		@enduml
		'''
		*/
	}

/*			«IF event instanceof InfoArg»
			note right
				«FOR e : event.elm»
					«e»
				«ENDFOR»
			end note
			«ENDIF» */

	/*def dispatch toUML(CommandEvent e, boolean expected)'''
						Client ->«IF ! expected»x«ENDIF» Server: command «e.event.name»«IF e.parameters.size() >0 »(«FOR p : e.parameters SEPARATOR ', '»«generateExpression(p)»«ENDFOR»)«ENDIF»
					'''
	def dispatch toUML(SignalEvent e, boolean expected)'''
						Client ->>«IF ! expected»x«ENDIF» Server: signal «e.event.name»«IF e.parameters.size() >0 »(«FOR p : e.parameters SEPARATOR ', '»«generateExpression(p)»«ENDFOR»)«ENDIF»
					'''
	
	def dispatch toUML(CommandReply e, boolean expected)'''
						Server -->«IF ! expected»x«ENDIF» Client: reply «IF e.parameters.size() > 0»(«generateExpression(e.parameters.get(0))»)«ENDIF»«IF e.command !== null» to command «e.command.event.name»«IF e.command.parameters.size() >0 »(«FOR p : e.command.parameters SEPARATOR ', '»«generateExpression(p)»«ENDFOR»)«ENDIF»«ENDIF»
					'''
	
	def dispatch toUML(NotificationEvent e, boolean expected)'''
						Client «IF ! expected»x«ENDIF»//- Server: notification «e.event.name»«IF e.parameters.size() >0 »(«FOR p : e.parameters SEPARATOR ', '»«generateExpression(p)»«ENDFOR»)«ENDIF»
					'''
	*/
	
/* 
			«IF e instanceof InfoResult»
				«FOR str : e.elm»
					# «str»
				«ENDFOR»
			«ELSEIF e instanceof InfoArg»
			
				«FOR str : e.elm»
					# «str»
				«ENDFOR»		
			«ELSEIF e instanceof InfoResult»
				«FOR str : e.elm»
					«str»
				«ENDFOR»

*/	
}