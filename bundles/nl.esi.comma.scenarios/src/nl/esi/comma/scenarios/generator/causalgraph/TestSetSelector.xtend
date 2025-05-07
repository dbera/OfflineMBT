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
package nl.esi.comma.scenarios.generator.causalgraph

import java.time.LocalDateTime
import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactReportBuilder
import nl.esi.comma.scenarios.generator.impactanalysis.ReportWriter
import nl.esi.comma.scenarios.scenarios.KEY_ID
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.scenarios.scenarios.SpecFlowScenario
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.Map.Entry
import java.util.stream.Collectors
import java.util.LinkedHashMap

class TestSetSelector {
    var progresionTestSet = new HashMap<String, Set<String>> // String > scnid - product set
    var regresionTestSet = new HashMap<String, Set<String>> // String > scnid - product set
    var impactedTestSet = new HashMap<String, Set<String>> // String > scnid - product set
    var nodeTestSetSelection = new HashMap<String, List<EdgeSelectionSet>> // string > node.actionName
    var nodeDataTestSetSelection = new HashMap<String, List<DataSelectionSet>> // string > node.actionName
    var nodeConfigTestSetSelection = new HashMap<String, List<ConfigurationSelectionSet>> // string > node.actionName
    var scnIDToMetaDataMap = new HashMap<String, SCNMetaData> // scndid - metadata (name,loc)
    var scnIDReason = new HashMap<String, Set<String>>
    var stepToCharMap = new HashMap<String,Character>
    var selectionTestSet = new HashMap<String, Set<String>> // configuration - list of test IDs
    
    // optimization vars
    var sortedRegressionTestSet = new LinkedHashMap<String, Integer> // SCN ID - Number of Reasons
    
    val ALL_CONFIGURATIONS = "ALL CONFIGURATIONS"
    
    // test statistics. computed in the end.
    var numTests = 0  
    var numConfigs = 0 
    var numTestConfigPairs = 0
    var estTime = 0
    var numSelTests = 0 
    var numSelConfigs = 0
    var numSelTestConfigPairs = 0
    var newEstTime = 0
    var avgConfigSwitchTime = 5*60
    var avgTestExecTime = 10
    
    def addReason(Map<String, Set<String>> testIDtoProd, String reason) {
        for(scnId : testIDtoProd.keySet) {
            if(!scnIDReason.containsKey(scnId)) {
                scnIDReason.put(scnId, new HashSet<String>)
                scnIDReason.get(scnId).add(reason)            
            } else {
                scnIDReason.get(scnId).add(reason)
            }
        }
    }
    
    def printReason() {
        for(scnId : scnIDReason.keySet) {
            System.out.println("    SCNID: " + scnId)
            for(elm : scnIDReason.get(scnId))
                System.out.println("    Reason: " + elm)
        }
    } 
    
    def getSCNName(String id) {
        if(scnIDToMetaDataMap.containsKey(id)) return scnIDToMetaDataMap.get(id).name
        else return new String
    }
    
    def getSCNLoc(String id) {
        if(scnIDToMetaDataMap.containsKey(id)) return scnIDToMetaDataMap.get(id).loc
        else return new String        
    }

    def getSCNReason(String id) {
        if(scnIDReason.containsKey(id)) {
            return scnIDReason.get(id).toList
        }
        else return newArrayList
    }
    
    def computeStatistics(Scenarios scns) {
        numTests = scns.specFlowScenarios.size
        var configSet = new HashSet<String>
        var configTestMap = new HashMap<String,Set<String>>
        var isAllConfigsPresent = false
        
        for(scn : scns.specFlowScenarios) {
            for(fa : scn.featureAttributes) { // we are looping again and again. each scenario has the same info! TODO
                if(fa.key.equals(KEY_ID.NUM_CONFIGS)) {
                    numConfigs = Integer.parseInt(fa.value.head)
                }
            }
            for(act : scn.events) {
                for(p : act.product) {
                    for(v : p.value)
                        if(!configSet.contains(v))
                            configSet.add(v)
                }
            }
            if(!configSet.contains(ALL_CONFIGURATIONS)) { isAllConfigsPresent = true numTestConfigPairs += configSet.size }
            else numTestConfigPairs += numConfigs
            
            // to compute est. time of testing
            for(c : configSet) {
                if(configTestMap.containsKey(c)) configTestMap.get(c).add(scn.HID)
                else {
                    var s = new HashSet<String>
                    s.add(scn.HID)
                    configTestMap.put(c,s)                    
                }
            }
        }
        
        //if(numConfigs===0) numConfigs = configSet.size
        for(c : configTestMap.keySet) {
            if(!c.equals(ALL_CONFIGURATIONS)) {
                var tmp1 = avgConfigSwitchTime
                var tmp2 = configTestMap.get(c).size * avgTestExecTime
                estTime = estTime + tmp1 + tmp2
            } else {
                if(!isAllConfigsPresent) {
                    var tmp1 = avgConfigSwitchTime * numConfigs
                    var tmp2 = configTestMap.get(c).size * avgTestExecTime
                    estTime = estTime + tmp1 + tmp2
                } else {
                    var tmp1 = avgConfigSwitchTime * (numConfigs - (configTestMap.keySet.size-1))
                    var tmp2 = configTestMap.get(c).size * avgTestExecTime
                    estTime = estTime + tmp1 + tmp2
                }
            }
            // Following code causes memory leak XTend!!!!
            /*if(!c.equals(ALL_CONFIGURATIONS))
                estTime += (avgConfigSwitchTime + (configTestMap.get(c).size * avgTestExecTime))
            else { 
                if(!isAllConfigsPresent) estTime += (avgConfigSwitchTime * numConfigs) + (configTestMap.get(c).size * avgTestExecTime)
                else estTime += (avgConfigSwitchTime * (numConfigs - (configTestMap.keySet.size-1)) + (configTestMap.get(c).size * avgTestExecTime))
            }*/
        }
        
        var numRTests = regresionTestSet.keySet.size
        var numPTests = progresionTestSet.keySet.size
        numSelTests = numPTests + numRTests
        var selConfigSet = new HashSet<String>
        
        for(vals : regresionTestSet.values) {
            for(v : vals)
                if(!selConfigSet.contains(v))
                    selConfigSet.add(v)
        }
        for(vals : progresionTestSet.values) {
            for(v : vals)
                if(!selConfigSet.contains(v))
                    selConfigSet.add(v)
        }
        
        if(selConfigSet.contains(ALL_CONFIGURATIONS))
            numSelConfigs = numConfigs
        else numSelConfigs = selConfigSet.size
    }
    
