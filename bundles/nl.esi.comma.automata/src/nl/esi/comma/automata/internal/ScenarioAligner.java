package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.stream.Collectors;

import dk.brics.automaton.Automaton;
import nl.esi.comma.automata.AlignResult;

public class ScenarioAligner {
	public static AlignResult align(Automaton automaton, Macros macros, String scenario) {
		var stack = new ArrayDeque<Triplet<Path, String, Integer>>();
		stack.add(new Triplet<>(new Path(), "", 0));
		var accepted = new ArrayList<Triplet<Path, String, Integer>>();
		var notAccepted = new ArrayList<Triplet<Path, String, Integer>>();
		while (!stack.isEmpty()) {
			var item = stack.removeFirst();
			var path = item.a;
			var macro = item.b;
			if (item.c == scenario.length()) {
				accepted.add(item);
			} else if (!macro.equals("")) {
				// We are in a macro transition
				if (macro.charAt(0) == scenario.charAt(item.c)) {
					stack.add(new Triplet<>(item.a, macro.substring(1), item.c + 1));
				} else {
					notAccepted.add(item);
				}
			} else {
				var state = path.transitions.isEmpty() ? automaton.getInitialState() : path.getTarget();
				var acceptedAtLeastOnce = false;
				for (var transition : state.getTransitions()) {
					for (char c = transition.getMin(); c <= transition.getMax(); c++) {
						for (var expanded : macros.expand(c)) {
							if (expanded.charAt(0) == scenario.charAt(item.c)) {
								var newPath = path.combine(new Transition(state, transition));
								stack.add(new Triplet<>(newPath, expanded.substring(1), item.c + 1));
								acceptedAtLeastOnce = true;
							}
						}
					}
				}
				if (!acceptedAtLeastOnce) {
					notAccepted.add(item);
				}
			}
		}
		
		var fullyAccepted = accepted.stream().filter(e -> e.b.equals("") && e.a.getTarget().isAccept())
				.collect(Collectors.toList());
		if (!fullyAccepted.isEmpty()) {
			return new AlignResult(AlignResult.Status.FULLY_ACCEPTED, scenario, "", scenario, fullyAccepted.get(0).a);
		} else if (!accepted.isEmpty()) {
			var path = accepted.get(0).a;
			if (!accepted.get(0).b.equals("")) path = path.removeLastTranition();
			return new AlignResult(AlignResult.Status.PARTIAL_ACCEPTED, scenario, "", scenario, path);
		} else {
			var item = notAccepted.get(0);
			return new AlignResult(AlignResult.Status.NOT_ACCEPTED, scenario.substring(0, item.c), scenario.substring(item.c), scenario, item.a);			
		}
	}
}
