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

import dk.brics.automaton.Automaton
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.PrintWriter
import java.util.ArrayList
import java.util.Arrays
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import java.util.StringTokenizer
import org.eclipse.xtext.generator.IFileSystemAccess2

class ConstraintStateMachine 
{
    var name = new String
    
    var text = new ArrayList<String>                    // added for CoCo dashboard
    
    var existentialText = new ArrayList<String>
    var futureText = new ArrayList<String>
    var pastText = new ArrayList<String>
    var pastFutureText = new ArrayList<String>
    var choiceText = new ArrayList<String>
    
    var dot = new String                                // added for CoCo dashboard
    var highlightedKeywords = new ArrayList<String>     // added for CoCo dashboard
    
    var Map<String,Character> unicodeMap = new HashMap<String,Character> // steps (with or without data) and sequence defs appearing in constraints file
    
    // Added DB to support complex mapping of actions 
    // to sequences and non-determinism
    var stepDataMap = new HashMap<String, Set<String>>
    var stepsMapping = new HashMap<String, String>
    var Map<String,Character> unusedUnicodeMap = new HashMap<String,Character>();
    var sequenceDefMap = new HashMap<String,ArrayList<List<String>>> // list of defined and used macros
    // a -> { b,c,d ; x,y,z } // support non-deterministic mapping
    var compoundUnicodeMap = new HashMap<Character,List<List<Character>>>
    // list of regexes
    var listOfRegexes = new ArrayList<String>
    var Character terminalChar = null
    ////////////////////
    
    var Map<String,String> actionToExprMap = new HashMap<String,String>(); // global for each constraint file
    var List<Automaton> automataList = new ArrayList<Automaton>
    var Automaton fa = new Automaton
   
    new(String _name, 
        Map<String, Character> _unicodeMap,
        Map<String, Set<String>> _stepDataMap,
        Map<String, String> _stepsMapping,
        Map<String, Character> _unusedUnicodeMap,
        Map<String, List<List<String>>> _sequenceDefMap,
        Map<Character, List<List<Character>>> _compoundUnicodeMap,
        List<String> _listOfRegexes,
        Map<String,String> _actionToExprMap,
        List<Automaton> _automataList, Character finalChar,
        List<String> _text, 
        List<String> _highlightedKeywords
    ) {
            terminalChar = finalChar
            name = _name
            for(k : _unicodeMap.keySet) unicodeMap.put(k ,_unicodeMap.get(k))
            for(k : _stepDataMap.keySet) {
                var elmSet = new HashSet<String>
                for(elm : _stepDataMap.get(k)) elmSet.add(elm)
                stepDataMap.put(k, elmSet)
            }
            for(k : _stepsMapping.keySet) stepsMapping.put(k ,_stepsMapping.get(k))
            for(k : _unusedUnicodeMap.keySet) unusedUnicodeMap.put(k ,_unusedUnicodeMap.get(k))
            for(k : _sequenceDefMap.keySet) {
                var listOfList = new ArrayList<List<String>>
                for(elmList : _sequenceDefMap.get(k)) {
                    var list = new ArrayList<String>
                    for(elm : elmList) {
                        list.add(elm)
                    }
                    listOfList.add(list)
                }
                sequenceDefMap.put(k,listOfList)
            }
            for(k : _compoundUnicodeMap.keySet) {
                var listOfList = new ArrayList<List<Character>>
                for(elmList : _compoundUnicodeMap.get(k)) {
                    var list = new ArrayList<Character>
                    for(elm : elmList) {
                        list.add(elm)
                    }
                    listOfList.add(list)
                }
                compoundUnicodeMap.put(k,listOfList)
            }
            for(elm : _listOfRegexes) listOfRegexes.add(elm)
            for(elm : _automataList) automataList.add(elm.clone)

            for(elm: _text) text.add(elm)
            for(elm : _highlightedKeywords) highlightedKeywords.add(elm)
            
            for(k : _actionToExprMap.keySet)
                actionToExprMap.put(k ,_actionToExprMap.get(k))
            
            displayComputedMaps
    }

    def setTemplateText(List<String> choice, List<String> past, 
        List<String> future, List<String> pastFuture, List<String> existential
    ) {
        choiceText.addAll(choice)
        pastText.addAll(past)
        futureText.addAll(future)
        pastFutureText.addAll(pastFuture)
        existentialText.addAll(existential)
    }

    def setDotText(String _dot) { dot = _dot }

