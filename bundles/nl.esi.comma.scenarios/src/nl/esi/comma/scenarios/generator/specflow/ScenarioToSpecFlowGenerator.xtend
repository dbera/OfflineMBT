/*
 * (C) Copyright 2018 TNO-ESI.
 */

package nl.esi.comma.scenarios.generator.specflow

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.NotificationEvent
import nl.esi.comma.actions.actions.SignalEvent
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.scenarios.generator.plantuml.ScenarioUMLGenerator
import nl.esi.comma.scenarios.scenarios.InfoArg
import nl.esi.comma.scenarios.scenarios.InfoResult
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.emf.ecore.EObject
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionVariable

class ScenarioToSpecFlowGenerator extends ScenarioUMLGenerator {
    val String _path = "..\\test-gen\\ScenariosToSpecFlowTest\\feature"

    var coMap = new HashMap<String, ArrayList<TCTagAction>>
    var siMap = new HashMap<String, ArrayList<String>>
    var niMap = new HashMap<String, ArrayList<TCTagAction>>
    var varMap = new HashMap<String, Expression>
    var headerMap = new HashMap<String, ArrayList<String>>
    var eventName = ""
    var argStr = ""
    var isSeparatedReply = false
    var isAtomicCommandReply = false
    //manipulating scenarios to a structured format
    var scenarioMap = new ArrayList<Pair<EObject, ArrayList<String>>>

    new(String fileName, IFileSystemAccess fsa) {
        super(fileName, fsa)
    }

    def doGenerate(List<Scenarios> scenariosList, String path, IFileSystemAccess fsa,
        HashMap<String, ArrayList<TCTagAction>> coMap, HashMap<String, ArrayList<String>> siMap,
        HashMap<String, ArrayList<TCTagAction>> niMap, HashMap<String, Expression> varMap,
        HashMap<String, ArrayList<String>> headerMap,
        boolean atomic) throws IllegalArgumentException {

        this.coMap = coMap
        this.siMap = siMap
        this.niMap = niMap
        this.varMap = varMap
        this.headerMap = headerMap
        this.isAtomicCommandReply = atomic

        for (scenarios : scenariosList) {
            if (scenarios.filterType.equals("ALL")) {
                // Select Scenarios that match all the given events
                for (s : scenarios.scenarios) {
                    if (isAllNotificationsPresentInScenario(scenarios, s) &&
                        isAllCommandsPresentInScenario(scenarios, s) && isAllSignalsPresentInScenario(scenarios, s)) {
                        // fsa.generateFile(path + "SequenceDiagrams\\feature" + s.name + ".plantuml", ScenarioToUML(s))
                        ToScenarioList(s)
                        fsa.generateFile(path + "ScenariosToSpecFlowTest\\scenario" + s.name + ".feature",
                            ScenarioToSpecFlow(s))
                        this.scenarioMap = new ArrayList<Pair<EObject, ArrayList<String>>>
                    // featureText += ScenarioToSpecFlow(s)
                    // fsa.generateFile(_path + s.name + ".feature", ScenarioToSpecFlow(s))
                    }
                }
            } else {
                // Select any Scenario that has at least one of the events
                val filteredScenariosList = getFilterScenarioList(scenarios)
                // if(generateSpecFlow) fsa.generateFile(_path + ".feature", ScenarioToSpecFlow(filteredScenariosList))
                for (s : filteredScenariosList) {
                    // fsa.generateFile(path + "SequenceDiagrams\\feature" + s.name + ".plantuml", ScenarioToUML(s))
                    fsa.generateFile(_path + "ScenariosToSpecFlowTest\\scenario" + s.name + ".feature",
                        ScenarioToSpecFlow(s))
                // featureText += ScenarioToSpecFlow(s) 
                // fsa.generateFile(_path + s.name + ".feature", ScenarioToSpecFlow(s))
                }
            }
        }
    // fsa.generateFile(_path + "generatedScenarios.feature", featureText)
    }
    
    def ToScenarioList(Scenario scn){
        var argIndex = 0
        var eventIndex = 0
        for(e: scn.events){
            if (e instanceof CommandEvent){
                argIndex = scenarioMap.size
                scenarioMap.add(new Pair<EObject, ArrayList<String>>(e, new ArrayList<String>))
            }
            if (e instanceof CommandReply){
                eventIndex = scenarioMap.size
                scenarioMap.add(new Pair<EObject, ArrayList<String>>(e, new ArrayList<String>))
            }
            if (e instanceof NotificationEvent){
                eventIndex = scenarioMap.size
                argIndex = scenarioMap.size
                scenarioMap.add(new Pair<EObject, ArrayList<String>>(e, new ArrayList<String>))
            }
            if (e instanceof SignalEvent){
                argIndex = scenarioMap.size
                scenarioMap.add(new Pair<EObject, ArrayList<String>>(e, new ArrayList<String>))
            }
            if (e instanceof InfoResult){
                scenarioMap.get(eventIndex).value.add(e.elm.toString)
            }
            if (e instanceof InfoArg){
                scenarioMap.get(argIndex).value.add(e.elm.toString)
            }
        }
    }
    
