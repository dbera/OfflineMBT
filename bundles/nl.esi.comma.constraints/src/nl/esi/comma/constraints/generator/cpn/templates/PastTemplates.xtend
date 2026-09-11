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
import nl.esi.comma.constraints.generator.cpn.model.CPNTemplateResult
import nl.esi.comma.constraints.generator.cpn.model.RefInfo
import nl.esi.xtext.expressions.expression.Variable

class PastTemplates {
    val FutureTemplates futuretemplates = new FutureTemplates
    
    def generatePrecedenceTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    )
    {
        val result = futuretemplates.generateResponseTemplate(templateName, correlationVar,
        activationEventInst, activationEventInfo, activationEvent,
        targetEventInst, targetEvent, targetEventInfo )
        
        val diagnostics=
        '''
        return []
        '''
        
        return new CPNTemplateResult(
            result.psBody,
            result.acceptanceJson.replace('"templateType": "Response"', '"templateType": "Precedence"'),
            diagnostics
        )
    }
    
    def generateChainPrecedenceTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    )
    {
        val result = futuretemplates.generateChainResponseTemplate(templateName, correlationVar,
        activationEventInst, activationEventInfo, activationEvent,
        targetEventInst, targetEvent, targetEventInfo )
        
        val diagnostics=
        '''
        return []
        '''
        
        return new CPNTemplateResult(
            result.psBody,
            result.acceptanceJson.replace('"templateType": "ChainResponse"', '"templateType": "ChainPrecedence"'),
            diagnostics
        )
    }
    
    def generateAlternatePrecedenceTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo,
        Ref intermediateEventInst, String intermediateEvent, RefInfo intermediateEventInfo
    )
    {
        val result = futuretemplates.generateAlternateResponseTemplate(templateName, correlationVar,
        activationEventInst, activationEventInfo, activationEvent,
        targetEventInst, targetEvent, targetEventInfo,
        intermediateEventInst, intermediateEvent, intermediateEventInfo )
        
        val diagnostics=
        '''
        return []
        '''
        
        return new CPNTemplateResult(
            result.psBody,
            result.acceptanceJson.replace('"templateType": "AlternateResponse"', '"templateType": "AlternatePrecedence"'),
            diagnostics
        )
    }
}