    def addToSelectionTestSet(String tid, Set<String> prodSet) {
        //System.out.println("    DEBUG CHECK: " + tid + " - " + getSCNName(tid) + " - "+ prodSet)
        //System.out.println("        > " + selectionTestSet)
        var tset = new HashSet<String>
        tset.add(tid)
        for(prod : prodSet) {
            if(selectionTestSet.containsKey(prod)) {
                // System.out.println("    >> " + prod + " - " + selectionTestSet.get(prod))
                // this.selectionTestSet.get(prod).add(tid) // Note TODO This did not work. All tuples got the tid added!. Figure out why!
                var temp = new HashSet<String> 
                for(elm : selectionTestSet.get(prod)) temp.add(elm)
                temp.add(tid)
                //System.out.println("        <!> " + selectionTestSet)
                selectionTestSet.put(prod,temp)
                //System.out.println("        <!> " + selectionTestSet)
            } else {
                //System.out.println("    !> " + prod + " - " + selectionTestSet.get(prod))
                selectionTestSet.put(prod,tset)
            }
        }
        // handle empty prodset
        if(prodSet.isNullOrEmpty) {
            if(selectionTestSet.containsKey("")) {
                selectionTestSet.get("").add(tid)
            }
            else {
                selectionTestSet.put("",tset)
            }
        }
    }
    
