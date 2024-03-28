package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.function.Consumer;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.State;
import nl.esi.comma.automata.AlgorithmType;

public class PathsComputerDfsBfs {
	public static List<Path> compute(Automaton automaton, AlgorithmType mode, List<Character> skipCharacters, 
			boolean skipSelfLoop, Consumer<String> stageChanged) {
		var paths = new ArrayList<Path>();
		var completePaths = new ArrayList<Path>();
		var visistedStates = new HashSet<State>();
		var incompletePaths = new ArrayDeque<Path>();
		var stack = new ArrayDeque<Path>(Arrays.asList(new Path()));
		stageChanged.accept("GraphWalk");
		while (!stack.isEmpty()) {
			var path = stack.removeFirst();
			var state = path.transitions.isEmpty() ? automaton.getInitialState() : path.lastTransition().target;
			
			if (state.isAccept()) completePaths.add(path);
			
			if (visistedStates.contains(state)) {
				if (state.isAccept()) paths.add(path);
				else incompletePaths.add(path);
			} else {
				visistedStates.add(state);
				if (state.getTransitions().size() == 0) paths.add(path);
				for (var t : state.getTransitions()) {
					if (Utils.shouldSkipTransition(skipCharacters, skipSelfLoop, state, t)) continue;
					if (mode == AlgorithmType.DFS) stack.addFirst(path.combine(new Transition(state, t)));
					else stack.addLast(path.combine(new Transition(state, t)));
				}
			}
		}

		stageChanged.accept("PathCompletion");
		paths.addAll(PathsCompleter.complete(completePaths, incompletePaths));
		
		stageChanged.accept("Done");
		return paths;
	}
}
