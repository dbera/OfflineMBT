package nl.esi.comma.automata;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.State;
import nl.esi.comma.automata.internal.Path;
import nl.esi.comma.automata.internal.Transition;

public class ScenarioComputeResult {
	public final List<String> scenarios;
	public final String statistics;	
	
	ScenarioComputeResult(List<String> scenarios, List<Path> paths, Automaton automaton, AlgorithmType algorithm, List<AlignResult> existingScenarios) {
		this.scenarios = scenarios;
		this.statistics = computeStatistics(algorithm, paths, automaton, existingScenarios);
	}
	
	private static String computeStatistics(AlgorithmType algorithm, List<Path> paths, Automaton automaton, List<AlignResult> existingScenarios) {
		var allStates = automaton.getStates().size();
		var allTransitions = automaton.getNumberOfTransitions();
		var coveredStates = new HashSet<State>();
		var coveredTransitions = new HashMap<Transition, Integer>();
		
		var steps = 0;
		for (var path : paths) {
			coveredStates.add(path.getSource());
			for (var transition : path.transitions) {
				coveredStates.add(transition.target);
				if (!coveredTransitions.containsKey(transition)) coveredTransitions.put(transition, 0);
				coveredTransitions.put(transition, coveredTransitions.get(transition) + 1);
				steps += (transition.getMax() - transition.getMin()) + 1;
			}
		}
		
		var transitionExecution = new HashMap<Integer, Integer>();
		for (var e : coveredTransitions.values()) {
			if (!transitionExecution.containsKey(e)) transitionExecution.put(e, 0);
			transitionExecution.put(e, transitionExecution.get(e) + 1);
		}
		var transitionExecutionEntries = transitionExecution.entrySet().stream().collect(Collectors.toList());
		transitionExecutionEntries.sort((a, b) -> b.getKey() - a.getKey());
		var transitionsCoverdByExistingTestCases = existingScenarios.stream().map(r -> r.path.transitions)
			.flatMap(List::stream).collect(Collectors.toSet());

		var result = "";
		result += String.format("Algorithm: %s\n", algorithm.toString());
		result += String.format("Transitions in automaton: %d\n", allTransitions);
		result += String.format(Locale.US, "Transitions covered by existing testcases: %.2f%%\n", (transitionsCoverdByExistingTestCases.size() / (double) allTransitions) * 100);
		result += String.format("States in automaton: %d\n", allStates);
		result += String.format("Sequences: %d\n", paths.size());
		result += String.format("Steps: %d\n", steps);
		result += String.format(Locale.US, "Average steps per sequence: %.2f\n", (double) steps / paths.size());
		result += String.format(Locale.US, "State coverage: %.2f%%\n", (coveredStates.size() / (double) allStates) * 100);
		result += String.format(Locale.US, "Transition coverage: %.2f%%\n", (coveredTransitions.size() / (double) allTransitions) * 100);
		result += String.format(Locale.US, "Average transition execution: %.2f\n", coveredTransitions.values().stream().mapToDouble(i -> i).average().getAsDouble());
		result += "\nTimes transitions are executed:\n";
		for (var e : transitionExecutionEntries) {
			result += String.format("%dx%s: %d transitions\n", e.getKey(), " ".repeat(6 - e.getKey().toString().length()), e.getValue());
		}
		
		return result;
	}
}
