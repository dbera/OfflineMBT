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
import nl.esi.comma.constraints.generator.cpn.Helpers

class PastTemplates {
    val FutureTemplates futuretemplates = new FutureTemplates
    val Helpers helpers = new Helpers
    
    def generatePrecedenceTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    )
    {
        val result = futuretemplates.generateResponseTemplate(templateName, correlationVar,
        activationEventInst, activationEventInfo, activationEvent,
        targetEventInst, targetEvent, targetEventInfo )
        
        val activationLabel = '''(«activationEvent» where «helpers.getRefConcreteWhereClause(activationEventInst)»)'''
        val targetLabel = '''(«targetEvent» where «helpers.getRefConcreteWhereClause(targetEventInst)»)'''
        
        val diagnostics =
        '''
        [
            {
                "kind": "unfulfilledPrecedence",
                "valueKind": "correlation",
                "tokenPlace": "«correlationVar.name»",
                "activationLabel": "«activationLabel»",
                "targetLabel": "«targetLabel»",
                "message": "{activationLabel} with correlation {correlation} was not preceded by {targetLabel} with correlation {correlation}."
            }
        ]
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
        
        val activationLabel = '''(«activationEvent» where «helpers.getRefConcreteWhereClause(activationEventInst)»)'''
        val targetLabel = '''(«targetEvent» where «helpers.getRefConcreteWhereClause(targetEventInst)»)'''
        
        val diagnostics =
        '''
        [
            {
                "kind": "unfulfilledChainPrecedence",
                "valueKind": "correlation",
                "tokenPlace": "«correlationVar.name»",
                "activationLabel": "«activationLabel»",
                "targetLabel": "«targetLabel»",
                "message": "{activationLabel} with correlation {correlation} was not immediately preceded by {targetLabel} with correlation {correlation}."
            }
        ]
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
        
        
        val activationLabel = '''(«activationEvent» where «helpers.getRefConcreteWhereClause(activationEventInst)»)'''
        val targetLabel = '''(«targetEvent» where «helpers.getRefConcreteWhereClause(targetEventInst)»)'''
        val intermediateLabel = '''(«intermediateEvent» where «helpers.getRefConcreteWhereClause(intermediateEventInst)»)'''
        val diagnostics =
        '''
        [
            {
                "kind": "unfulfilledAlternatePrecedence",
                "valueKind": "correlation",
                "tokenPlace": "«correlationVar.name»",
                "activationLabel": "«activationLabel»",
                "targetLabel": "«targetLabel»",
                "intermediateLabel": "«intermediateLabel»",
                "message": "{activationLabel} with correlation {correlation} was not preceded by {targetLabel} with correlation {correlation}."
            },
            {
                "kind": "unfulfilledAlternatePrecedence",
                "valueKind": "correlation",
                "tokenPlace": "rejecting_tokens",
                "activationLabel": "«activationLabel»",
                "targetLabel": "«targetLabel»",
                "intermediateLabel": "«intermediateLabel»",
                "message": "{activationLabel} with correlation {correlation} was seen but then was preceded by a blocker before {targetLabel} with correlation {correlation}"
            }
        ]
        '''
        
        return new CPNTemplateResult(
            result.psBody,
            result.acceptanceJson.replace('"templateType": "AlternateResponse"', '"templateType": "AlternatePrecedence"'),
            diagnostics
        )
    }
}