package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.State;

public class PathsComputerPrefixSuffix {
	private final Map<State, LinkedHashMap<State, List<Path>>> lookup = new LinkedHashMap<State, LinkedHashMap<State, List<Path>>>();
	private final Map<State, List<Path>> prefixes = new LinkedHashMap<State, List<Path>>();
	private final Map<State, List<Path>> suffixes = new LinkedHashMap<State, List<Path>>();

	private final boolean minimize;
	private final Automaton automaton;
	private final List<Character> skipCharacters;
	private final boolean skipSelfLoop;
	private final boolean suffix;
	private final Consumer<String> stageChanged;
	
	private PathsComputerPrefixSuffix(Automaton automaton, boolean suffix, boolean minimize, List<Character> skipCharacters, 
			boolean skipSelfLoop, Consumer<String> stateChanged) {
		this.automaton = automaton;
		this.minimize = minimize;
		this.skipCharacters = skipCharacters;
		this.suffix = suffix;
		this.stageChanged = stateChanged;
		this.skipSelfLoop = skipSelfLoop;
	}
	
	public static List<Path> compute(Automaton automaton, boolean suffix, boolean minimize, List<Character> skipCharacters, 
			boolean skipSelfLoop, Consumer<String> stageChanged) {
		return new PathsComputerPrefixSuffix(automaton, suffix, minimize, skipCharacters, skipSelfLoop, stageChanged).compute();
	}
	
	public List<Path> compute() {
		stageChanged.accept("ComputeLookup");
		this.computeLookup();
		
		stageChanged.accept("StateSort");
		var acceptStatesSorted = new ArrayList<>(automaton.getAcceptStates());
		acceptStatesSorted.sort((State a, State b) -> a.compareTo(b));
		
		stageChanged.accept("ComputePrefix");
		for (var s : acceptStatesSorted) prefixes.put(s, findPaths(automaton.getInitialState(), s, true));
		if (suffix) {
			stageChanged.accept("ComputeSuffix");
			for (var s : acceptStatesSorted) suffixes.put(s, findPaths(s, s, false));
		}
		
		stageChanged.accept("ComputePaths");
		var paths = computePaths();
		
		stageChanged.accept("Done");
		return paths;
	}
	
	private void computeLookup() {
		automaton.getAcceptStates().forEach(s -> lookup.put(s, new LinkedHashMap<State, List<Path>>()));
		lookup.put(automaton.getInitialState(), new LinkedHashMap<State, List<Path>>());
		
		var visitedAcceptStates = new HashSet<State>();
		var incompletePaths = new ArrayDeque<Path>();
		visitedAcceptStates.add(automaton.getInitialState());
		var visitedStates = new HashSet<State>();
		var stack = new ArrayDeque<Tuple<State, Path>>();
		stack.add(new Tuple<State, Path>(automaton.getInitialState(), new Path()));
		stageChanged.accept("ComputeLookup:GraphWalk");
		while (!stack.isEmpty()) {
			var entry = stack.removeFirst();
			var state = entry.b.transitions.isEmpty() ? entry.a : entry.b.getTarget();
			for (var t : state.getTransitions()) {
				var transition = new Transition(state, t);
				if (entry.b.transitions.contains(transition)) continue;
				if (Utils.shouldSkipTransition(skipCharacters, skipSelfLoop, state, t)) continue;
				var newPath = entry.b.combine(transition);
				if (transition.target.isAccept()) {
					if (!lookup.get(entry.a).containsKey(transition.target)) {
						lookup.get(entry.a).put(transition.target, new ArrayList<Path>());
					}
					lookup.get(entry.a).get(transition.target).add(newPath);
					if (!visitedAcceptStates.contains(transition.target)) {
						visitedAcceptStates.add(transition.target);
						stack.add(new Tuple<State, Path>(transition.target, new Path()));
					}
				} else if (minimize && visitedStates.contains(transition.target)) {
					incompletePaths.add(newPath);
				} else {
					stack.add(new Tuple<State, Path>(entry.a, newPath));
				}
				visitedStates.add(transition.target);
			}
		}
		
		if (minimize) {
			stageChanged.accept("PathCompletion");
			var paths = lookup.values().stream().map(v -> v.values().stream()
					.flatMap(List::stream).collect(Collectors.toList()))
					.flatMap(List::stream).collect(Collectors.toList());
			for (var path : PathsCompleter.complete(paths, incompletePaths)) {
				if (!lookup.get(path.getSource()).containsKey(path.getTarget())) {
					lookup.get(path.getSource()).put(path.getTarget(), new ArrayList<Path>());
				}
				lookup.get(path.getSource()).get(path.getTarget()).add(path);
			}
		}
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

	private List<Path> findPaths(State from, State to, boolean prefix) {
		if (prefix && from == to) return Arrays.asList(new Path());

		var stack = new ArrayDeque<Tuple<List<Path>, Set<State>>>();
		if (prefix) {
			stack.add(new Tuple<List<Path>, Set<State>>(new ArrayList<>(), Collections.singleton(to)));
		} else {
			stack.add(new Tuple<List<Path>, Set<State>>(new ArrayList<>(), new HashSet<>()));
		}
		
		var paths = new ArrayList<Path>();
		while (!stack.isEmpty()) {
			var entry = stack.removeFirst();
			var state = entry.a.isEmpty() ? to : entry.a.get(0).getSource();
			for (var l : lookup.entrySet()) {
				if (l.getValue().containsKey(state)) {
					for (var path : l.getValue().get(state)) {
						if (entry.b.contains(path.getSource())) continue;
						var newPathList = new ArrayList<Path>(entry.a);
						newPathList.add(0, path);
						if (l.getKey() == from) {
							paths.add(new Path(newPathList));
						} else {
							var newStateList = new HashSet<>(entry.b);
							newStateList.add(path.getSource());
							stack.add(new Tuple<>(newPathList, newStateList));
						}
					}
				}
			}
		}
		
		return paths;
	}
}
