/*
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
package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.function.Consumer;

import dk.brics.automaton.State;

class PathsCompleter {
	// Completes incomplete paths
	// An incomplete path is completed by finding a path to a accept state
	static List<Path> complete(List<Path> completePaths, ArrayDeque<Path> incompletePaths) {
		var result = new ArrayList<Path>();
		var completionLookup = new HashMap<State, Path>();
	    Consumer<Path> addToLookup = (path) -> {
	    	for (var transition : path.transitions) {
	    		if (!completionLookup.containsKey(transition.source)) {
	    			completionLookup.put(transition.source, path);
	    		}
	    	}
	    };
	    completePaths.forEach(p -> addToLookup.accept(p));
	    
	    var counter = 0;
	    while (!incompletePaths.isEmpty()) {
	    	var incompletePath = incompletePaths.removeFirst();
	    	var target = incompletePath.getTarget();
	    	if (completionLookup.containsKey(target)) {
	    		counter = 0;
	    		var completionPath = completionLookup.get(target).pathFrom(target);
				var firstAcceptStateTransition = completionPath.transitions.stream().filter(t -> t.target.isAccept()).findFirst().get();
				var completePath = incompletePath.combine(completionPath.transitions.subList(0, completionPath.transitions.indexOf(firstAcceptStateTransition) + 1));
				addToLookup.accept(completePath);
				result.add(completePath);
	    	} else {
		    	counter++;
	    		incompletePaths.add(incompletePath);
	    	}
	    	
	    	if (counter > incompletePaths.size()) {
	    		throw new RuntimeException("Failed to complete incomplete paths");
	    	}
	    }
	    return result;
	}
}