    def selectTestConfigsAndGenerateDashBoard(IFileSystemAccess2 fsa, Scenarios scns, String taskName,
    	String configFP, String assemFP, String prefix, String defaultName
    ) {
        var reportBuilder = new ImpactReportBuilder().withMeta(LocalDateTime.now(), taskName).withConfig(configFP,assemFP,prefix,defaultName)
        var allConfigList = new HashSet<String>
                
        allConfigList.add(ALL_CONFIGURATIONS)
        computeStatistics(scns)
        //for(id : regresionTestSet.keySet) { 
        // Testing DB: use the sorted Map instead 
        // Assumption is that both have same contents. TODO Throw error otherwise, before
        for(id : sortedRegressionTestSet.keySet) {
            //System.out.println("Debug scn: " + id)
            //System.out.println("Debug: " + getSCNLoc(id))
            // check if product set is null. Dont expect to hit the else because scenarios generation adds "ALL Configurations" whne null
            if(regresionTestSet.get(id)!==null) {
                if(regresionTestSet.get(id).contains(ALL_CONFIGURATIONS)) {
                    reportBuilder.addRegressionTest(getSCNName(id), allConfigList.toList, getSCNLoc(id), getSCNReason(id))
                    addToSelectionTestSet(id, allConfigList)
                }
                else { 
                    reportBuilder.addRegressionTest(getSCNName(id), regresionTestSet.get(id).toList, getSCNLoc(id), getSCNReason(id))
                    addToSelectionTestSet(id, regresionTestSet.get(id))
                }
                //reportBuilder.addImpactedTest(getSCNName(id), regresionTestSet.get(id).toList, getSCNLoc(id), getSCNReason(id))
            } else {
                reportBuilder.addRegressionTest(getSCNName(id), new ArrayList, getSCNLoc(id), getSCNReason(id))
                addToSelectionTestSet(id, new HashSet<String>)
                //reportBuilder.addImpactedTest(getSCNName(id), new ArrayList, getSCNLoc(id), getSCNReason(id))
            }
        }

        for(id : impactedTestSet.keySet) {  
            //System.out.println("Debug scn: " + id)
            //System.out.println("Debug: " + getSCNName(id))
            //System.out.println("Debug: " + getSCNLoc(id))   
            //System.out.println("Progression Tests: " + progresionTestSet)        
            if(impactedTestSet.get(id)!==null) {
                if(impactedTestSet.get(id).contains(ALL_CONFIGURATIONS)) {
                    reportBuilder.addImpactedTest(getSCNName(id), allConfigList.toList, getSCNLoc(id), getSCNReason(id))
                    //addToSelectionTestSet(id, allConfigList)
                }
                else {
                    reportBuilder.addImpactedTest(getSCNName(id), impactedTestSet.get(id).toList, getSCNLoc(id), getSCNReason(id))
                    //addToSelectionTestSet(id, impactedTestSet.get(id))
                }
            }
            else {
                reportBuilder.addImpactedTest(getSCNName(id), new ArrayList, getSCNLoc(id), getSCNReason(id))
                //addToSelectionTestSet(id, new HashSet<String>)    
            }
        }

        for(id : progresionTestSet.keySet) {  
            //System.out.println("Debug scn: " + id)
            //System.out.println("Debug: " + getSCNName(id))
            //System.out.println("Debug: " + getSCNLoc(id))   
            //System.out.println("Progression Tests: " + progresionTestSet)        
            if(progresionTestSet.get(id)!==null) {
                if(progresionTestSet.get(id).contains(ALL_CONFIGURATIONS)) {
                    reportBuilder.addProgressionTest(getSCNName(id), allConfigList.toList, getSCNLoc(id), getSCNReason(id))
                    addToSelectionTestSet(id, allConfigList)  
                }
                else {
                    reportBuilder.addProgressionTest(getSCNName(id), progresionTestSet.get(id).toList, getSCNLoc(id), getSCNReason(id))
                     addToSelectionTestSet(id, progresionTestSet.get(id))      
                }
            }
            else {
                reportBuilder.addProgressionTest(getSCNName(id), new ArrayList, getSCNLoc(id), getSCNReason(id))
                addToSelectionTestSet(id, new HashSet<String>)
            }
        }
        
        reportBuilder.addNumDefinedTestsAndConfigs(numTests, numConfigs, numTestConfigPairs, estTime.toString + " seconds")//TODO
        //if()
        for(config : selectionTestSet.keySet) {
            if(config.equals(ALL_CONFIGURATIONS)) {
                numSelTestConfigPairs += (numConfigs * selectionTestSet.get(config).size)
                //newEstTime += (avgConfigSwitchTime * numConfigs) + (selectionTestSet.get(config).size * avgTestExecTime)
                //println(" DBUG AL CONFIG: " + numConfigs + " - " + (numConfigs * selectionTestSet.get(config).size))
            }
            else {
                numSelTestConfigPairs += selectionTestSet.get(config).size
                //newEstTime += avgConfigSwitchTime + (selectionTestSet.get(config).size * avgTestExecTime)
                //println(" DBUG INDV CONFIG: " + selectionTestSet.get(config).size)
            }
        }
        reportBuilder.addNumSelectedTestsAndConfig(numSelTests,numSelConfigs, numSelTestConfigPairs, newEstTime + " seconds")//TODO
    
        for(config : selectionTestSet.keySet) {
            if(selectionTestSet.get(config) !== null) {
                var testset = selectionTestSet.get(config)
                var testNameLst = new HashSet<String>
                var isRegr = false
                var isProgr = false
                for(id : testset) {
                    if(progresionTestSet.containsKey(id)) isProgr = true
                    if(regresionTestSet.containsKey(id)) isRegr = true
                    testNameLst.add(getSCNName(id))
                }
                if(isRegr && isProgr)
                    reportBuilder.addSelectionTest(config, testNameLst.toList, "REGRESSION AND PROGRESSION")
                else if(isRegr)
                    reportBuilder.addSelectionTest(config, testNameLst.toList, "REGRESSION")
                else if(isProgr)
                    reportBuilder.addSelectionTest(config, testNameLst.toList, "PROGRESSION")
                else {}
            }
        }
                
        (new ReportWriter(fsa, "..\\test-gen\\" + taskName + "_dashboard.html")).write(reportBuilder.build())
        printSelectedTestSet
    }
    
    def printMetaInfo() {
        System.out.println(" ************** Meta Info ***************** ")
        for(k : scnIDToMetaDataMap.keySet) {
            System.out.println(" HID : " + k)
            System.out.println(" NAME : " + scnIDToMetaDataMap.get(k).name)
            System.out.println(" LOC : " + scnIDToMetaDataMap.get(k).loc)
        }
        System.out.println(" ************** ***************** ***************** ")
    }
    
    def areEdgesAddedAndRemoved(List<EdgeSelectionSet> nssList) {
        var found = false
        for(nss : nssList) {
            if(nss.ECT.equals(EdgeChangeType.edge_added)) found = true
            if(nss.ECT.equals(EdgeChangeType.edge_removed)) found = true
        }
        return found
    }

