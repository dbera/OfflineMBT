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
package nl.esi.comma.scenarios.generator.traces

import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.types.types.Import
import java.util.List
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.actions.actions.SignalEvent
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.types.utilities.TypeUtilities
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.types.types.Type
import java.util.ArrayList
import nl.esi.comma.types.types.TypeDecl
import org.eclipse.emf.ecore.EObject
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.actions.actions.NotificationEvent
import nl.esi.comma.actions.actions.EventPattern
import nl.esi.comma.actions.actions.AnyEvent
import nl.esi.comma.scenarios.scenarios.SpecFlowScenario
import java.util.HashMap
import nl.esi.comma.scenarios.scenarios.ActionType

class ScenarioTracesGenerator extends ExpressionsCommaGenerator {
	final static String DEFAULT_SERVER_IP = "192.68.32.1"
	final static String DEFAULT_CLIENT_IP = "192.68.32.2"
	final static String DEFAULT_SERVER_NAME = "server1"
	final static String DEFAULT_CLIENT_NAME = "client1"

	// instead of traces let us generate XES files
	def generateXESfile(Scenarios scenarios, String path, IFileSystemAccess fsa) {
		if(!scenarios.scenarios.isEmpty)
		  fsa.generateFile(path + "scenarios.xes", ScenarioToXESModel(scenarios))
		if(!scenarios.specFlowScenarios.isEmpty) {
		  fsa.generateFile(path + "scenarios.xes", ScenarioToXESModel(scenarios))
        }
		/*for(s : scenarios.scenarios){
			fsa.generateFile(path + s.name + ".xes", ScenarioToXESModel(s))
		}*/		
	}
	
	def generateLogsForDeclareChecker(Scenarios scenarios, String path, IFileSystemAccess fsa) {
        if(!scenarios.specFlowScenarios.isEmpty) {
            fsa.generateFile(path + "scenarios.logs", ScenarioToLogsModel(scenarios))
            fsa.generateFile(path + "scenarios.constraint", ScenarioToDeclModel(scenarios))
        }
	}

    def ScenarioToDeclModel(Scenarios scenarios) {
        var actionList = new HashMap<String,String> // name and type
        for(scn : scenarios.specFlowScenarios) {
            var lastType = ActionType.GIVEN
            for(evt : scn.events) {
                if(evt.type.equals(ActionType.GIVEN)) {
                    lastType = evt.type
                    if(!actionList.keySet.contains(evt.name))
                        actionList.put(evt.name,"Pre-condition")
                }
                else if(evt.type.equals(ActionType.WHEN)) {
                    lastType = evt.type
                    if(!actionList.keySet.contains(evt.name))
                        actionList.put(evt.name,"Trigger")
                }
                else if(evt.type.equals(ActionType.THEN)) {
                    lastType = evt.type
                    if(!actionList.keySet.contains(evt.name))
                        actionList.put(evt.name,"Observable")
                }
                else if(evt.type.equals(ActionType.AND)) {
                    if(!actionList.keySet.contains(evt.name)) {
                        if(lastType.equals(ActionType.WHEN)) 
                            actionList.put(evt.name,"Trigger")
                        else if(lastType.equals(ActionType.GIVEN))
                            actionList.put(evt.name,"Pre-condition")
                        else actionList.put(evt.name,"Observable")
                    }
                }
            }
        }
        '''
        action-list: { 
            «FOR act : actionList.keySet»
                «actionList.get(act)» «act» "«act»"
            «ENDFOR»
        }
        
        Requirements
        '''
    }
    	
	def ScenarioToLogsModel(Scenarios scenarios) {
	    '''
	    «FOR scn : scenarios.specFlowScenarios»
	       scenario «scn.name»
    	       «FOR evt : scn.events»
    	           «evt.name»
    	       «ENDFOR»
	    «ENDFOR»
	    '''
	}
	
	def doGenerate(Scenarios scenarios, String path, IFileSystemAccess fsa){
		for(s : scenarios.scenarios){
			fsa.generateFile(path + s.name + ".traces", ScenarioToTraceModel(s, scenarios.imports))
		}
	}
	
