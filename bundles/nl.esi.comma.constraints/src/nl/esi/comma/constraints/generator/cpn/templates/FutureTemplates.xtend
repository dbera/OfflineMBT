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
        Ref activationEventInst, RefInfo actEventInfo, String activationEvent, 
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    ) 
    {
       return
       '''
			system RootRESPONSE
			{
			    inputs
			    «actEventInfo.refType» «actEventInfo.refName»
			    «IF targetEventInfo.refType != actEventInfo.refType && targetEventInfo.refName != actEventInfo.refName»
			    	«targetEventInfo.refType» «targetEventInfo.refName»
			    «ENDIF»
			
			    local
			    «correlationVar.type.type.name» «correlationVar.name»
			    UNIT split
			
			    desc "«templateName»"
			
			    action          UnactivatedTarget
			    element-label   "Unactivated Target"
			    case            default priority 10
			    with-inputs     «targetEventInfo.refName»
			    with-guard      «helpers.getRefWhereClause(targetEventInst)»
			
			    action          RepeatedActivation
			    element-label   "Repeated Activation"
			    case            default priority 30
			    with-inputs     split, «actEventInfo.refName», «correlationVar.name»
			    with-guard      «helpers.getRefAllWhereClause(activationEventInst)»
			    produces-outputs    split suppress
			    updates:
			    split := split
			    produces-outputs «correlationVar.name»
			    updates:
			        «correlationVar.name» := «correlationVar.name»
			
			    action          Target
			    element-label   "Target"
			    case            default priority 20
			    with-inputs     split, «targetEventInfo.refName», «correlationVar.name»
			    with-guard      «helpers.getRefWhereClause(targetEventInst)»
			
			    action          Activation
			    element-label   "Activation"
			    case            default priority 20
			    with-inputs     «actEventInfo.refName»
			    with-guard      «helpers.getRefWhereClause(activationEventInst)»
			    produces-outputs split suppress
			    produces-outputs «correlationVar.name»
			    updates:
			    «helpers.getRefWithClause(activationEventInst)»
			
			    element-labels ["Root", "RESPONSE"]
			}
		''' 
    }
    
}