    def getConstraintText() { return text }
    def getHighLightedKeyWords() { return highlightedKeywords }
    def getDot() { return dot }
    def getTerminalChar() { return terminalChar }
	def getStepsMapping() { return stepsMapping }

    def displayComputedMaps() {
        var printWriter = new PrintWriter(System.out,true);
        System.out.println("UNICODE MAP")
        for(elm : unicodeMap.keySet) {
            // printWriter.println("    Key: " + elm + "  Value: "+ unicodeMap.get(elm))
            System.out.println("    Key: " + elm + "  Value: "+ unicodeMap.get(elm))
            // System.out.println("    Step: " + elm + " Maps To " + stepsMapping.get(elm))
            // System.out.println("    Step: " + stepsMapping.get(elm) + " Maps To " + stepDataMap.get(stepsMapping.get(elm)))
        }
        System.out.println("UnUSed UNICODE MAP")
        for(elm : unusedUnicodeMap.keySet) {
            System.out.println("    Key: " + elm + "  Value: "+ unusedUnicodeMap.get(elm))
            // System.out.println("    Step: " + elm + " Maps To " + stepsMapping.get(elm))
            // System.out.println("    Step: " + stepsMapping.get(elm) + " Maps To " + stepDataMap.get(stepsMapping.get(elm)))
        }
        System.out.println("Sequence Def MAP")
        for(elm : sequenceDefMap.keySet) {
            System.out.println("    Key: " + elm + "  Value: "+ sequenceDefMap.get(elm))
        }
        System.out.println("Compound UNICODE MAP")
        for(elm : compoundUnicodeMap.keySet) {
            System.out.println("    Key: " + elm + "  Value: "+ compoundUnicodeMap.get(elm))            
            //for(e : compoundUnicodeMap.get(elm))
                //for(e1 : e) System.out.println(e1 as int)
        }
        System.out.println("List Of Regex")
        for(elm : listOfRegexes) System.out.println("   RegEx: " + elm)
    }
    
    def getName() { return name }
    def getUnicodeMap() { return unicodeMap }
    def getActExprMap() { return actionToExprMap }
    def getCompoundUnicodeMap() { return compoundUnicodeMap }
    def getRegExList() { return listOfRegexes }
    def getAutomataList() { return automataList }
    
    def getComputedAutomata() { return fa }
    
    def getStepName(char c) {
        for(k : unicodeMap.keySet) {
            if(c.equals(unicodeMap.get(k))) {
                return k
            }
        }
        for(k : unusedUnicodeMap.keySet) {
            if(c.equals(unusedUnicodeMap.get(k))) {
                return k
            }
        }
        
        return " ANY "
    }
    
    def getStepChar(String s) {
        if(unicodeMap.containsKey(s)) return unicodeMap.get(s)
        else if(unusedUnicodeMap.containsKey(s)) return unusedUnicodeMap.get(s)
        else { /*System.out.println("Could not find character for step " + s)*/ return terminalChar } 
    }
    
    def computeAutomaton(String path, IFileSystemAccess2 fsa, boolean display, boolean printConstraints) {
        fa = new Automaton
        if(automataList.size() > 1) {
            // final Automaton Construction 
            fa = automataList.get(0);
            for(var i = 1; i < automataList.size(); i++) {
                fa = fa.intersection(automataList.get(i));
            }
            // Visualize final automaton
            if(display) displayAutomaton(fa, path, true, fsa, printConstraints);          
        }
        return transformWithLabels(fa, fa.toDot(), true, printConstraints)
    }
    
