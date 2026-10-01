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

class ExistentialTemplates {
    val Helpers helpers = new Helpers
    
    def generateCountTemplate(
       String templateName, Ref eventInst, RefInfo eventInfo, String event, String operator, int number, String constraintType
    ) 
    {
       val psBody =
       '''
            system Root«constraintType»
            {
                inputs
                «eventInfo.refType» «eventInfo.refName»
                ANY any
                EOT endoftrace
                StepMetaData    StepMetaData
                
                outputs
                StepMetaData    StepMetaData
            
                local
                Counter Countctx

                UNIT acceptor
                UNIT final
                
                init
                Countctx:= Counter { count = 0, MetaData= <map<string,string[]>>{"eventIds" -> <string[]>[]}  }
                
                desc "«templateName»"
                
                action           CountOccurrence
                element-label    "Count Occurrence"
                case             default priority 10
                with-inputs      «eventInfo.refName», Countctx, StepMetaData
                with-guard       «helpers.getRefConcreteWhereClause(eventInst)»
                produces-outputs    Countctx
                updates:
                    Countctx:= Counter { 
                                count = Countctx.count + 1,
                                MetaData = <map<string,string[]>>{"eventIds" -> add (Countctx.MetaData["eventIds"], StepMetaData.steps["stepid"])}
                    }
                produces-outputs    StepMetaData
                updates:
                    StepMetaData := StepMetaData
                        
                action           CounterValidator
                element-label    "Counter Validator"
                case             default priority 10
                with-inputs      endoftrace, Countctx
                with-guard       Countctx.count «operator» «number»
                produces-outputs    final suppress 
                
                action          ANY
                element-label   "ANY"
                case            default priority 20
                with-inputs     any
                produces-outputs    acceptor suppress
                 
                 element-labels ["Root", "«constraintType»"]
            }
        ''' 
        
        val acceptanceJson =
        '''
        {
          "schemaType": "matala.constraints.acceptance",
          "schemaVersion": 1,
          "templateType": "«constraintType»",
          "constraint": "«templateName»",
        
          "graph": {
            "format": "ltsvisualizer",
            "version": 1
          },
        
          "monitorPlaces": [
            "final",
            "acceptor",
            "endoftrace"
          ],
        
          "acceptance": {
            "scope": "terminalNodes",
            "emptyPlaces": [
              ["endoftrace"]
            ],
            "nonEmptyPlaces": [
            ["acceptor", "final"]
            ]
          }
        }
        '''
        
        val requirementText =
            switch constraintType {
                case "ATLEAST": '''at least «number» times'''
                case "ATMOST": '''at most «number» times'''
                case "EXACT": '''exactly «number» times'''
                default: '''«operator» «number» times'''
            }
        
        val eventLabel = '''(«event» where «helpers.getRefConcreteWhereClause(eventInst)»)'''
        
        val diagnostics =
        '''
        [
            {
                "kind": "unfulfilledCount",
                "valueKind": "count",
                "includeRawToken": False,
                "eventLabel": "«helpers.escapePythonString(eventLabel)»",
                "event": {
                    "name": "«helpers.escapePythonString(event)»",
                    "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(eventInst))»",
                    "stepIdsFrom": "eventIds"
                },
                "triggerPlace": "endoftrace",
                "tokenPlace": "Countctx",
                "requirement": "«requirementText»",
                "message": "The step was observed {actualCount} times; expected {requirement}."
            }
        ]
        '''        
        return new CPNTemplateResult (psBody, acceptanceJson, diagnostics)
    }
    
    def generateFirstEventTemplate(
        String templateName,Ref eventInst, RefInfo eventInfo, String event,  String constraintType
        ) 
        {
            val psBody =
            '''
                system Root«constraintType»OCCURRENCE
                {
                    inputs
                    «eventInfo.refType» «eventInfo.refName»
                    ANY any
        
                    local
                    UNIT  final
        
                    desc "«templateName»"
        
                    action InitialMatch
                    element-label "Initial Match"
                    case default priority 10
                    with-inputs «eventInfo.refName»
                    with-guard «helpers.getRefConcreteWhereClause(eventInst)»
                    produces-outputs final suppress
        
                    element-labels ["Root", "«constraintType» OCCURRENCE"]
                }
            '''
        
            val acceptanceJson =
            '''
            {
              "schemaType": "matala.constraints.acceptance",
              "schemaVersion": 1,
              "templateType": "«constraintType»",
              "constraint": "«templateName»",
              
              "graph": {
                "format": "ltsvisualizer",
                "version": 1
              },
              
              "monitorPlaces": [
                "final"
              ],
              
              "acceptance": {
                "scope": "terminalNodes",
                "emptyPlaces": [],
                "nonEmptyPlaces": [
                  ["final"]
                ]
              }
            }
            '''
            val boundaryDescription =
                if (constraintType == "INIT") {
                    "start with"
                } else {
                    "end with"
                }
            val boundaryPosition =
                if (constraintType == "INIT") {
                    "first"
                } else {
                    "last"
                }
            val eventLabel = '''(«event» where «helpers.getRefConcreteWhereClause(eventInst)»)'''
            
            val diagnostics =
            '''
            [
                {
                    "kind": "missingBoundaryEvent",
                    "valueKind": "none",
                    "includeRawToken": False,
                    "eventLabel": "«helpers.escapePythonString(eventLabel)»",
                    "event": {
                        "name": "«helpers.escapePythonString(event)»",
                        "whereConcrete": "«helpers.escapePythonString(helpers.getRefConcreteWhereClause(eventInst))»"
                    },
                    "violationStep": {
                        "relation": "testCaseBoundary",
                        "position": "«boundaryPosition»"
                    },
                    "triggerPlace": "final",
                    "violationKind": "nonEmptyPlaces",
                    "message": "The trace does not «boundaryDescription» the required test step."
                }
            ]
            '''
            return new CPNTemplateResult(psBody, acceptanceJson, diagnostics)
        }
    
}