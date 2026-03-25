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

import java.util.HashMap
import java.util.List
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.scenarios.scenarios.ActionType
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.types.types.Type
import nl.esi.xtext.common.lang.base.Import
import org.eclipse.xtext.generator.IFileSystemAccess

class ScenarioTracesGenerator extends ExpressionsCommaGenerator {
	final static String DEFAULT_SERVER_IP = "192.68.32.1"
	final static String DEFAULT_CLIENT_IP = "192.68.32.2"
	final static String DEFAULT_SERVER_NAME = "server1"
	final static String DEFAULT_CLIENT_NAME = "client1"

	
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
	
		
	def ScenarioToTraceModel(Scenario s, List<Import> imports)
	'''
	«FOR i : imports»
	import "«i.importURI»"
	«ENDFOR»
	
	server «DEFAULT_SERVER_NAME» on «DEFAULT_SERVER_IP»
	
	«FOR ev : s.events»
	«generateTimeHeader»
	
	«ENDFOR»
	'''
	
	def generateTimeHeader()
	'''
	Timing: 0.0
	Timestamp: 0.0
	'''
	def generateParameter(Type t, Expression e)
	'''
	Parameter: «typeToComMASyntax(t)» : «IF e instanceof ExpressionAny»«generateDefaultValue(t)»«ELSE»«exprToComMASyntax(e)»«ENDIF»
	'''
	
}