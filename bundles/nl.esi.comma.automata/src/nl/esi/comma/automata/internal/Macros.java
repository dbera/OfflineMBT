package nl.esi.comma.automata.internal;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class Macros {
	private Map<Character, List<char[]>> macros = new HashMap<Character, List<char[]>>();
	
	public void add(char macroChar, char[] macro) {
		detectCycle(macroChar, macro);
		if (!macros.containsKey(macroChar)) macros.put(macroChar, new ArrayList<>());
		macros.get(macroChar).add(macro);
	}
	
	private void detectCycle(char macroChar, char[] macro) {
		var stack = new ArrayDeque<ArrayDeque<Character>>();
		stack.add(new ArrayDeque<>(Arrays.asList(macroChar)));
		while (!stack.isEmpty()) {
			var seen = stack.pollFirst();
			var char_ = seen.peekLast();
			var values = char_ == macroChar ? Arrays.asList(macro) : macros.get(char_);
			for (var value : values) {
				for (var c : value) {
					if (seen.contains(c)) {
						throw new RuntimeException("Macro cycle detected: " + seen);
					} else if (macros.containsKey(c)) {
						var next = new ArrayDeque<>(seen);
						next.add(c);
						stack.add(next);
					}
				}
			}
		}
	}
	
	public List<String> expand(char macroChar) {
		if (macros.containsKey(macroChar)) {
			return macros.get(macroChar).stream().map(macro -> {
				var result = Arrays.asList("");
				for (var char_ : macro) {
					var newResult = new ArrayList<String>();
					var expanded = expand(char_);
					for (var r : result) {
						for (var e : expanded) {
							newResult.add(r + e);
						}
					}
					result = newResult;
				}
				return result.stream().map(s -> s.toString()).collect(Collectors.toList());
			}).flatMap(List::stream).collect(Collectors.toList());
		} else {
			return Arrays.asList(Character.toString(macroChar));
		}
	}
}