    def areEdgesUpdated(List<EdgeSelectionSet> nssList) {
        var found = false
        for(nss : nssList) {
            if(nss.ECT.equals(EdgeChangeType.edge_updated)) found = true
        }
        return found
    }
    
    def areEdgesTestSetAddedRemoved(List<EdgeSelectionSet> nssList) {
        var foundA = false
        var foundR = false
        for(nss : nssList) {
            //if(nss.ECT.equals(EdgeChangeType.edge_updated)) 
                if(nss.causalSCNToChangesMap.values!==null) {
                    for(elm : nss.causalSCNToChangesMap.values) {
                        if(elm.contains(EdgeChangeType.testset_added)) foundA = true 
                        if(elm.contains(EdgeChangeType.testset_removed)) foundR = true
                    }
                }
        }
        if(foundA&&foundR) return true
        else return false 
    }
    
    def addToImpactedTestSet(Map<String, Set<String>> testIDtoProd) {
        for(id : testIDtoProd.keySet) {
            if(!impactedTestSet.containsKey(id)) {
                impactedTestSet.put(id, testIDtoProd.get(id))   
            }
        }
    }
    
    def addToRegressionTestSet(Map<String, Set<String>> testIDtoProd) {
        for(id : testIDtoProd.keySet) {
            if(!regresionTestSet.containsKey(id)) {
                if(!progresionTestSet.containsKey(id)) // this is relevant for data extensions.
                    regresionTestSet.put(id, testIDtoProd.get(id))
            }
        }
    }
    
    def getScenario(String id, Scenarios scns) {
        for(scn : scns.specFlowScenarios) {
            if(scn.HID.equals(id)) return scn
        }
        return null
    }
    
    def getSymbolicScenario(SpecFlowScenario scn, Map<String,Character> stepToCharMap) {
        var str = new String
        for(evt : scn.events) str += stepToCharMap.get(evt.name) // assumption all steps are mapped. TODO check it? What to do if not mapped?
        return str
    }
    
    def computeStepsToSymbolMap(Scenarios scns) {
        var char symb = '!'
        for(scn : scns.specFlowScenarios) {
            for(evt : scn.events) {
                if(!stepToCharMap.containsKey(evt.name)) {
                    stepToCharMap.put(evt.name,symb)
                    symb++    
                }
            }            
        }
        //println("test: "  + stepToCharMap)
    }
    
    // Given a set of scenarios - find the minimal distinct set (eliminate duplicates)
    // add to minset only if 1. not there already, 2. is distinct enough
    // pre: stepToCharMap must be computed already
    def computeMinimalSet(Map<String, Set<String>> testprodset, Scenarios scns, double sensitivity) {
        var MAX_THRESHOLD_VAL = 100000
        var testset = testprodset.keySet
        var Map<String, Set<String>> final_testprodset = new HashMap<String, Set<String>>
        var Map<String, String> mapIDtoSymbolicSCN = new HashMap<String,String>

        if(testset.size <= 1) return testprodset

        var refId = testset.get(0) // base reference test set ID
        final_testprodset.put(refId,testprodset.get(refId))
        var refScn = getScenario(refId, scns) // ref specflow scenario
        var refSymbScn = getSymbolicScenario(refScn, stepToCharMap) // ref synbolic scenario
        mapIDtoSymbolicSCN.put(refId,refSymbScn)
        
        for(tid : testset) {
            //println("   checking if tid must be inserted")
            if(!tid.equals(refId)) {
                //println("       getting symbolic scn")
                var symbScn = getSymbolicScenario(getScenario(tid,scns), stepToCharMap)
                var thresh = Math.ceil(symbScn.length * (sensitivity/100.0)).intValue
                // compute distance between symbScn and all entry in mapIDtoSymbolicSCN
                println("   SymbSCN: " + symbScn + " tid: " + tid + " sens: " + sensitivity)
                println("   map " + mapIDtoSymbolicSCN)
                var minDist = MAX_THRESHOLD_VAL // TODO find a better upper bound! e.g. based on length of str
                for(sid : mapIDtoSymbolicSCN.keySet) {
                    var currDist = StringEditDistance.distance(mapIDtoSymbolicSCN.get(sid), symbScn)
                    if(currDist < minDist) minDist = currDist
                }
                println("   minDist: " + minDist + " threshold: " + thresh)
                if(minDist >= thresh) {
                    final_testprodset.put(tid,testprodset.get(tid))
                    mapIDtoSymbolicSCN.put(tid,symbScn)
                } else {
                    if(!final_testprodset.containsValue(testprodset.get(tid))) {
                        final_testprodset.put(tid,testprodset.get(tid))
                        mapIDtoSymbolicSCN.put(tid,symbScn)
                    }
                }
            }
        }
        return final_testprodset
    }
    