   def displayAutomaton(Automaton fa, String path, boolean useProvidedLabels, IFileSystemAccess2 fsa, boolean printConstraints) 
    {
        var fname = name + ".dot"
        fsa.generateFile("\\Constraints\\"+fname, transformWithLabels(fa, fa.toDot(),useProvidedLabels, printConstraints))
        
        /*var file = new File(path + fname);
        if (!file.exists()) {
            try { file.createNewFile(); } catch (IOException e) { e.printStackTrace(); } 
        }
        try {
            //var fw = new FileWriter(file);
            //var out = new BufferedWriter(fw);
            var BufferedWriter out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(path + fname)))
            out.write(transformWithLabels(fa.toDot(),useProvidedLabels)); //} catch (IOException e) { e.printStackTrace(); 
        } catch (FileNotFoundException e1) { e1.printStackTrace(); } catch (IOException e1) { e1.printStackTrace(); }
        */
        
        var ProcessBuilder builder = new ProcessBuilder("cmd.exe", "/c", "dot -Tpng -O "+ fname);
        builder.redirectErrorStream(true);
        var Process p = null;
        try { p = builder.start(); } catch (IOException e) { e.printStackTrace(); }
        var BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()));
        var String line = null;
        do {
            try {
            line = r.readLine();
            } catch (IOException e) {
                e.printStackTrace();
            }
            //if (line == null) { break; }
            //System.out.println(line);
        } while (line!==null)
        /*String path = "C:\\Users\\berad\\Desktop\\ContentsFeb2021\\JavaAndCSharpSources\\JavaWorkspace2020\\wrkspace\\DemoRegExp\\g.dot.png";*/
        var String expr1 = "dot -Tpng " + path + fname + " -O " + fname;
        //String apath = path + "g.dot.png";
        var String expr2 = "rundll32.exe \"C:\\Program Files\\Windows Photo Viewer\\PhotoViewer.dll\", ImageView_Fullscreen " + path + fname + ".png";
        try { Runtime.getRuntime().exec(expr1); } catch (IOException e) { e.printStackTrace(); }
        try { Runtime.getRuntime().exec(expr2); } catch (IOException e) { e.printStackTrace(); }
    }
    
    // assumption: constraint text is available.
    def String transformWithLabels(Automaton fa, String str, boolean useProvidedLabels, boolean printConstraints) {
        var String final_str = str
        /*var matcher = Pattern.compile("(\"[^\"]*?\")").matcher(final_str);
        var sb = new StringBuffer();
        while (matcher.find()) {
           matcher.appendReplacement(sb, matcher.group(1).replaceAll("_", " "));
        }
        matcher.appendTail(sb)
        final_str = sb.toString*/
        
        var Set<String> labelAlphabet = getLegendUnicode(fa)
        var Map<String, String> legends = newHashMap
        var printLegend = printConstraints

        if(useProvidedLabels) {
            for(String key : unicodeMap.keySet()) {
                //System.out.println("check<!> " + "[label=\"" + "\\u"+String.format("%04x", unicodeMap.get(key)) + "\"]"  + " -> " + key);
                //System.out.println("check<!> " + "[label=\"" + "\\u"+String.format("%04x",(unicodeMap.get(key) as int)) + "\"]"  + " -> " + key);
                if(final_str.contains("[label=\"" + unicodeMap.get(key).toString() + "\"]")) {
                    //System.out.println("check " + "[label=\"" + unicodeMap.get(key).toString() + "\"]"  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + unicodeMap.get(key).toString() + "\"]", "[label=\"" + key + "\"]");
                }
                /*if(final_str.contains("[label=\"" + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key))) + "\"]")) {
                    System.out.println("check<> " + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key)))  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key))) + "\"]", "[label=\"" + key + "\"]");
                }*/
                if(final_str.contains("[label=\"" + "\\u"+String.format("%04x",(unicodeMap.get(key) as int)) + "\"]")) {
                    //System.out.println("check<> " + "\\u"+String.format("%04x",(unicodeMap.get(key) as int))  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + "\\u"+String.format("%04x",(unicodeMap.get(key) as int)) + "\"]", "[label=\"" + key + "\"]");
                }
                
                if(labelAlphabet.contains(unicodeMap.get(key).toString)){
                	legends.put(unicodeMap.get(key).toString(), key)
                }
            }
            
            //add Legend
            if (!legends.empty) {
            	//var legend = "  graph [labelloc=\"b\" labeljust=\"l\" label=<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\">" + "\n"
            	var legend = "subgraph cluster0 {  rank = min color=white \n" + "  legendTable [ shape=plaintext color=black fontname=Courier" + "\n"
            	legend += "   label=< " + "\n"
            	legend += "     <table border='0' cellborder='1' cellspacing='0'>" + "\n"
				legend += "       <tr><td bgcolor=\"lightblue\"><b> Legend </b></td></tr>" + "\n"
				for (c : legends.keySet) legend += "      <tr><td>" + "<b>" +c+ "</b>" + "</td><td>" + legends.get(c).replaceAll("_", " ") + "</td></tr>" + "\n"
				legend += "  </table>>] }" + "\n\n"
            	final_str = final_str.replace("digraph Automaton {\n", "digraph Automaton {\n " + legend)
            }
            
            if(printLegend) {
                var constraintTxt = "subgraph cluster1 {  rank = max color=white \n" + "  constraintTable [" + "\n"
                constraintTxt += "   shape=plaintext" + "\n"
                constraintTxt += "   color=black fontname=Courier" + "\n"
                constraintTxt += "   label=< " + "\n"
                constraintTxt += "     <table border='0' cellborder='1' cellspacing='0'>" + "\n"
                
                constraintTxt += "       <tr><td bgcolor=\"lightblue\"><b> List of Constraints </b></td></tr>" + "\n"
                
                if(!futureText.isEmpty) {
                    constraintTxt += "       <tr><td bgcolor=\"lightgrey\">future</td></tr>" + "\n"
                    for(elm : futureText) constraintTxt += "       <tr><td>" +addLineBreaks(elm)+ "</td></tr>" + "\n" //  align='left'
                } 
                if(!pastText.isEmpty) {
                    constraintTxt += "       <tr><td bgcolor=\"lightgrey\">past</td></tr>" + "\n"
                    for(elm : pastText) constraintTxt += "       <tr><td>" +addLineBreaks(elm)+ "</td></tr>" + "\n" //  align='left'
                } 
                if(!pastFutureText.isEmpty) {
                    constraintTxt += "       <tr><td bgcolor=\"lightgrey\">past-future</td></tr>" + "\n"
                    for(elm : pastFutureText) constraintTxt += "       <tr><td>" +addLineBreaks(elm)+ "</td></tr>" + "\n" //  align='left'
                } 
                if(!choiceText.isEmpty) {
                    constraintTxt += "       <tr><td bgcolor=\"lightgrey\">choice</td></tr>" + "\n"
                    for(elm : choiceText) constraintTxt += "       <tr><td>" +addLineBreaks(elm)+ "</td></tr>" + "\n" //  align='left'
                }
                if(!existentialText.isEmpty) {
                    constraintTxt += "       <tr><td bgcolor=\"lightgrey\">existential</td></tr>" + "\n"
                    for(elm : existentialText) constraintTxt += "       <tr><td>" +addLineBreaks(elm)+ "</td></tr>" + "\n" //  align='left'
                }
                
                //for(elm : text) constraintTxt += "       <tr><td>" +addLineBreaks(elm)+ "</td></tr>" + "\n" //  align='left'
                
                constraintTxt += "     </table>" + "\n"
                constraintTxt += "  >] }" + "\n\n"
                final_str = final_str.replace("digraph Automaton {\n", "digraph Automaton {\n " + constraintTxt)
            }
        }
        return final_str.replaceAll("_", " ");
    }
	
	def highlightKeywords(String elm) {
	    var str = elm
	    var listOfKeywords = new ArrayList<String>(
	        Arrays.asList("if", "whenever", "then", "have-occurred-before", "eventually-follow", "either", 
	        "must-have-occurred-before", "must-follow", "immediately-follow", "have-occurred-immediately-before", 
	        "occurs-as-well", "vice-versa", "eventually-occur", "but-never-together", "occurs-last", "occurs-first", 
	        "occurs-at-most", "occurs-exactly", "no", "not", "occurs-at-least", "occurs", "must", "in-between")
	    )
	    for(key : listOfKeywords) {
	        str = str.replaceAll("\\b"+key+"\\b", "<b> "+key+" </b>")
	    }  
	    return str 
	}
	
	def addLineBreaks(String elm) {
	    if(elm.length > 60)  { return highlightKeywords(addLinebreaks(elm, 50)) }
	    else return highlightKeywords(elm)
	}
	
    def addLinebreaks(String input, int maxLineLength) {
        var tok = new StringTokenizer(input, " ");
        var output = new StringBuilder(input.length());
        var lineLen = 0;
        while (tok.hasMoreTokens()) {
            var word = tok.nextToken();
    
            if (lineLen + word.length() > maxLineLength) {
                output.append("<br />");
                lineLen = 0;
            }
            output.append(word + " ");
            lineLen += word.length();
        }
        return output.toString();
    }
	
	def insertString(String originalString, String stringToBeInserted, int index)
    {
        var newString = new StringBuffer(originalString);
        newString.insert(index + 1, stringToBeInserted);
        return newString.toString();
    }
	
	def Set<String> getLegendUnicode(Automaton fa){
		var Set<String> labelAlphabet = newHashSet
		var states = fa.states
		for (s : states){
			for(t : s.transitions){
				if (t.min !== t.max){
					var c = t.min
					while (c <= t.max){
						labelAlphabet.add(c.toString)
						c++
					}
				}
			}
		}
		return labelAlphabet
	}
}