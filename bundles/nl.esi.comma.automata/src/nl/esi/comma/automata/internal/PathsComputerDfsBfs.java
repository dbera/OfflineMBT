package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.State;
import nl.esi.comma.automata.AlgorithmType;

public class PathsComputerDfsBfs {
	public static List<Path> compute(Automaton automaton, AlgorithmType mode) {
		var paths = new ArrayList<Path>();
		var visistedStates = new HashSet<State>();
		var incompletePaths = new ArrayDeque<Path>();
		var stack = new ArrayDeque<Path>(Arrays.asList(new Path()));
		while (!stack.isEmpty()) {
			var path = stack.removeFirst();
			var state = path.transitions.isEmpty() ? automaton.getInitialState() : path.lastTransition().target;
			if (visistedStates.contains(state)) {
				if (state.isAccept()) paths.add(path);
				else incompletePaths.add(path);
			} else {
				visistedStates.add(state);
				if (state.getTransitions().size() == 0) paths.add(path);
				for (var t : state.getTransitions()) {
					if (mode == AlgorithmType.DFS) stack.addFirst(path.combine(new Transition(state, t)));
					else stack.addLast(path.combine(new Transition(state, t)));
				}
			}
		}
		
		paths.addAll(PathsCompleter.complete(paths, incompletePaths));
		return paths;
	}
}