    def computeRegressionTestSet(Scenarios scns, double sensitivity, boolean ignoreOverlap, boolean ignoreStepContext) {
        for(node : nodeTestSetSelection.keySet) {
            // if nss contains edge_update then check if edges were added or removed
            if(areEdgesUpdated(nodeTestSetSelection.get(node))) {
                if(areEdgesAddedAndRemoved(nodeTestSetSelection.get(node))) {
                    // update + added and removed // aggressive primary + conservative secondary
                    for(nss : nodeTestSetSelection.get(node)) {
                        var p = nss.primaryAnd // NOTE selects everything on edge. We want only uniquely distinct scenarios. TODO
                        //println("computing minimal set")
                        var minp = computeMinimalSet(p,scns, sensitivity)
                        //println("computed minimal set")
                        var s = nss.secondary
                        //addToRegressionTestSet(p)
                        addToRegressionTestSet(minp)
                        addToRegressionTestSet(s)
                        addReason(minp, "Pri[CU+CA|CR]:" + node) //compound primary causal update of
                        addReason(s, "Sec[CU+CA|CR]:" + node) // compound secondary causal update of 
                    }
                } else {
                    // update only // conservative primary  
                    // To prevent test addition because edge was updated by addition of other test scenarios
                    // indicated by user
                    if(!ignoreOverlap) {
                        for(nss : nodeTestSetSelection.get(node)) {
                            var p = nss.primary
                            var s = nss.secondary
                            // edge context update leads to primary set being null. see below.
                            if(p!==null) {
                                var minp = computeMinimalSet(p,scns, sensitivity)
                                addToRegressionTestSet(minp)
                                // addToRegressionTestSet(p) // This was the old case. 06.05.2022 DB TODO test stability
                                addReason(p, "Pri[CU]:" + node) //simple causal update of
                            }
                            // + conservative secondary -> if testset added and removed?
                            if(areEdgesTestSetAddedRemoved(nodeTestSetSelection.get(node))) {
                                addToRegressionTestSet(s)
                                addReason(s, "Sec[CU]:" + node) // secondary simple causal update of 
                            }
                        }
                    }
                    if(!ignoreStepContext) {
                        for(nss : nodeTestSetSelection.get(node)) {
                            // edge context update leads to primary set being null. see below.
                            var s = nss.secondary
                            addToRegressionTestSet(s)
                            addReason(s, "Context[CU]:" + node)
                        }
                    }
                }
            } else {
                // edges were added or removed // aggressive primary + conservative secondary
                for(nss : nodeTestSetSelection.get(node)) {
                   //var p = nss.primaryAnd // this is null?
                   var p = nss.primary // does this fix null?
                   var s = nss.secondary
                   addToRegressionTestSet(p)
                   addToRegressionTestSet(s)
                   addReason(p, "Pri[CA|CR]:" + node) //causal addition or removal of 
                   addReason(s, "Sec[CA|CR]:" + node) //secondary causal addition or removal of
                }
            }
        }
        printRegressionTestSet
        sortRegressionTestSet
    }
 
    def sortRegressionTestSet() {
        /* New Feature Testing */
        // Sort Regression test set by severity
        //println(" *********  DEBUG ****************")
        var unsortedRegressionTestSet = new LinkedHashMap<String, Integer> 
        for(k : regresionTestSet.keySet) {
            var rsize = 0
            //println("SCN ID: " + k)
            if(scnIDReason.containsKey(k)) {
                rsize = scnIDReason.get(k).size
                //println("   + Reason Set Size: " + rsize)
                //println(scnIDReason.get(k))
            } else { /* should not be here! Throw Error! */}
            unsortedRegressionTestSet.put(k, rsize)
        }
        sortedRegressionTestSet = MapSort.sortByComparator(unsortedRegressionTestSet, false)
        //println("Sorted Regression IDs")
        //for(elm : sortedRegressionTestSet.entrySet) println("   > " + elm.key + " - " + elm.value)
        if(sortedRegressionTestSet.keySet.size !== regresionTestSet.keySet.size) 
            throw new Exception("[0x001] UnEqual Test Set: sortRegressionTestSet()");
        //println(" *********  DEBUG ****************")
        /* New feature Testing */
    }
 
 
 
    
    def computeImpactedTestSet() {
        for(node : nodeDataTestSetSelection.keySet) {
            for(dss : nodeDataTestSetSelection.get(node)) {
                addToImpactedTestSet(dss.primary)
            }
        }
        printImpactedTestSet
    }
    
    def printSelectedTestSet() {
        System.out.println(" ************** SELECTION TEST SET ***************** ")
        for(k : selectionTestSet.keySet) {
            println("   CONFIG: " + k + "  TEST-ID: " + selectionTestSet.get(k))
        }
        System.out.println(" ***************************************************** ")
    }
    
    def printProgressionTestSet() {
        System.out.println(" ************** PROGRESSION TEST SET ***************** ")
        for(k : progresionTestSet.keySet) {
            println("   TEST ID: " + k + "  Products: " + progresionTestSet.get(k))
        }
        System.out.println(" ************** ***************** ***************** ")
    }
    
    def printRegressionTestSet() {
        System.out.println(" ************** REGRESSION TEST SET ***************** ")
        for(k : regresionTestSet.keySet) {
            println("   TEST ID: " + k + "  Products: " + regresionTestSet.get(k))
        }
        System.out.println(" ************** ***************** ***************** ")
    }
    
