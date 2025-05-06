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
package nl.esi.comma.constraints.generator

import java.util.List
import java.util.ArrayList

class TestMinimizer 
{
    var listOfSimilariyScores = new ArrayList<SimilariyScore>
    
    def getListOfSimilarityScores() { return listOfSimilariyScores }
    
    def computeMinimalTests(List<String> existing, List<String> newly, Integer similarity) 
    {
        //System.out.println(" EXISTING: " + existing)
        //System.out.println(" New: " + newly)
        var finalTests = new ArrayList<String>
        var eidx = 0
        var nidx = 0
        for(et : existing) {
            for(nt : newly) {
                var jIndex = (new StringEditDistance).distance(et, nt, 1)
                if(jIndex < 1.0 - Double.valueOf(similarity)/100.0) {
                    //System.out.println(" ET: " + et + " NT: " + nt)
                    //System.out.println("    EIDX: " + eidx + " NIDX: " + nidx + " jIndex: " + jIndex)
                    var dist = StringEditDistance.LVdistance(et, nt)
                    var threshold = Math.max(et.length, nt.length)
                    //System.out.println("    TRESH: " + threshold  + " NORM DIST: " + Double.valueOf(dist)/threshold)
                    listOfSimilariyScores.add(new SimilariyScore(eidx, nidx, jIndex, Double.valueOf(dist)/threshold))
                }
                nidx++
            }
            nidx = 0
            eidx++
        }
        return newly
    }
}

class SimilariyScore 
{
    var existingTestId = 0
    var newTestId = 0
    var jaccardIndex = 0.0
    var normalizedEditDistance = 0.0
    
    new(int eid, int nid, double jindex, double ned) {
        existingTestId = eid
        newTestId = nid
        jaccardIndex = jindex
        normalizedEditDistance = ned
    }
    
    def getEID() { return existingTestId }
    def getNID() { return newTestId }
    def getJIndex() { return jaccardIndex }
    def getNED() { return normalizedEditDistance }
}