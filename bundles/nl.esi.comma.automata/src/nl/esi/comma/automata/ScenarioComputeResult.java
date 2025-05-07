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
package nl.esi.comma.automata;

import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.State;
import nl.esi.comma.automata.internal.Path;
import nl.esi.comma.automata.internal.Transition;

public class ScenarioComputeResult {
	public final List<String> scenarios;

	public final String statistics;	
	public final AlgorithmType algorithm;
	
	public final String error;
	
	// Statistics
	public final int amountOfStatesInAutomaton;
	public final int amountOfTransitionsInAutomaton;
	public final int amountOfTransitionsCoveredByExistingScenarios;
	public final int amountOfPaths;
	public final int amountOfSteps;
	public final double percentageTransitionsCoveredByExistingScenarios;
	public final double averageAmountOfStepsPerSequence;
	public final double percentageOfStatesCovered;
	public final double percentageOfTransitionsCovered;
	public final double averageTransitionExecution;
	public final Map<Integer, List<Transition>> timesTransitionIsExecuted; // Key = times executed

	ScenarioComputeResult(List<String> scenarios, List<Path> paths, Automaton automaton, AlgorithmType algorithm, List<AlignResult> existingScenarios, 
			String error) {
		this.scenarios = scenarios;
		this.algorithm = algorithm;
		
		this.error = error;
		
		// Compute statistics
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
		var transitionExecution = coveredTransitions.keySet().stream().collect(Collectors.groupingBy(k -> coveredTransitions.get(k)))
				.entrySet().stream().collect(Collectors.toList()).stream().sorted((a, b) -> b.getKey() - a.getKey()).collect(Collectors.toList());

		// Set statistics
		amountOfStatesInAutomaton = automaton.getStates().size();
		amountOfTransitionsInAutomaton = automaton.getNumberOfTransitions();
		amountOfTransitionsCoveredByExistingScenarios = existingScenarios.stream().map(r -> r.path.transitions)
				.flatMap(List::stream).collect(Collectors.toSet()).size();
		amountOfPaths = paths.size();
		amountOfSteps = steps;
		percentageTransitionsCoveredByExistingScenarios = (amountOfTransitionsCoveredByExistingScenarios / (double) amountOfTransitionsInAutomaton);
		averageAmountOfStepsPerSequence = (double) amountOfSteps / amountOfPaths;
		percentageOfStatesCovered = (coveredStates.size() / (double) amountOfStatesInAutomaton);
		percentageOfTransitionsCovered = (coveredTransitions.size() / (double) amountOfTransitionsInAutomaton);
		averageTransitionExecution = coveredTransitions.size() > 0 ? 
				coveredTransitions.values().stream().mapToDouble(i -> i).average().getAsDouble() : 0;
		timesTransitionIsExecuted = new LinkedHashMap<>();
		for (var entry : transitionExecution) timesTransitionIsExecuted.put(entry.getKey(), entry.getValue());
		
		this.statistics = getStatistics();
	}
	
	private String getStatistics() {
		var result = "";
		if (error != null) {
			result += String.format("ERROR occurred: %s", error);
		}
		result += String.format("Algorithm: %s\n", algorithm.toString());
		result += String.format("Transitions in automaton: %d\n", amountOfTransitionsInAutomaton);
		result += String.format(Locale.US, "Transitions covered by existing testcases: %.2f%%\n", percentageTransitionsCoveredByExistingScenarios * 100);
		result += String.format("States in automaton: %d\n", amountOfStatesInAutomaton);
		result += String.format("Sequences: %d\n", amountOfPaths);
		result += String.format("Steps: %d\n", amountOfSteps);
		result += String.format(Locale.US, "Average steps per sequence: %.2f\n", averageAmountOfStepsPerSequence);
		result += String.format(Locale.US, "State coverage: %.2f%%\n", percentageOfStatesCovered * 100);
		result += String.format(Locale.US, "Transition coverage: %.2f%%\n", percentageOfTransitionsCovered * 100);
		result += String.format(Locale.US, "Average transition execution: %.2f\n", averageTransitionExecution);
		result += "\nTimes transitions are executed:\n";
		for (var e : timesTransitionIsExecuted.entrySet()) {
			result += String.format("%dx%s: %d transitions\n", e.getKey(), " ".repeat(6 - e.getKey().toString().length()), e.getValue().size());
		}
		return result;
	}
}
