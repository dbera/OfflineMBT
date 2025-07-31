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
package nl.esi.comma.causalgraph.generator

import java.util.HashSet
import nl.esi.comma.causalgraph.causalGraph.ActionsBody
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.ControlFlowEdge
import nl.esi.comma.causalgraph.causalGraph.DataFlowEdge
import nl.esi.comma.causalgraph.causalGraph.LanguageBody
import nl.esi.comma.causalgraph.causalGraph.Node
import nl.esi.comma.causalgraph.causalGraph.StepBody
import org.eclipse.xtext.generator.IFileSystemAccess2

class CausalGraphPlantUML {
    def generatePlantUML(CausalGraph prod, IFileSystemAccess2 fsa) {
        // Causal Graph Handling
        toPlantUML(fsa, prod)
    }

    def toPlantUML(IFileSystemAccess2 fsa, CausalGraph cg) {
        val colors = #['#LightBlue', '#LightGreen', '#LightYellow', '#LightPink']
        val scenarios = cg.nodes
            .flatMap[n | n.tests.map[s | s.name.name]]
            .toSet.toList
            
        var cgTxt = ''''''
        cg.name
        cgTxt = '''
            @startuml
            «FOR n : cg.nodes»
                class «n.name» { 
                step-name: «n.stepName»
                step-type: «n.stepType»
                «IF !n.stepParameters.isEmpty»
                    step-params: «n.stepParameters.map[p|p.name].join(", ")»
                «ENDIF»        
                }
                «IF n.stepBody !== null»
                    note right of «n.name»
                    step-arguments:
                          «FOR s : n.tests SEPARATOR(", ")»
                              «IF !s.stepArguments.isEmpty»
                                  «s.name.name»:«s.stepArguments.map[p|CSharpHelper.commaAction(p, [c | c], "")].join(", ")»
                              «ENDIF» 
                          «ENDFOR»
                    step-body:
                    «renderStepBody(n.stepBody)»
                    end note
                «ENDIF»
                «IF n.stepBody === null»
                    «FOR s : n.tests»
                        «var idx = scenarios.indexOf(s.name.name)»
                        «var col = colors.get(idx % colors.size)»
                        note right of «n.name» «col»
                        scenario: «s.name.name»
                        step-number: «s.stepNumber»
                        «IF !s.stepArguments.isEmpty»
                        step-arguments:«s.stepArguments.map[p|CSharpHelper.commaAction(p, [c | c], "")].join(", ")»
                        «ENDIF» 
                        «IF s.stepBody !== null»
                        step-body:
                        «renderStepBody(s.stepBody)»
                        «ENDIF»
                        end note
                            «ENDFOR»
                        «ENDIF»
                    «ENDFOR»
                    
            «FOR edge : cg.edges»
                «IF edge instanceof ControlFlowEdge»
                «edge.source.name» --> «edge.target.name»
                «var edgeLabel = getTestIDOnEdge(edge.source, edge.target)»
                «IF !edgeLabel.isEmpty»
                note left on link
                «FOR elm : edgeLabel»
                «elm»
                «ENDFOR»
                end note
                «ENDIF»
                «ENDIF»
                
                «IF edge instanceof DataFlowEdge»
                «edge.source.name» ..> «edge.target.name»
                note left on link
                «FOR ref : edge.dataReferences SEPARATOR("")»
                «ref.scenario.name»: «ref.variables.map[v|v.name].join(", ")»
                «ENDFOR»  
                end note                          
                «ENDIF»
                
            «ENDFOR»
            @enduml
            '''
        fsa.generateFile(cg.name + '.plantuml', cgTxt)
    }

    def getTestIDsFromNode(Node n) {
        var tidList = new HashSet<String>
        for (a : n.getTests()) {
            tidList.add(a.getName().getName())
        }
        return tidList
    }

    def getTestIDOnEdge(Node src, Node dst) {
        val result = new HashSet<String>
        for (stepSrc : src.tests) {
            for (stepDst : dst.tests) {
                if (stepSrc.name.name == stepDst.name.name
                        && stepDst.stepNumber == stepSrc.stepNumber + 1) {
                    result.add(stepDst.name.name)
                }
            }
        }
        return result
    }
    
    def String renderStepBody(StepBody sb) {
        val content = if (sb instanceof LanguageBody) {
                (sb as LanguageBody).body
            } else if (sb instanceof ActionsBody) {
                (sb as ActionsBody).actions.map[a|CSharpHelper.commaAction(a, [s|s], "")].join("")
            } else {
                ""
            }
        return content
    }

}
