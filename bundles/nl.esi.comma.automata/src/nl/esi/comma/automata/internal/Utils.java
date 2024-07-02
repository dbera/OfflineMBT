package nl.esi.comma.automata.internal;

import java.util.List;

import dk.brics.automaton.State;

public class Utils {
	public static boolean shouldSkipTransition(List<Character> skipCharacters, boolean skipSelfLoop,
			State source, dk.brics.automaton.Transition transition) {
		if (skipSelfLoop && transition.getDest() == source) return true;

		// If at least one character is not skipped return false here.
		for (char c = transition.getMin(); c <= transition.getMax(); c++) {
			if (!skipCharacters.contains(c)) {
				return false;
			}
		}
		return true;
	}
}