    def ScenarioToSpecFlow(Scenario scn){
        var isContextOf = context.none
        '''
            # provide your feature tags here
            # @tag1 @tag2
            
            Feature: «scn.name»
            
            # provide your scenario tags here
            # @tag1 @tag2
            
            Scenario: [Explain the scenario here]
            
            Given test_id [enter number] is logged
            And [add more pre-conditions if relevant]
            «FOR i : 0..< this.scenarioMap.size»
                «var e = this.scenarioMap.get(i)»
                «IF e.key instanceof CommandEvent»
                    «IF !isAtomicCommandReply»
                        
                        When «getGherkinTextComd((e.key as CommandEvent).event.name, e.value)»
                        «{eventName =(e.key as CommandEvent).event.name isContextOf = context.when ""}»
                    «ELSE»
                        «IF i+1 < this.scenarioMap.size»
                        «var nextEvent = this.scenarioMap.get(i+1)»
                        «IF !(nextEvent.key instanceof CommandReply)»
                            «{isSeparatedReply = true ""}»
                            «IF isContextOf.equals(context.when)»
                                And «getGherkinTextComd((e.key as CommandEvent).event.name, e.value)»
                            «ELSE»
                                
                                When «getGherkinTextComd((e.key as CommandEvent).event.name, e.value)»
                            «ENDIF»
                            «{isContextOf = context.when ""}»
                        «ELSE»
                            «{argStr = getArgumentStr((e.key as CommandEvent).event.name, e.value) ""}»
                        «ENDIF»
                        «ELSE»
                            
                            When «getGherkinTextComd((e.key as CommandEvent).event.name, e.value)»
                            «{isContextOf = context.when ""}»
                        «ENDIF»
                        «{eventName =(e.key as CommandEvent).event.name ""}»
                    «ENDIF»
                «ELSEIF e.key instanceof SignalEvent»
                    «IF isContextOf.equals(context.when)»
                        And «getGherkinTextSig((e.key as SignalEvent).event.name, e.value)»
                    «ELSE»
                        
                        When «getGherkinTextSig((e.key as SignalEvent).event.name, e.value)»
                    «ENDIF»
                    «{isContextOf = context.when ""}»
                «ELSEIF e.key instanceof NotificationEvent»
                    «IF e.value.equals(null)»
                        «IF isContextOf.equals(context.then)»
                            And «getGherkinTextNotif((e.key as NotificationEvent).event.name)»
                        «ELSE»
                        
                            Then «getGherkinTextNotif((e.key as NotificationEvent).event.name)»
                        «ENDIF»
                        «{isContextOf = context.then ""}»
                    «ELSE»
                        «IF isContextOf.equals(context.then)»
                            And «getGherkinTextNotifResult((e.key as NotificationEvent).event.name, e.value)»
                        «ELSE»

                            Then «getGherkinTextNotifResult((e.key as NotificationEvent).event.name, e.value)»
                        «ENDIF»
                        «{isContextOf = context.then ""}»
                    «ENDIF»
                «ELSEIF e.key instanceof CommandReply»
                    «IF isSeparatedReply»
                        «IF isContextOf.equals(context.then)»
                            And «getGherkinTextComdResult(e.value)»
                        «ELSE»

                            Then «getGherkinTextComdResult(e.value)»
                        «ENDIF»
                        «{isSeparatedReply = false eventName = "" isContextOf = context.then ""}»
                    «ELSE»
                        «IF !isAtomicCommandReply»
                            «IF isContextOf.equals(context.then)»
                                And «getGherkinTextComdResult(e.value)»
                            «ELSE»

                                Then «getGherkinTextComdResult(e.value)»
                            «ENDIF»
                            «{isContextOf = context.then ""}»
                        «ELSE»
                            «IF isContextOf.equals(context.when)»
                                And «getGherkinTextComdResult(e.value)»
                                «IF !argStr.equals("")»«argStr»«ENDIF»
                            «ELSE»
                                
                                When «getGherkinTextComdResult(e.value)»
                                «IF !argStr.equals("")»«argStr»«ENDIF»
                            «ENDIF»
                            «{isContextOf = context.when argStr="" ""}»
                        «ENDIF»
                    «ENDIF»
                «ENDIF»
            «ENDFOR»
        '''
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
