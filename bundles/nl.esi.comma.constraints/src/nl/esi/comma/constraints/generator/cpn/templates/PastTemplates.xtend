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
import nl.esi.comma.constraints.generator.cpn.Helpers
import nl.esi.comma.constraints.generator.cpn.model.CPNTemplateResult
import nl.esi.comma.constraints.generator.cpn.model.RefInfo

class PastTemplates {
    val FutureTemplates futuretemplates = new FutureTemplates
    val Helpers helpers = new Helpers
    
    def generatePrecedenceTemplate(
        String templateName, RefInfo correlationInfo, boolean hasCorrelation,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    )
    {
        val result = futuretemplates.generateResponseTemplate(templateName, correlationInfo, hasCorrelation,
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
                "hasCorrelation": «IF hasCorrelation»True«ELSE»False«ENDIF»,
                "includeRawToken": False,
                "tokenPlace": "«correlationInfo.refName»",
                "activationLabel": "«helpers.escapePythonString(activationLabel)»",
                "targetLabel": "«helpers.escapePythonString(targetLabel)»",
                "activationEvent": {
                    "name": "«helpers.escapePythonString(activationEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(activationEventInst))»",
                    "correlationBinding": "«helpers.escapePythonString(helpers.getRefWithClause(activationEventInst).trim)»",
                    "stepIdsFrom": "activationIds"
                },
                "targetEvent": {
                    "name": "«helpers.escapePythonString(targetEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(targetEventInst))»",
                    "whereCorrelation": "«helpers.escapePythonString(helpers.getRefCorrelationWhereClause(targetEventInst))»"
                },
                "message": "The triggering event occurred without its required prior event «IF hasCorrelation» with matching correlation«ENDIF»."
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
        String templateName, RefInfo correlationInfo, boolean hasCorrelation,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    )
    {
        val result = futuretemplates.generateChainResponseTemplate(templateName, correlationInfo, hasCorrelation,
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
                "hasCorrelation": «IF hasCorrelation»True«ELSE»False«ENDIF»,
                "includeRawToken": False,
                "tokenPlace": "«correlationInfo.refName»",
                "activationLabel": "«helpers.escapePythonString(activationLabel)»",
                "targetLabel": "«helpers.escapePythonString(targetLabel)»",
                "activationEvent": {
                    "name": "«helpers.escapePythonString(activationEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(activationEventInst))»",
                    "correlationBinding": "«helpers.escapePythonString(helpers.getRefWithClause(activationEventInst).trim)»",
                    "stepIdsFrom": "activationIds"
                },
                "targetEvent": {
                    "name": "«helpers.escapePythonString(targetEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(targetEventInst))»",
                    "whereCorrelation": "«helpers.escapePythonString(helpers.getRefCorrelationWhereClause(targetEventInst))»"
                },
                "violationStep": {
                    "relation": "immediatePredecessor",
                    "of": "activationEvent"
                },
                "message": "The triggering event was not immediately preceded by its required event «IF hasCorrelation» with matching correlation«ENDIF»."
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
        String templateName, RefInfo correlationInfo, boolean hasCorrelation,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent,
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo,
        Ref intermediateEventInst, String intermediateEvent, RefInfo intermediateEventInfo
    )
    {
        val result = futuretemplates.generateAlternateResponseTemplate(templateName, correlationInfo, hasCorrelation,
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
                "hasCorrelation": «IF hasCorrelation»True«ELSE»False«ENDIF»,
                "includeRawToken": False,
                "tokenPlace": "«correlationInfo.refName»",
                "activationLabel": "«helpers.escapePythonString(activationLabel)»",
                "targetLabel": "«helpers.escapePythonString(targetLabel)»",
                "intermediateLabel": "«helpers.escapePythonString(intermediateLabel)»",
                "activationEvent": {
                    "name": "«helpers.escapePythonString(activationEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(activationEventInst))»",
                    "correlationBinding": "«helpers.escapePythonString(helpers.getRefWithClause(activationEventInst).trim)»",
                    "stepIdsFrom": "activationIds"
                },
                "targetEvent": {
                    "name": "«helpers.escapePythonString(targetEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(targetEventInst))»",
                    "whereCorrelation": "«helpers.escapePythonString(helpers.getRefCorrelationWhereClause(targetEventInst))»"
                },
                "message": "The triggering event occurred without its required earlier event «IF hasCorrelation» with matching correlation«ENDIF»."
            },
            {
                "kind": "unfulfilledAlternatePrecedence",
                "valueKind": "correlation",
                "hasCorrelation": «IF hasCorrelation»True«ELSE»False«ENDIF»,
                "includeRawToken": False,
                "tokenPlace": "rejecting_tokens",
                "activationLabel": "«helpers.escapePythonString(activationLabel)»",
                "targetLabel": "«helpers.escapePythonString(targetLabel)»",
                "intermediateLabel": "«helpers.escapePythonString(intermediateLabel)»",
                "activationEvent": {
                    "name": "«helpers.escapePythonString(activationEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(activationEventInst))»",
                    "correlationBinding": "«helpers.escapePythonString(helpers.getRefWithClause(activationEventInst).trim)»",
                    "stepIdsFrom": "activationIds"
                },
                "targetEvent": {
                    "name": "«helpers.escapePythonString(targetEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(targetEventInst))»",
                    "whereCorrelation": "«helpers.escapePythonString(helpers.getRefCorrelationWhereClause(targetEventInst))»"
                },
                "blockerEvent": {
                    "name": "«helpers.escapePythonString(intermediateEvent)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(intermediateEventInst))»",
                    "whereCorrelation": "«helpers.escapePythonString(helpers.getRefCorrelationWhereClause(intermediateEventInst))»",
                    "stepIdsFrom": "blockerIds"
                },
                "message": "A blocker prevented the required earlier event."
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