    def printImpactedTestSet() {
        System.out.println(" ************** IMPACTED TEST SET ***************** ")
        for(k : impactedTestSet.keySet) {
            println("   TEST ID: " + k + "  Products: " + impactedTestSet.get(k))
        }
        System.out.println(" ************** ***************** ***************** ")
    }
    
    def printNodeTestSetSelection() {
        System.out.println(" ************** TEST SET SELECTION ***************** ")
        for(n : nodeTestSetSelection.keySet) {
            System.out.println("Node Name: " + n)
            for(nss : nodeTestSetSelection.get(n)) {
                System.out.println("    Edge Change Type: " + nss.ECT)
                System.out.println("    Primary: " + nss.primary)
                System.out.println("    PrimaryAND: " + nss.primaryAnd)
                System.out.println("    Secondary: " + nss.secondary)
                for(k : nss.causalSCNToChangesMap.keySet) {
                    System.out.println("    Causal SCNID: " + k)
                    System.out.println("    ChangeTypes: " + nss.causalSCNToChangesMap.get(k))
                }                    
            }
        }
        System.out.println(" ************** ***************** ***************** ")
    }
    
     def computeBaselineStats(Scenarios scnList) {
         var numSCN = scnList.specFlowScenarios.size
         System.out.println("   TOTAL NUMBER OF SCENARIOS: " + numSCN)
     }
    
    def computeIDToMetaInfo(Scenarios scnList) {
        for(scn : scnList.specFlowScenarios) {
            var meta = new SCNMetaData
            for(attr : scn.scenarioAttributes) {
                if(attr.key.equals(KEY_ID.SCN_NAME)) {
                    meta.name = attr.value.head // there is only one file location
                }
            }
            for(attr : scn.featureAttributes) {
                if(attr.key.equals(KEY_ID.LOCATION)) {
                    meta.loc = attr.value.head // there is only one file location
                }
            }
            scnIDToMetaDataMap.put(scn.HID, meta)
        }
    }
    
    def computeProgressionTests(CausalGraph source, CausalGraph target) {
        var srcTests = new HashMap<String, Set<String>>
        var dstTests = new HashMap<String, Set<String>>
        for(n : source.nodes) {
            var tmp = n.mapIDtoProductSet // iterate over scnid of node
            for(k : tmp.keySet) 
                if(!srcTests.containsKey(k)) 
                    srcTests.put(k, tmp.get(k))
        }
        for(n : target.nodes) {
            var tmp = n.mapIDtoProductSet
            for(k : tmp.keySet) 
                if(!dstTests.containsKey(k)) 
                    dstTests.put(k, tmp.get(k))
        }        
        // make the selection
        for(s : dstTests.keySet) {
            if(!srcTests.containsKey(s)) {
                progresionTestSet.put(s, dstTests.get(s))
                //System.out.println(" Debug: " + srcTests + " \n dst: " + dstTests + "\n" + "id: " + s)
            }
        }
        System.out.println("Progression Tests: " + progresionTestSet)
    }

    // called by edge updates
    def addToProgressionSet(Node n, Edge e) {
        var tstProdSet = new HashMap<String, Set<String>>
        var testSet = e.scnIDs
        for(id : testSet) {
            if(n.mapIDtoProductSet.get(id)===null) tstProdSet.put(id, new HashSet<String>)
            else tstProdSet.put(id, n.mapIDtoProductSet.get(id))
        }
        //System.out.println("DEBUG: " + n.mapIDtoProductSet)
        //System.out.println("DEBUG: " + tstProdSet)
        for(k : tstProdSet.keySet) {
            if(!progresionTestSet.containsKey(k)) {
                progresionTestSet.put(k, tstProdSet.get(k))
            }
        }
        //printProgressionTestSet
    }
    
    // called by edge updates & data update (if not an iteration change)    
    def addToProgressionSet(Node n, String SCNId) {
        if(!progresionTestSet.containsKey(SCNId)) {
            if(n.mapIDtoProductSet.get(SCNId)!==null)
                progresionTestSet.put(SCNId, n.mapIDtoProductSet.get(SCNId))
            else progresionTestSet.put(SCNId, new HashSet<String>)
        }
    }

    // edge creation
    def computeImpactOfEdgeAddition(Node n, Edge e) {
        // add SCNID to progression testset
        addToProgressionSet(n,e)
        var primarySet = n.selectAllSCNID(e)
        /*System.out.println("    Debug: Addition")
        System.out.println("        Debug: " + n.actionName + " - " + e.src + " - " + e.dst )
         for(id : e.scnIDs) {
             System.out.println("       Debug: " + id)
        } */  
        var secondarySet = n.selectMinOtherSCNID(e, "") // can result in test id along e to be selected along another edge
        var nss = new EdgeSelectionSet(EdgeChangeType.edge_added, primarySet, secondarySet)
        //nss.addCausalSCN(SCNID, EdgeChangeType.edge_added)
        if(!nodeTestSetSelection.containsKey(n.actionName)) {
            var lst = new ArrayList<EdgeSelectionSet>
            lst.add(nss)
            nodeTestSetSelection.put(n.actionName, lst)
        } else { nodeTestSetSelection.get(n.actionName).add(nss) }
        //System.out.println("Debug: Addition")
    }
    
