package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.State;

public class PathsComputerPrefixSuffix {
	private final Map<State, LinkedHashMap<State, List<Path>>> lookup = new LinkedHashMap<State, LinkedHashMap<State, List<Path>>>();
	private final Map<State, List<Path>> prefixes = new LinkedHashMap<State, List<Path>>();
	private final Map<State, List<Path>> suffixes = new LinkedHashMap<State, List<Path>>();

	private final boolean minimize;
	private final Automaton automaton;

	public PathsComputerPrefixSuffix(Automaton automaton, boolean minimize) {
		this.automaton = automaton;
		this.minimize = minimize;
	}
	
	public static List<Path> compute(Automaton automaton, boolean minimize) {
		return new PathsComputerPrefixSuffix(automaton, minimize).compute();
	}
	
	public List<Path> compute() {
		if (!automaton.getInitialState().isAccept()) {
			computeLookup(automaton.getInitialState());
		}
		var acceptStatesSorted = new ArrayList<>(automaton.getAcceptStates());
		acceptStatesSorted.sort((State a, State b) -> a.compareTo(b));

		for (var s : acceptStatesSorted) computeLookup(s);
		
		for (var s : acceptStatesSorted) prefixes.put(s, findPaths(automaton.getInitialState(), s, true));
		for (var s : acceptStatesSorted) suffixes.put(s, findPaths(s, s, false));
		
		return computePaths();
	}
	
	private List<Path> computePaths() {
        var prefixesClone = new LinkedHashMap<State, List<Path>>();
        var paths = new ArrayList<Path>();
        prefixes.entrySet().forEach(e -> prefixesClone.put(e.getKey(), new ArrayList<>(e.getValue())));

        for (var entry : suffixes.entrySet()) {
            for (var suffix : entry.getValue()) {
                Path prefix;
                if (!prefixesClone.get(entry.getKey()).isEmpty()) {
                    prefix = prefixesClone.get(entry.getKey()).remove(0);
                } else {
                    prefix = prefixes.get(entry.getKey()).get(0);
                }
                
                paths.add(prefix.combine(suffix));
            }
        }

        // Add remaining prefixes
        prefixesClone.values().forEach(p -> paths.addAll(p));
        
        return paths;
    }
	
	private List<Path> findPaths(State from, State to, boolean emptyForSelfLoop) {
		if (emptyForSelfLoop && from == to) return Arrays.asList(new Path());

		var stack = new ArrayDeque<List<Path>>(Arrays.asList(new ArrayList<>()));
		var visistedStates = new HashSet<State>();
		var paths = new ArrayList<Path>();
		var incompletePaths = new ArrayDeque<Path>();
		while (!stack.isEmpty()) {
			var pathList = stack.removeFirst();
			var state = pathList.isEmpty() ? to : pathList.get(0).getSource();
			for (var entry : lookup.entrySet()) {
				if (minimize && entry.getKey() == state) continue;
				if (entry.getValue().containsKey(state)) {
					for (var path : entry.getValue().get(state)) {
						if (!minimize && pathList.contains(path)) continue;
						var newPathList = new ArrayList<Path>(pathList);
						newPathList.add(0, path);
						if (entry.getKey() == from) {
							paths.add(new Path(newPathList));
						} else if (minimize && visistedStates.contains(entry.getKey())) {
							incompletePaths.add(new Path(newPathList));
						} else {
							stack.add(newPathList);
						}
						visistedStates.add(entry.getKey());
					}
				}
			}
		}
		
		// Note: incompletePaths only contains entries when minimize == true
		var remainingIterations = incompletePaths.size();
		while (!incompletePaths.isEmpty()) {
			if (remainingIterations == 0) break;
			var completed = false;
	    	var incompletePath = incompletePaths.removeFirst();
	    	var target = incompletePath.getSource();
	    	for (var path : paths) {
	    		var completionPath = path.pathTill(target);
	    		if (completionPath != null) {
	    			var completedPath = completionPath.combine(incompletePath);
	    			paths.add(completedPath);
	    			completed = true;
	    			break;
	    		}
	    	}
	    	if (!completed) {
		    	remainingIterations = remainingIterations - 1;
	    		incompletePaths.add(incompletePath);
	    	} else {
	    		remainingIterations = incompletePaths.size();
	    	}	
		}
	    	
		return paths;
	}
	
	private void computeLookup(State startState) {
		var map = new LinkedHashMap<State, List<Path>>();
		lookup.put(startState, map);

		var visistedStates = new HashSet<State>();
		var incompletePaths = new ArrayDeque<Path>();
		var stack = new ArrayDeque<Path>(Arrays.asList(new Path()));
		while (!stack.isEmpty()) {
			var path = stack.removeFirst();
			var state = path.transitions.isEmpty() ? startState : path.lastTransition().target;
			if (minimize) {
				for (var t : state.getTransitions()) {
					if (t.getDest() == state) {
						path = path.combine(new Transition(state, t));
					}
				}
			}
			for (var t : state.getTransitions()) {
				var transition = new Transition(state, t);
				if (minimize && t.getDest() == state) continue;
				if (!minimize && path.transitions.contains(transition)) continue;
				var newPath = path.combine(transition);
				if (transition.target.isAccept()) {
					if (!map.containsKey(transition.target)) {
						map.put(transition.target, new ArrayList<Path>());
					}
					map.get(transition.target).add(newPath);
				} else if (minimize && visistedStates.contains(transition.target)) {
					incompletePaths.add(newPath);
				} else {
					stack.add(newPath);
				}
				visistedStates.add(transition.target);
			}
		}
		
		if (minimize) {
			var paths = map.values().stream().flatMap(List::stream).collect(Collectors.toList());
			for (var completePath : PathsCompleter.complete(paths, incompletePaths)) {
				map.get(completePath.getTarget()).add(completePath);
			}
		}
	}
}
