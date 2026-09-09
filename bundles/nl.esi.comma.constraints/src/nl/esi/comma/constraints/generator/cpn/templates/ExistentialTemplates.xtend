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
            
                local
                Counter Countctx

                UNIT acceptor
                UNIT final
                
                init
                Countctx:= Counter { count = 0 }
                
                desc "«templateName»"
                
                action           CountOccurrence
                element-label    "Count Occurrence"
                case             default priority 10
                with-inputs      «eventInfo.refName», Countctx
                with-guard       «helpers.getRefConcreteWhereClause(eventInst)»
                produces-outputs    Countctx
                updates:
                    Countctx:= Counter { count = Countctx.count + 1 }
                    
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
        
        return new CPNTemplateResult (psBody, acceptanceJson)
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
        
            return new CPNTemplateResult(psBody, acceptanceJson)
        }
    
}