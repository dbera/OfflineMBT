package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;

public class SequenceComputer {
	public static List<String> compute(Macros macros, List<Path> paths, boolean minimize, int k) {
		var sequences = new LinkedHashSet<String>();
		var seenTransitions = new HashSet<Transition>();
		var stack = new ArrayDeque<Triplet<Path, String, Integer>>();
		paths.forEach(p -> stack.add(new Triplet<Path, String, Integer>(p, "", 0)));
		while (!stack.isEmpty()) {
			var item = stack.removeFirst();
			if (item.c == item.a.transitions.size()) {
				sequences.add(item.b);
			} else {
				var transition = item.a.transitions.get(item.c);
				if (minimize && transition.isLoop() && seenTransitions.contains(transition)) {
					stack.add(new Triplet<Path, String, Integer>(item.a, item.b, item.c + 1));
				} else {
					var max = transition.getMax();
					if (minimize) {
						max = seenTransitions.contains(transition) ? transition.getMin() : transition.getMax();
						seenTransitions.add(transition);
					}
					
					for (var c = transition.getMin(); c <= max; c++) {
						for (var expanded : macros.expand(c)) {
							stack.add(new Triplet<Path, String, Integer>(item.a, item.b + expanded, item.c + 1));
							
							if (k != 1 && transition.isLoop()) {
								for (int i = 1; i < k; i++) {
									var last = stack.getLast();
									stack.add(new Triplet<Path, String, Integer>(last.a, last.b + Character.toString(c), last.c));
		                        }
							}
						}
					}
				}
			}
		}
		
		return removePrefixSequences(new ArrayList<>(sequences));
	}
	
	private static List<String> removePrefixSequences(List<String> sequences) {
    	var result = new LinkedHashSet<String>();
    	for (var seq1 : sequences) {
    		var isPrefix = false;
    		for (var seq2 : sequences) {
        		if (seq1 != seq2 && seq1.length() < seq2.length() && seq2.startsWith(seq1)) {
        			isPrefix = true;
        			break;
        		}
        	}
    		
    		if (!isPrefix) {
    			result.add(seq1);
    		}
    	}
    	
    	return new ArrayList<String>(result);
    }
}