    // scnid and edge are not present in node n
    // edge deletion
    def computeImpactOfEdgeRemoval(Node n, Edge e) {
        //System.out.println("Debug: Removal")
        var secondarySet = n.selectMinOtherSCNID(e, "") // test id is removed
        var nss = new EdgeSelectionSet(EdgeChangeType.edge_removed, secondarySet)
        // nss.addCausalSCN(SCNID, EdgeChangeType.edge_removed)
        if(!nodeTestSetSelection.containsKey(n.actionName)) {
            var lst = new ArrayList<EdgeSelectionSet>
            lst.add(nss)
            nodeTestSetSelection.put(n.actionName, lst)
        } else { nodeTestSetSelection.get(n.actionName).add(nss) }
    }

    // edge deletion
    def computeImpactOfEdgeContextChange(Node n, Edge e) {
        //System.out.println("Debug: Context Change")
        var secondarySet = n.selectMinOtherSCNID(e, "") 
        var nss = new EdgeSelectionSet(EdgeChangeType.edge_updated, secondarySet)
        if(!nodeTestSetSelection.containsKey(n.actionName)) {
            var lst = new ArrayList<EdgeSelectionSet>
            lst.add(nss)
            nodeTestSetSelection.put(n.actionName, lst)
        } else { nodeTestSetSelection.get(n.actionName).add(nss) }
    }

    // edge update
    def computeImpactOfEdgeUpdate(Node n, Edge e, String SCNID, EdgeChangeType ect) { // can come here with e not having scnID: testset removed
        var primarySet = n.selectMinSCNID(e,SCNID) 
        var primaryAndSet = n.selectAllSCNID(e) // only if node has other edge additions or removal, else minSet. how to figure this?
        //if(!ect.equals(EdgeChangeType.testset_removed)) System.out.println("Debug: Update - R")
        //else System.out.println("Debug: Update - A")
        var secondarySet = n.selectMinOtherSCNID(e, SCNID) // only if node has other edge additions or removal - else empty set.
        
        var nss = new EdgeSelectionSet(EdgeChangeType.edge_updated, primarySet, primaryAndSet, secondarySet)
        nss.addCausalSCN(SCNID, ect) // in post-processing this info will also be used to decide - and-or set
        // scnid will be added to progression test set during post processing
        if(!ect.equals(EdgeChangeType.testset_removed))
            addToProgressionSet(n,SCNID) // to prevent removed scnID from being added
            
        if(!nodeTestSetSelection.containsKey(n.actionName)) {
            var lst = new ArrayList<EdgeSelectionSet>
            lst.add(nss)
            nodeTestSetSelection.put(n.actionName, lst)
        } else { nodeTestSetSelection.get(n.actionName).add(nss) }
    }
    
    // data impact
    // data update
    // assumption: SCNID is present in n (this is checked before calling)
    def computeImpactOfDataUpdate(Node n, String SCNID, NodeChangeType nct, Map<NodeChangeType, List<String>> detailedChangeSet) {
        var primarySet = n.selectAllSCNIDandConfigOfNode 
        var dss = new DataSelectionSet(nct, primarySet)
        var Map<String, Set<String>> emptyTestIDtoProd = new HashMap<String, Set<String>>
        // iteration update does not show up in regression or impacted testsets
        if(detailedChangeSet.keySet.contains(NodeChangeType.index_added) ||
           detailedChangeSet.keySet.contains(NodeChangeType.index_removed)) {
           // only report - probably already part of progression test set. 
           // Add it. Do not use primary set 
           addToProgressionSet(n,SCNID) // TODO how to handle when data is added but not in table! Pollutes progression test set.
           emptyTestIDtoProd.put(SCNID, n.getProductSet(SCNID))
           addReason(emptyTestIDtoProd, "Data.Iter[A|R]:" + n.actionName)
        } else {
            for(id : primarySet.keySet) emptyTestIDtoProd.put(id, n.getProductSet(id))
            addReason(emptyTestIDtoProd, "Data.Iter[U]:" + n.actionName)
            
            if(!nodeDataTestSetSelection.containsKey(n.actionName)) {
                var lst = new ArrayList<DataSelectionSet>
                lst.add(dss)
                nodeDataTestSetSelection.put(n.actionName, lst)
            } else nodeDataTestSetSelection.get(n.actionName).add(dss)
            //emptyTestIDtoProd.put(SCNID, n.getProductSet(SCNID))
            //addReason(emptyTestIDtoProd, "Iteration updated")
        }
    }
    
