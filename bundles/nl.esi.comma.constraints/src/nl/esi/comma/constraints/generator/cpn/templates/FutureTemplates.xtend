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

package nl.esi.comma.constraints.generator.cpn.templates

import nl.esi.comma.constraints.constraints.Ref
import nl.esi.xtext.expressions.expression.Variable
import nl.esi.comma.constraints.generator.cpn.model.RefInfo
import nl.esi.comma.constraints.generator.cpn.Helpers

class FutureTemplates {
    val Helpers helpers = new Helpers
    
    def generateResponseTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent, 
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    ) 
    {
       return
       '''
			system RootRESPONSE
			{
			    inputs
			    «activationEventInfo.refType» «activationEventInfo.refName»
			    «IF targetEventInfo.refType != activationEventInfo.refType || targetEventInfo.refName != activationEventInfo.refName»
			    	«targetEventInfo.refType» «targetEventInfo.refName»
			    «ENDIF»
			    ANY any
			
			    local
			    «correlationVar.type.type.name» «correlationVar.name»
			    UNIT split
			    UNIT acceptor
			    UNIT final
			    
			    desc "«templateName»"
			    
			    action           UnmatchedActivation
			    element-label    "Unmatched Activation"
			    case             default priority 10
			    with-inputs      «activationEventInfo.refName»
			    with-guard       NOT(«helpers.getRefConcreteWhereClause(activationEventInst)»)
			    produces-outputs     acceptor suppress
			    
			    action          RepeatedActivation
			    element-label   "Repeated Activation"
			    case            default priority 50
			    with-inputs     split, «activationEventInfo.refName», «correlationVar.name»
			    with-guard      «helpers.getRefCombinedWhereClause(activationEventInst)»
			    produces-outputs    split suppress
			    updates:
			         split := split
			    produces-outputs    «correlationVar.name»
			    updates:
			         «correlationVar.name» := «correlationVar.name»
			          
			     action          UnactivatedTarget
			     element-label   "Unactivated Target"
			     case            default priority 30
			     with-inputs     «targetEventInfo.refName»
			     with-guard      «helpers.getRefConcreteWhereClause(targetEventInst)»
			     produces-outputs    acceptor suppress
			     
			     action          Target
			     element-label   "Target"
			     case            default priority 40
			     with-inputs     split, «targetEventInfo.refName», «correlationVar.name»
			     with-guard      «helpers.getRefCombinedWhereClause(targetEventInst)»
			     produces-outputs    final suppress
			     updates:
			         final := split
			      
			     action          Activation
			     element-label   "Activation"
			     case            default priority 40
			     with-inputs     «activationEventInfo.refName»
			     with-guard      «helpers.getRefConcreteWhereClause(activationEventInst)»
			     produces-outputs    split suppress
			     produces-outputs    «correlationVar.name»
			     updates:
			         «helpers.getRefWithClause(activationEventInst)»
			         
			     action           UnmatchedTarget
			     element-label    "Unmatched Target"
			     case             default priority 20
			     with-inputs      «targetEventInfo.refName»
			     with-guard       NOT(«helpers.getRefConcreteWhereClause(targetEventInst)»)
			     produces-outputs     acceptor suppress

			     
			     action          ANY
			     element-label   "ANY"
			     case            default priority 40
			     with-inputs     any
			     produces-outputs    acceptor suppress
			     
			     element-labels ["Root", "RESPONSE"]
			}
		''' 
    }
    
}
