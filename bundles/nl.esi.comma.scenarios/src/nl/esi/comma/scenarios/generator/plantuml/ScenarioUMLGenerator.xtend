/*
 * (C) Copyright 2018 TNO-ESI.
 */

package nl.esi.comma.scenarios.generator.plantuml

import java.util.ArrayList
import java.util.List
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.actions.actions.EventPattern
import nl.esi.comma.actions.actions.SignalEvent
import nl.esi.comma.actions.generator.plantuml.ActionsUmlGenerator
import nl.esi.comma.scenarios.scenarios.InfoResult
import nl.esi.comma.scenarios.scenarios.NotificationEvent
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.actions.actions.CommandReply

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
		for(scenarios : scenariosList){
			if(scenarios.filterType.equals("ALL")) {
				// Select Scenarios that match all the given events
				for(s : scenarios.scenarios) {
					if(isAllNotificationsPresentInScenario(scenarios, s) &&
						isAllCommandsPresentInScenario(scenarios, s) &&
						isAllSignalsPresentInScenario(scenarios, s)) {
							//fsa.generateFile(path + "scenario" + s.name + ".plantuml", ScenarioToUML(s))
							//if(generateSpecFlow) fsa.generateFile(path + "ScenariosToSpecFlowTest\\scenario" + s.name + ".feature", ScenarioToSpecFlow(s))
								//featureText += ScenarioToSpecFlow(s)
							//fsa.generateFile(_path + s.name + ".feature", ScenarioToSpecFlow(s))
						}
				}
			}
			else {
				// Select any Scenario that has at least one of the events
				val filteredScenariosList = getFilterScenarioList(scenarios)
				// if(generateSpecFlow) fsa.generateFile(_path + ".feature", ScenarioToSpecFlow(filteredScenariosList))
				for(s : filteredScenariosList) {
					//fsa.generateFile(path + "scenario" + s.name + ".plantuml", ScenarioToUML(s))
					//if(generateSpecFlow) fsa.generateFile(_path + "ScenariosToSpecFlowTest\\scenario" + s.name + ".feature", ScenarioToSpecFlow(s)) 
						//featureText += ScenarioToSpecFlow(s) 
					//fsa.generateFile(_path + s.name + ".feature", ScenarioToSpecFlow(s))
				}
			}
		}
		//fsa.generateFile(_path + "generatedScenarios.feature", featureText)		
	}

	// This is the realization of the ALL Feature //
	def isAllNotificationsPresentInScenario(Scenarios scenarios, Scenario s) {
		
		//if(scenarios.incl_notifications.empty) 
		//	return true
		
		var boolean isAllNotificationsPresent = true
		if(scenarios.incl_notifications!==null)
		for(elm : scenarios.incl_notifications) {
			isAllNotificationsPresent = isAllNotificationsPresent && isNotificationPresentInScenario(s, elm)
		}
		
		return isAllNotificationsPresent
	}
	
	
	def isNotificationPresentInScenario(Scenario s, String name) {
		var boolean isNotificationPresent = false
		for(event : s.events) {
			if(event instanceof EventPattern) {
				if(event instanceof NotificationEvent) {
					if(event.event.name.equals(name))
						isNotificationPresent = true			
				}	
			}
		}
		return isNotificationPresent
	}

	def isAllCommandsPresentInScenario(Scenarios scenarios, Scenario s) {
		
		//if(scenarios.incl_commands.empty) 
		//	return true
		
		var boolean isAllcommandsPresent = true
		
		if(scenarios.incl_commands!==null)
		for(elm : scenarios.incl_commands) {
			isAllcommandsPresent = isAllcommandsPresent && isCommandPresentInScenario(s, elm)
		}
		
		return isAllcommandsPresent
	}
	
	
	def isCommandPresentInScenario(Scenario s, String name) {
		var boolean isCommandPresent = false
		for(event : s.events) {
			if(event instanceof EventPattern) {
				if(event instanceof CommandEvent) {
					if(event.event.name.equals(name))
						isCommandPresent = true			
				}	
			}
		}
		return isCommandPresent
	}

	def isAllSignalsPresentInScenario(Scenarios scenarios, Scenario s) {
		
		//if(scenarios.incl_signals.empty)
		//	return true
		
		var boolean isAllsignalsPresent = true
		if(scenarios.incl_signals!==null)
		for(elm : scenarios.incl_signals) {
			isAllsignalsPresent = isAllsignalsPresent && isSignalPresentInScenario(s, elm)
		}
		
		return isAllsignalsPresent
	}
	
	
	def isSignalPresentInScenario(Scenario s, String name) {
		var boolean isSignalPresent = false
		for(event : s.events) {
			if(event instanceof EventPattern) {
				if(event instanceof SignalEvent) {
					if(event.event.name.equals(name))
						isSignalPresent = true			
				}	
			}
		}
		return isSignalPresent
	}

	
	// This is the realization of the ANY Feature //
	def isPresentInCommandList(Scenarios scenarios, String name) {
		for(elm : scenarios.incl_commands) {
			if(elm.equals(name)) return true
		}
		return false
	}

	def isPresentInSignalList(Scenarios scenarios, String name) {
		for(elm : scenarios.incl_signals) {
			if(elm.equals(name)) return true
		}
		return false
	}

	def isPresentInNotificationList(Scenarios scenarios, String name) {
		for(elm : scenarios.incl_notifications) {
			if(elm.equals(name)) return true
		}
		return false
	}
	
	def getFilterScenarioList(Scenarios scenarios) {
		var ArrayList<Scenario> filteredScenarios = new ArrayList<Scenario>
		for(s : scenarios.scenarios){
			var boolean scenarioToBeAdded = false
			for(event : s.events) {
				if(event instanceof EventPattern) {
					if(event instanceof CommandEvent) {
						if(isPresentInCommandList(scenarios, event.event.name)) {
							scenarioToBeAdded = true
						}
					}
					if(event instanceof NotificationEvent) {
						if(isPresentInNotificationList(scenarios, event.event.name)) {
							scenarioToBeAdded = true
						}						
					}
					if(event instanceof SignalEvent) {
						if(isPresentInSignalList(scenarios, event.event.name)) {
							scenarioToBeAdded = true
						}						
					}
				}
			}
			if(scenarioToBeAdded) filteredScenarios.add(s)
		}
		filteredScenarios
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
	
	def dispatch eventToUML(NotificationEvent event, boolean expected) {
		'''
		«IF event.periodic»
		loop
		«ENDIF»
		«super.eventToUML(event, expected)»
		«IF event.periodic»
		end
		... until ...
		«ENDIF»
		'''
	}

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