    // data addition
    def computeImpactOfDataAddition(Node n, String SCNID, NodeChangeType nct) {
        var primarySet = n.selectAllSCNIDandConfigOfNode
        var dss = new DataSelectionSet(nct, primarySet)
        var Map<String, Set<String>> emptyTestIDtoProd = new HashMap<String, Set<String>>
        
        for(id : primarySet.keySet) emptyTestIDtoProd.put(id, n.getProductSet(id))
        addReason(emptyTestIDtoProd, "Data[A]:" + n.actionName)
        
        if(!nodeDataTestSetSelection.containsKey(n.actionName)) {
            var lst = new ArrayList<DataSelectionSet>
            lst.add(dss)
            nodeDataTestSetSelection.put(n.actionName, lst)
        } else nodeDataTestSetSelection.get(n.actionName).add(dss)
    }
    
    // data removal
    def computeImpactOfDataRemoval(Node n, NodeChangeType nct) {
        var primarySet = n.selectAllSCNIDandConfigOfNode
        var dss = new DataSelectionSet(nct, primarySet)
        var Map<String, Set<String>> emptyTestIDtoProd = new HashMap<String, Set<String>>

        for(id : primarySet.keySet) emptyTestIDtoProd.put(id, n.getProductSet(id))
        addReason(emptyTestIDtoProd, "Data[R]:" + n.actionName)

        if(!nodeDataTestSetSelection.containsKey(n.actionName)) {
            var lst = new ArrayList<DataSelectionSet>
            lst.add(dss)
            nodeDataTestSetSelection.put(n.actionName, lst)
        } else nodeDataTestSetSelection.get(n.actionName).add(dss)
    }
}

// changes due to productset updates per case (product added/removed)
class ConfigurationSelectionSet {
    var NodeChangeType nct
    // scnid - productset
    var Map<String, Set<String>> primaryTestset
    var Map<String, Set<NodeChangeType>> causalSCNToChangesMap
    
    new(){
        primaryTestset = new HashMap<String, Set<String>>
        causalSCNToChangesMap = new HashMap<String, Set<NodeChangeType>>
    }
}

// changes due to data updates per case (data added\updated\removed)
class DataSelectionSet {
    var NodeChangeType nct // data added/removed/updated
    // scnid - productset
    var Map<String, Set<String>> primaryTestset
    var Map<String, Set<NodeChangeType>> causalSCNToChangesMap
    
    new(NodeChangeType _nct, Map<String, Set<String>> p){
        nct = _nct
        primaryTestset = p
        causalSCNToChangesMap = new HashMap<String, Set<NodeChangeType>>
    }

    def getCausalSCNToChangesMap() { return causalSCNToChangesMap }
    def getPrimary() { return primaryTestset }
    def addCausalSCN(String scnID, NodeChangeType nct) {
        if(!causalSCNToChangesMap.containsKey(scnID))
            causalSCNToChangesMap.put(scnID, new HashSet<NodeChangeType>)
        causalSCNToChangesMap.get(scnID).add(nct)
    }
}

// changes due to edge updates per case (edge added\updated\removed)
class EdgeSelectionSet {
    var EdgeChangeType ect
    // scnid - productset
    var Map<String, Set<String>> primaryTestset
    var Map<String, Set<String>> primaryAndTestset 
    var Map<String, Set<String>> secondaryTestset
    // causal scnID - minor edge change types (testset added, removed)
    var Map<String, Set<EdgeChangeType>> causalSCNToChangesMap
    
    new(EdgeChangeType e, Map<String, Set<String>> p, Map<String, Set<String>> s) {
        ect = e
        primaryTestset = p
        secondaryTestset = s
        primaryAndTestset = new HashMap<String, Set<String>>
        causalSCNToChangesMap = new HashMap<String, Set<EdgeChangeType>>
    } 
    
    new(EdgeChangeType e, Map<String, Set<String>> s) {
        ect = e
        primaryTestset = new HashMap<String, Set<String>> //null
        secondaryTestset = s
        primaryAndTestset = new HashMap<String, Set<String>>
        causalSCNToChangesMap = new HashMap<String, Set<EdgeChangeType>>
    }

    new(EdgeChangeType e, Map<String, Set<String>> p, Map<String, Set<String>> ps, Map<String, Set<String>> s) {
        ect = e
        primaryTestset = p
        primaryAndTestset = ps
        secondaryTestset = s
        causalSCNToChangesMap = new HashMap<String, Set<EdgeChangeType>>
    }  
 
    
    def getECT() { return ect}
    def getPrimary() { return primaryTestset }
    def getPrimaryAnd() { return primaryAndTestset }
    def getSecondary() { return secondaryTestset }
    def getCausalSCNToChangesMap() { return causalSCNToChangesMap }
    
    def addCausalSCN(String scnID, EdgeChangeType ect) {
        if(!causalSCNToChangesMap.containsKey(scnID))
            causalSCNToChangesMap.put(scnID, new HashSet<EdgeChangeType>)
        causalSCNToChangesMap.get(scnID).add(ect)
    }
}


class SCNMetaData {
    var String name
    var String fileLocation
    
    def setName(String str) { name = str }
    def setLoc(String str) { fileLocation = str }
    def getName() { name }
    def getLoc() { fileLocation }
}
// Format for dashboard
// String scnID, List<String> configs, String filePath, String reason)