	def ScenarioToXESModel(Scenarios scns) {
		var idx = 1
		'''
		<?xml version="1.0" encoding="UTF-8" ?>
		<!-- XES version 1.0 -->
		<!-- Created by ComMA (http://comma.esi.nl -->
		<!-- (c) 2021 ComMA Team  -->
		<log xes.version="1.0" xmlns="http://code.deckfour.org/xes" xes.creator="ComMA">
			<extension name="Concept" prefix="concept" uri="http://code.deckfour.org/xes/concept.xesext"/>
			<extension name="Time" prefix="time" uri="http://code.deckfour.org/xes/time.xesext"/>
			<extension name="Organizational" prefix="org" uri="http://code.deckfour.org/xes/org.xesext"/>
			<global scope="trace">
				<string key="concept:name" value="name"/>
			</global>
			<global scope="event">
				<string key="concept:name" value="name"/>
				<string key="org:resource" value="resource"/>
				<date key="time:timestamp" value="2011-04-13T14:02:31.199+02:00"/>
				<string key="Activity" value="string"/>
				<string key="Resource" value="string"/>
				<string key="Costs" value="string"/>
			</global>
			<classifier name="Activity" keys="Activity"/>
			<classifier name="activity classifier" keys="Activity"/>
			<string key="creator" value="ComMA"/>
			«FOR s : scns.scenarios»
				<trace>
					<string key="concept:name" value="«idx»"/>
					«{idx++ ""}»
					«FOR evt : s.events»
						«IF evt instanceof EventPattern»
							«IF evt instanceof AnyEvent»
							«ELSEIF evt instanceof SignalEvent»
							<event>
								<string key="concept:name" value="«evt.event.name»"/>
								<string key="org:resource" value="Client"/>
								<date key="time:timestamp" value="2011-01-06T15:02:00.000+01:00"/>
								<string key="Activity" value="«evt.event.name»"/>
								<string key="Resource" value="Pete"/>
								<string key="Costs" value="50"/>
							</event>
							«ELSEIF evt instanceof CommandEvent»
							<event>
								<string key="concept:name" value="«evt.event.name»"/>
								<string key="org:resource" value="Client"/>
								<date key="time:timestamp" value="2011-01-06T15:02:00.000+01:00"/>
								<string key="Activity" value="«evt.event.name»"/>
								<string key="Resource" value="Pete"/>
								<string key="Costs" value="50"/>
							</event>							
							«ELSEIF evt instanceof CommandReply»
							<event>
								<string key="concept:name" value="reply-to-«evt.command.event.name»"/>
								<string key="org:resource" value="Server"/>
								<date key="time:timestamp" value="2011-01-06T15:02:00.000+01:00"/>
								<string key="Activity" value="reply-to-«evt.command.event.name»"/>
								<string key="Resource" value="Pete"/>
								<string key="Costs" value="50"/>
							</event>
							«ELSEIF evt instanceof NotificationEvent»
							<event>
								<string key="concept:name" value="«evt.event.name»"/>
								<string key="org:resource" value="Server"/>
								<date key="time:timestamp" value="2011-01-06T15:02:00.000+01:00"/>
								<string key="Activity" value="«evt.event.name»"/>
								<string key="Resource" value="Pete"/>
								<string key="Costs" value="50"/>
							</event>
							«ELSE»
								FATAL: UNHANDLED EVENT TYPE!
							«ENDIF»
						«ENDIF»
					«ENDFOR»
				</trace>
			«ENDFOR»
		</log>
		'''
	}
	
	def ScenarioToTraceModel(Scenario s, List<Import> imports)
	'''
	«FOR i : imports»
	import "«i.importURI»"
	«ENDFOR»
	
	server «DEFAULT_SERVER_NAME» on «DEFAULT_SERVER_IP»
	client «DEFAULT_CLIENT_NAME» on «DEFAULT_CLIENT_IP» uses «FOR i : determineUsedInterfaces(s) SEPARATOR ' '»«i.name»«ENDFOR»
	
	«FOR ev : s.events»
	«generateTimeHeader»
	«generateMessage(ev)»
	
	«ENDFOR»
	'''
	
