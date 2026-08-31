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
import nl.esi.comma.constraints.generator.cpn.model.CPNTemplateResult

class FutureTemplates {
    val Helpers helpers = new Helpers
    
    def generateResponseTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent, 
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    ) 
    {
       val psBody =
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
			    with-guard      «helpers.getRefRepeatedActivationWhereClause(activationEventInst)»
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
		
		val acceptanceJson =
        '''
        {
          "schemaType": "matala.constraints.acceptance",
          "schemaVersion": 1,
          "templateType": "Response",
          "constraint": "«templateName»",
        
          "graph": {
            "format": "ltsvisualizer",
            "version": 1
          },
        
          "monitorPlaces": [
            "split",
            "final",
            "acceptor",
            "«correlationVar.name»"
          ],
        
          "acceptance": {
            "scope": "terminalNodes",
            "emptyPlaces": [
              ["split"],
              ["«correlationVar.name»"]
            ],
            "nonEmptyPlaces": [
            ["acceptor", "final"]
            ]
          }
        }
        '''
		
		return new CPNTemplateResult (psBody, acceptanceJson)
    }
    
    

    def generateChainResponseTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent, 
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo
    ) 
    {
       val psBody =
       '''
            system RootCHAINRESPONSE
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
                UNIT blockerseen
                UNIT acceptor
                UNIT final
                
                desc "«templateName»"
                
                action           UnmatchedActivation1
                element-label    "Unmatched Activation1"
                case             default priority 10
                with-inputs      «activationEventInfo.refName»
                with-guard       NOT(«helpers.getRefConcreteWhereClause(activationEventInst)»)
                produces-outputs     acceptor suppress
                
                action          RepeatedActivation
                element-label   "Repeated Activation"
                case            default priority 70
                with-inputs     split, «activationEventInfo.refName», «correlationVar.name»
                with-guard      «helpers.getRefConcreteWhereClause(activationEventInst)»
                produces-outputs    blockerseen suppress
                updates:
                     blockerseen := split
                produces-outputs    «correlationVar.name»
                updates:
                     «correlationVar.name» := «correlationVar.name»
                      
                 action          UnactivatedTarget
                 element-label   "Unactivated Target"
                 case            default priority 30
                 with-inputs     «targetEventInfo.refName»
                 with-guard      «helpers.getRefConcreteWhereClause(targetEventInst)»
                 produces-outputs    acceptor suppress
                 
                 action          UnmatchedTarget2
                 element-label   "Unmatched Target2"
                 case            default priority 60
                 with-inputs     split, «targetEventInfo.refName»
                 with-guard      NOT(«helpers.getRefConcreteWhereClause(targetEventInst)»)
                 produces-outputs   blockerseen suppress
                 updates:
                    blockerseen:=split
                 
                 action          Target
                 element-label   "Target"
                 case            default priority 80
                 with-inputs     split, «targetEventInfo.refName», «correlationVar.name»
                 with-guard      «helpers.getRefCombinedWhereClause(targetEventInst)»
                 produces-outputs    final suppress
                 updates:
                     final := split
                     
                 action           ANY2
                 element-label    "ANY2"
                 case             default priority 90
                 with-inputs      split, any
                 produces-outputs   blockerseen suppress
                 updates:
                    blockerseen := split
                    
                 action            UnmatchedTarget1
                 element-label     "Unmatched Target1"
                 case              default priority 20
                 with-inputs       «targetEventInfo.refName»
                 with-guard        NOT(«helpers.getRefConcreteWhereClause(targetEventInst)»)
                 produces-outputs   acceptor suppress
                  
                 action          Activation
                 element-label   "Activation"
                 case            default priority 60
                 with-inputs     «activationEventInfo.refName»
                 with-guard      «helpers.getRefConcreteWhereClause(activationEventInst)»
                 produces-outputs    split suppress
                 produces-outputs    «correlationVar.name»
                 updates:
                     «helpers.getRefWithClause(activationEventInst)»
                     
                 action           UnmatchedActivation2
                 element-label    "Unmatched Activation2"
                 case             default priority 40
                 with-inputs      split, «activationEventInfo.refName»
                 with-guard       NOT(«helpers.getRefConcreteWhereClause(activationEventInst)»)
                 produces-outputs     blockerseen suppress
                 updates:
                    blockerseen := split

                 
                 action          ANY1
                 element-label   "ANY1"
                 case            default priority 80
                 with-inputs     any
                 produces-outputs    acceptor suppress
                 
                 element-labels ["Root", "CHAINRESPONSE"]
            }
        ''' 
        val acceptanceJson =
        '''
        {
                  "schemaType": "matala.constraints.acceptance",
                  "schemaVersion": 1,
                  "templateType": "ChainResponse",
                  "constraint": "«templateName»",
                
                  "graph": {
                    "format": "ltsvisualizer",
                    "version": 1
                  },
                
                  "monitorPlaces": [
                    "split",
                    "final",
                    "acceptor",
                    "«correlationVar.name»",
                    "blockerseen"
                  ],
                
                  "acceptance": {
                    "scope": "terminalNodes",
                    "emptyPlaces": [
                      ["split"],
                      ["«correlationVar.name»"],
                      ["blockerseen"]
                    ],
                    "nonEmptyPlaces": [
                    ["acceptor", "final"]
                    ]
                  }
                }
        '''
        return new CPNTemplateResult (psBody, acceptanceJson)
    }

    def generateAlternateResponseTemplate(
        String templateName, Variable correlationVar,
        Ref activationEventInst, RefInfo activationEventInfo, String activationEvent, 
        Ref targetEventInst, String targetEvent, RefInfo targetEventInfo,
        Ref intermediateEventInst, String intermediateEvent, RefInfo intermediateEventInfo
    ) 
    {
       val psBody =
       '''
            system RootALTERNATERESPONSE
            {
                inputs
                «activationEventInfo.refType» «activationEventInfo.refName»
                «IF targetEventInfo.refType != activationEventInfo.refType || targetEventInfo.refName != activationEventInfo.refName»
                    «targetEventInfo.refType» «targetEventInfo.refName»
                «ENDIF»
                «IF intermediateEventInfo.refType != activationEventInfo.refType || intermediateEventInfo.refName != activationEventInfo.refName»
                    «IF intermediateEventInfo.refType != targetEventInfo.refType || intermediateEventInfo.refName != targetEventInfo.refName»
                        «intermediateEventInfo.refType» «intermediateEventInfo.refName»
                    «ENDIF»
                «ENDIF»
                ANY any
            
                local
                «correlationVar.type.type.name» «correlationVar.name»
                «correlationVar.type.type.name» rejecting_tokens
                UNIT split
                UNIT acceptor
                UNIT final
                
                desc "«templateName»"
                
                action          RepeatedActivation
                element-label   "Repeated Activation"
                case            default priority 70
                with-inputs     split, «activationEventInfo.refName», «correlationVar.name»
                with-guard      «helpers.getRefRepeatedActivationWhereClause(activationEventInst)»
                produces-outputs    split suppress
                updates:
                     split := split
                produces-outputs    «correlationVar.name»
                updates:
                     «correlationVar.name» := «correlationVar.name»
                      
                action          UnactivatedTarget
                element-label   "Unactivated Target"
                case            default priority 40
                with-inputs     «targetEventInfo.refName»
                with-guard      «helpers.getRefConcreteWhereClause(targetEventInst)»
                produces-outputs    acceptor suppress
                 
                action          Target
                element-label   "Target"
                case            default priority 60
                with-inputs     split, «targetEventInfo.refName», «correlationVar.name»
                with-guard      «helpers.getRefCombinedWhereClause(targetEventInst)»
                produces-outputs    final suppress
                updates:
                    final := split
                 
                action           UnmatchedActivation
                element-label    "Unmatched Activation"
                case             default priority 10
                with-inputs      «activationEventInfo.refName»
                with-guard       NOT(«helpers.getRefConcreteWhereClause(activationEventInst)»)
                produces-outputs   acceptor suppress
                 
                action            UnmatchedBlocker
                element-label     "Unmatched Blocker"
                case              default priority 30
                with-inputs       «intermediateEventInfo.refName»
                with-guard        NOT(«helpers.getRefConcreteWhereClause(intermediateEventInst)»)
                produces-outputs   acceptor suppress
                  
                action          Activation
                element-label   "Activation"
                case            default priority 60
                with-inputs     «activationEventInfo.refName»
                with-guard      «helpers.getRefConcreteWhereClause(activationEventInst)»
                produces-outputs    split suppress
                produces-outputs    «correlationVar.name»
                updates:
                    «helpers.getRefWithClause(activationEventInst)»
                 
                action          ANY
                element-label   "ANY"
                case            default priority 90
                with-inputs     any
                produces-outputs    acceptor suppress
                 
                action         UnactivatedBlocker
                element-label  "Unactivated Blocker"
                case           default priority 50
                with-inputs    «intermediateEventInfo.refName»
                with-guard     «helpers.getRefConcreteWhereClause(intermediateEventInst)»
                produces-outputs   acceptor suppress
                 
                action         UnmatchedTarget
                element-label  "Unmatched Target"
                case           default priority 20
                with-inputs    «targetEventInfo.refName»
                with-guard     NOT(«helpers.getRefConcreteWhereClause(targetEventInst)»)
                produces-outputs   acceptor suppress
                 
                action         Blocker
                element-label  "Blocker"
                case           default priority 80
                with-inputs    split, «intermediateEventInfo.refName», «correlationVar.name»
                with-guard     «helpers.getRefCombinedWhereClause(intermediateEventInst)»
                produces-outputs   rejecting_tokens
                updates:
                   rejecting_tokens := «correlationVar.name»
                   
                element-labels ["Root", "ALTERNATERESPONSE"]
            }
        ''' 
        val acceptanceJson =
        '''
        {
                          "schemaType": "matala.constraints.acceptance",
                          "schemaVersion": 1,
                          "templateType": "AlternateResponse",
                          "constraint": "«templateName»",
                        
                          "graph": {
                            "format": "ltsvisualizer",
                            "version": 1
                          },
                        
                          "monitorPlaces": [
                            "split",
                            "final",
                            "acceptor",
                            "«correlationVar.name»",
                            "rejecting_tokens"
                          ],
                        
                          "acceptance": {
                            "scope": "terminalNodes",
                            "emptyPlaces": [
                              ["split"],
                              ["«correlationVar.name»"],
                              ["rejecting_tokens"]
                            ],
                            "nonEmptyPlaces": [
                            ["acceptor", "final"]
                            ]
                          }
                        }
        '''
        return new CPNTemplateResult (psBody, acceptanceJson)
        
    }

}