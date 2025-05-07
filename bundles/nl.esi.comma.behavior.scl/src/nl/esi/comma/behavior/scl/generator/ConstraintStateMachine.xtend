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
package nl.esi.comma.behavior.scl.generator

import java.util.Map
import java.util.HashMap
import java.util.List
import java.util.ArrayList
import java.io.BufferedWriter
import java.io.OutputStreamWriter
import java.io.FileOutputStream
import java.io.FileNotFoundException
import java.io.IOException
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.concurrent.TimeUnit
import dk.brics.automaton.Automaton

class ConstraintStateMachine {
    var name = new String
    var Map<String,Character> unicodeMap = new HashMap<String,Character> // steps (with or without data) appearing in constraints file
    var Map<String,String> actionToExprMap = new HashMap<String,String>(); // global for each constraint file
    var List<Automaton> automataList = new ArrayList<Automaton>
    var Automaton fa = new Automaton
   
    new(String _name, Map<String,Character> _unicodeMap, Map<String,String> _actionToExprMap, List<Automaton> _automataList) {
            name = _name
            for(k : _unicodeMap.keySet)
                unicodeMap.put(k ,_unicodeMap.get(k))
            for(k : _actionToExprMap.keySet)
                actionToExprMap.put(k ,_actionToExprMap.get(k))
            for(elm : _automataList)
                automataList.add(elm.clone)
    }
    
    def getName() { return name }
    def getUnicodeMap() { return unicodeMap }
    def getActExprMap() { return actionToExprMap }
    def getAutomataList() { return automataList }
    
    def getComputedAutomata() { return fa }
    
    def getStepName(char c) {
        for(k : unicodeMap.keySet) {
            if(c.equals(unicodeMap.get(k))) {
                return k
            }
        }
        return " ANY "
    }
    
    def printUnicodeMap() {
    	for(k : unicodeMap.keySet)
    		System.out.println("Key : " + k + " Value : " + unicodeMap.get(k))
    }

    def printActToExprMap() {
    	for(k : actionToExprMap.keySet)
    		System.out.println("Key : " + k + " Expr : " + actionToExprMap.get(k))
    }

    
    def computeAutomaton(String path) {
        fa = new Automaton
        if(automataList.size() > 1) {
            // final Automaton Construction 
            fa = automataList.get(0);
            for(var i = 1; i < automataList.size(); i++) {
                fa = fa.intersection(automataList.get(i));
            }
            // Visualize final automaton
            displayAutomaton(fa, path, true);          
        }
    }
    
   def displayAutomaton(Automaton fa, String path, boolean useProvidedLabels) 
    {
    	printUnicodeMap
    	printActToExprMap
        var fname = name + ".dot"
        try(
            var BufferedWriter out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(path + fname))) //path + fname
        ) {
            try { out.write(transformWithLabels(fa.toDot(),useProvidedLabels)); } catch (IOException e) { e.printStackTrace(); } 
        } catch (FileNotFoundException e1) { e1.printStackTrace(); } catch (IOException e1) { e1.printStackTrace(); }

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
        TimeUnit.SECONDS.sleep(3);
        var String expr2 = "rundll32.exe \"C:\\Program Files\\Windows Photo Viewer\\PhotoViewer.dll\", ImageView_Fullscreen " + path + fname + ".png";
        try { Runtime.getRuntime().exec(expr1); } catch (IOException e) { e.printStackTrace(); }
        try { Runtime.getRuntime().exec(expr2); } catch (IOException e) { e.printStackTrace(); }
    }
    
    def String transformWithLabels(String str, boolean useProvidedLabels) {
        var String final_str = str;
        if(useProvidedLabels) {
            for(String key : unicodeMap.keySet()) {
                //System.out.println("check<!> " + "[label=\"" + "\\u"+String.format("%04x", (int) unicodeMap.get(key)) + "\"]"  + " -> " + key);
                if(final_str.contains("[label=\"" + unicodeMap.get(key).toString() + "\"]")) {
                    //System.out.println("check " + "[label=\"" + unicodeMap.get(key).toString() + "\"]"  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + unicodeMap.get(key).toString() + "\"]", "[label=\"" + key + "\"]");
                }
                if(final_str.contains("[label=\"" + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key))) + "\"]")) {
                    //System.out.println("check<> " + "\\u"+String.format("%04x", (int) unicodeMap.get(key))  + " -> " + key);
                    final_str = final_str.replace("[label=\"" + "\\u"+String.format("%04x", Character.getNumericValue(unicodeMap.get(key))) + "\"]", "[label=\"" + key + "\"]");
                }
            }
        }
        return final_str;
    }
}