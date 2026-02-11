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
package nl.esi.comma.scenarios.generator.specflow

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.scenarios.generator.plantuml.ScenarioUMLGenerator
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess

class ScenarioToSpecFlowGenerator extends ScenarioUMLGenerator {
//    val String _path = "..\\test-gen\\ScenariosToSpecFlowTest\\feature"

    var coMap = new HashMap<String, ArrayList<TCTagAction>>
    var siMap = new HashMap<String, ArrayList<String>>
    var niMap = new HashMap<String, ArrayList<TCTagAction>>
    var varMap = new HashMap<String, Expression>
    var headerMap = new HashMap<String, ArrayList<String>>
    var eventName = ""

    new(String fileName, IFileSystemAccess fsa) {
        super(fileName, fsa)
    }

    def doGenerate(List<Scenarios> scenariosList, String path, IFileSystemAccess fsa,
        HashMap<String, ArrayList<TCTagAction>> coMap, HashMap<String, ArrayList<String>> siMap,
        HashMap<String, ArrayList<TCTagAction>> niMap, HashMap<String, Expression> varMap,
        HashMap<String, ArrayList<String>> headerMap) throws IllegalArgumentException {

        this.coMap = coMap
        this.siMap = siMap
        this.niMap = niMap
        this.varMap = varMap
        this.headerMap = headerMap

        for (scenarios : scenariosList) {
            // no-op for now
        }
    // fsa.generateFile(_path + "generatedScenarios.feature", featureText)
    }

    def ScenarioToSpecFlow(Scenario scn){
        // no-op for now
    }

    def getGherkinTextNotif(String eventName) {
        if (!niMap.get(eventName).equals(null))
            for (txt : niMap.get(eventName)) {
                if (txt.data.equals(null)) {
                    // notification without data result
                    return txt.data
                }
            }
        else
            return eventName
        return ""
    }

    def getGherkinTextNotifResult(String eventName, String[] result) {
        if (!eventName.equals("")) {
            if ( !niMap.get(eventName).equals(null) ) {
                for (txt : niMap.get(eventName)) {
                    if (!txt.data.equals(null)) {
                        if (dataMatch(result, txt.data)){
                            return txt.tagText
                        }
                    }
                }
                return niMap.get(eventName).get(0).tagText
            } else {
                return eventName
            }
        }
        return ""
    }

    def getGherkinTextSig(String eventName, String[] args) {
        var txt = ""
        var arguments = ""
        if (!siMap.get(eventName).equals(null)) {
            txt = siMap.get(eventName).get(0)
            if (args.size > 0 && args.size.equals(headerMap.get(eventName).size)){
                arguments = getArgumentStr(eventName, args)
                return txt + "\n" + arguments
            } else {
                return txt
            }
        } else {
            return eventName
        }
    }

    def getGherkinTextComd(String eventName, String[] args) {
        var arguments = ""
        if (!coMap.get(eventName).equals(null))
            for (txt : coMap.get(eventName)) {
                if (args.size > 0 && args.size.equals(headerMap.get(eventName).size)) {
                    arguments = getArgumentStr(eventName, args)
                    return txt.tagText + "\n" + arguments
                } else {
                    return txt.tagText
                }
            }
        else 
            return eventName
        return coMap.get(eventName).get(0).tagText
    }

    def getGherkinTextComdResult(String[] result) {
        if (!eventName.equals("")) {
            if ( !coMap.get(eventName).equals(null) ) {
                for (txt : coMap.get(eventName)) {
                    if (!txt.data.equals(null)){
                        if (dataMatch(result, txt.data)){
                            return txt.tagText
                        }
                    }
                }
                if (coMap.get(eventName).filter[e|!e.comd].size > 0) {
                    return coMap.get(eventName).filter[e|!e.comd].get(0).tagText
                } else {
                    return coMap.get(eventName).get(0).tagText
                }
                
            }
            return eventName
        }
        return "No Matched Tag!"
    }
    
    def dataMatch(String[] result, Expression[] data) {
        var dataToStr = ""
        var dataStrList = new ArrayList<String>()
        var counter = 0
        var match = true
        var i = 0
        while (match && i < data.size) {
            var exp = data.get(i)
            if (exp instanceof ExpressionVariable) {
                exp = varMap.get(exp.variable.name)
            }
            if (exp instanceof ExpressionRecord) {
                dataStrList = EventOutputToString.OuputDataToStringList(exp)
                for (j : 0 ..< dataStrList.size) {
                    if (i < result.size) {
                        if (!result.get(counter).equals(dataStrList.get(j))) {
                            match = false
                        }
                        counter++
                    }
                }
            } else {
                dataToStr = EventOutputToString.OuputDataToString(exp)
                if (counter < result.size) {
                    if (!result.get(counter).equals(dataToStr)) {
                        match = false
                    }
                    counter++
                }
            }
            i++
        }
        return match
    }
    
    def getArgumentStr(String eventName, String[] args){
        var arguments = ""
        if (args.size > 0){
            val int[] headerL = newIntArrayOfSize(headerMap.get(eventName).size)
            for (i : 0 ..< headerMap.get(eventName).size) {
                var argL = args.get(i).getValue.length
                if (argL > headerMap.get(eventName).get(i).length) {
                    headerL.set(i, argL)
                } else {
                    headerL.set(i, headerMap.get(eventName).get(i).length)
                }
                arguments += fixedLengthString(headerL.get(i), headerMap.get(eventName).get(i))
            }
            arguments += "  |\n"
            for (i : 0 ..< args.size) {
                arguments += fixedLengthString(headerL.get(i), args.get(i).getValue)
            }
            arguments += "  |\n"
            return arguments
        }
        return ""
    }
    
    def getValue(String arg){
        var value = arg.substring(7, arg.indexOf("]"))
        return value
    }
    
    def fixedLengthString(int headerL, String arg){
        return "  |  " + String.format("%1$"+headerL+"s", arg)
    }
    
    enum context{
        when,
        then,
        none
    }
}