	def generateTimeHeader()
	'''
	Timing: 0.0
	Timestamp: 0.0
	'''
	
	def dispatch generateMessage(CommandEvent ev)
	'''
	src address: «DEFAULT_CLIENT_IP»
	dest address: «DEFAULT_SERVER_IP»
	Interface: «(ev.event.eContainer as Signature).name»
	Command: «ev.event.name»
	«generateParametersBlock(ev.event, ev.parameters)»
	'''
	
	def dispatch generateMessage(SignalEvent ev)
	'''
	src address: «DEFAULT_CLIENT_IP»
	dest address: «DEFAULT_SERVER_IP»
	Interface: «(ev.event.eContainer as Signature).name»
	Command: «ev.event.name» SIGNAL
	«generateParametersBlock(ev.event, ev.parameters)»
	'''
		
	def dispatch generateMessage(NotificationEvent ev)
	'''
	src address: «DEFAULT_SERVER_IP»
	dest address: «DEFAULT_CLIENT_IP»
	Interface: «(ev.event.eContainer as Signature).name»
	Command: «ev.event.name» NOTIFY
	«generateParametersBlock(ev.event, ev.parameters)»
	'''
	
	def dispatch generateMessage(CommandReply ev){
		val command = getCommandEventForReply(ev)
	'''
	src address: «DEFAULT_SERVER_IP»
	dest address: «DEFAULT_CLIENT_IP»
	Interface: «(command.eContainer as Signature).name»
	Command: «command.name» OK
	«IF ev.parameters.empty»
	«IF ! TypeUtilities::isVoid(command.type)»
	Parameter: «typeToComMASyntax(command.type)» : «generateDefaultValue(command.type)»
	«ENDIF»
	«ELSE»
	«generateParameter(command.type, ev.parameters.get(0))»
	«ENDIF»
	'''
	}
	
	def generateParametersBlock(InterfaceEvent trigger, List<Expression> paramValues)
	'''
	«IF ! trigger.parameters.empty»
	«IF paramValues.empty»
	«generateDefaultParameters(trigger)»
	«ELSE»
	«FOR p : paramValues»
	«generateParameter(trigger.parameters.get(paramValues.indexOf(p)).type, p)»
	«ENDFOR»
	«ENDIF»
	«ENDIF»
	'''
	
	def Command getCommandEventForReply(CommandReply ev){
		val parent = ev.eContainer as Scenario
		val int index = parent.events.indexOf(ev)
		(parent.events.get(index - 1) as CommandEvent).event as Command
	}
	
	def generateParameter(Type t, Expression e)
	'''
	Parameter: «typeToComMASyntax(t)» : «IF e instanceof ExpressionAny»«generateDefaultValue(t)»«ELSE»«exprToComMASyntax(e)»«ENDIF»
	'''
	
	def generateDefaultParameters(InterfaceEvent ev)
	'''
	«FOR p : ev.parameters»
	Parameter: «typeToComMASyntax(p.type)» : «generateDefaultValue(p.type)»
	«ENDFOR»
	'''
	
	def determineUsedInterfaces(Scenario s){
		var result = new ArrayList<Signature>()
		for(ev : s.events){
			val triggerFeature = ev.eClass.getEStructuralFeature("trigger")
			if(triggerFeature !== null){
				val triggerInterface = (ev.eGet(triggerFeature) as EObject).eContainer as Signature
				if(!result.contains(triggerInterface)){
					result.add(triggerInterface)
				}
 			}
		}
		result
	}
	
	override CharSequence generateTypeName(TypeDecl t){
		var String prefix = ""
		if(t.eContainer instanceof Signature){
			prefix = (t.eContainer as Signature).name + "::"
		}
		prefix + t.name
	}
	
}