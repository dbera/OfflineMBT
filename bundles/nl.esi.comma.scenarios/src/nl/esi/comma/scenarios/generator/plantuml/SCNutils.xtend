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

import nl.esi.comma.scenarios.scenarios.Scenario
import java.util.ArrayList
import nl.esi.comma.actions.actions.EventPattern
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.scenarios.scenarios.NotificationEvent
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.SignalEvent

class SCNutils {

	def static getSCNName(Scenario scn) {
		return scn.name
	}
	
	def static getScenarioSequence(Scenario scn) {
		var seq = new ArrayList<String>
		for(evt : scn.events)	{
			if(evt instanceof EventPattern) {
				if(evt instanceof CommandEvent) {
					 seq.add(evt.event.name)
				}
				else if(evt instanceof NotificationEvent) {
					seq.add(evt.event.name)		
				}
				else if(evt instanceof CommandReply) {
					//seq.add("reply to command "+evt.command.event.name)
					seq.add("reply")
				}
				else if(evt instanceof SignalEvent) {
					seq.add(evt.event.name)
				}
				else {
					// AnyEvent: Handle?
				}
			}
		}
		seq		
	}
}

/*
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
	
	def getScenarioSequence(Scenario scn) {
		var seq = new ArrayList<String>
		for(evt : scn.events)	{
			if(evt instanceof EventPattern) {
				if(evt instanceof CommandEvent) {
					 
				}
				else if(evt instanceof NotificationEvent) {
							
				}
				else if(evt instanceof CommandReply) {
					
				}
				else if(evt instanceof SignalEvent) {
					
				}
				else {
					// AnyEvent: Handle?
				}
			}
		}		
	}
*/
