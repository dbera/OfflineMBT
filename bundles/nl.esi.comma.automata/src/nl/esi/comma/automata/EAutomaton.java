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

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import dk.brics.automaton.Automaton;
import dk.brics.automaton.RegExp;
import dk.brics.automaton.State;
import nl.esi.comma.automata.internal.Macros;
import nl.esi.comma.automata.internal.Path;
import nl.esi.comma.automata.internal.PathsComputerDfsBfs;
import nl.esi.comma.automata.internal.PathsComputerPrefixSuffix;
import nl.esi.comma.automata.internal.ScenarioAligner;
import nl.esi.comma.automata.internal.SequenceComputer;
import nl.esi.comma.automata.internal.Transition;

public class EAutomaton {
	private Automaton automaton;
	private Macros macros = new Macros();

	public EAutomaton() {
	}

	public EAutomaton(Automaton automaton) {
		this.automaton = automaton;
	}

	public void addMacro(char c, char[] chars) {
		macros.add(c, chars);
	}

	public void addRegexes(List<String> regexes) {
		regexes.forEach(r -> addRegex(r));
	}

	public ScenarioComputeResult computeScenarios(AlgorithmType algorithmType, int k, List<Character> skipCharacters,
			boolean skipDuplicateSelfLoop, boolean skipSelfLoop, Integer timeout) {
		return computeScenarios(algorithmType, new ArrayList<>(), k, skipCharacters, skipDuplicateSelfLoop, skipSelfLoop, timeout);
	}

	public ScenarioComputeResult computeScenarios(AlgorithmType algorithmType, List<String> existingScenarios, int k,
			List<Character> skipCharacters, boolean skipDuplicateSelfLoop, boolean skipSelfLoop, Integer timeout) {
		Future<ScenarioComputeResult> future;
		var executor = Executors.newSingleThreadExecutor();
		ScenarioComputeResult result = null;
		final String[] stage = { "Start" };
		try {
			future = executor.submit(() -> {
				return computeScenariosInternal(algorithmType, existingScenarios, k, skipCharacters, skipDuplicateSelfLoop,
						skipSelfLoop, (String s) -> stage[0] = s);
			});
			result = timeout != null ? future.get(timeout, TimeUnit.SECONDS) : future.get();
		} catch (TimeoutException e) {
			result = new ScenarioComputeResult(new ArrayList<String>(), new ArrayList<Path>(), automaton, algorithmType,
					new ArrayList<AlignResult>(), String.format("Timeout at stage: %s", stage[0]));
		} catch (Exception e) {
			e.printStackTrace();
			result = new ScenarioComputeResult(new ArrayList<String>(), new ArrayList<Path>(), automaton, algorithmType,
					new ArrayList<AlignResult>(), String.format("Error at stage: %s: %s", stage[0], e.getMessage()));
		}
		
		return result;
	}

	public ScenarioComputeResult computeScenariosInternal(AlgorithmType algorithmType, List<String> existingScenarios,
			int k, List<Character> skipCharacters, boolean skipDuplicateSelfLoop, boolean skipSelfLoop, Consumer<String> stageChanged) {
		stageChanged.accept("MacroCheck");
		for (Character c : skipCharacters) {
			if (macros.has(c))
				throw new RuntimeException("Skip characters are not allowed to be macros, '" + c + "' is a macro.");
		}

		List<Path> paths = null;
		if (algorithmType == AlgorithmType.BFS || algorithmType == AlgorithmType.DFS) {
			paths = PathsComputerDfsBfs.compute(automaton, algorithmType, skipCharacters, skipSelfLoop,
					(String s) -> stageChanged.accept("PathsComputerDfsBfs:" + s));
		} else {
			var minimize = algorithmType == AlgorithmType.PREFIX_SUFFIX_MINIMIZED
					|| algorithmType == AlgorithmType.PREFIX_MINIMIZED;
			var suffix = algorithmType == AlgorithmType.PREFIX_SUFFIX
					|| algorithmType == AlgorithmType.PREFIX_SUFFIX_MINIMIZED;
			paths = PathsComputerPrefixSuffix.compute(automaton, suffix, minimize, skipCharacters, skipSelfLoop,
					(String s) -> stageChanged.accept("PathsComputerPrefixSuffix:" + s));
		}

		// Remove already existing scenarios; a path is skipped when all of its
		// transitions are already covered
		stageChanged.accept("AlignScenarios");
		var aligned = alignScenarios(existingScenarios);
		var coveredTransitions = aligned.stream().map(r -> r.path.transitions).flatMap(List::stream)
				.collect(Collectors.toSet());
		paths = paths.stream().filter(p -> p.transitions.stream().anyMatch(t -> !coveredTransitions.contains(t)))
				.collect(Collectors.toList());

		stageChanged.accept("ComputeScenarios");
		var scenarios = SequenceComputer.compute(macros, paths, k, skipCharacters, skipDuplicateSelfLoop);

		// Sort
		stageChanged.accept("SortScenarios");
		scenarios.sort((a, b) -> a.length() == b.length() ? a.compareTo(b) : a.length() - b.length());

		stageChanged.accept("CreateScenarioComputeResult");
		var result = new ScenarioComputeResult(scenarios, paths, automaton, algorithmType, aligned, null);
		return result;
	}

	public AlignResult alignScenario(String scenario) {
		return ScenarioAligner.align(automaton, macros, scenario);
	}

	public List<AlignResult> alignScenarios(List<String> scenarios) {
		return scenarios.stream().map(s -> alignScenario(s)).collect(Collectors.toList());
	}

	public CoverageResult calculateCoverage(List<AlignResult> alignResults) {
		var allTransitions = automaton.getNumberOfTransitions();
		var allStates = this.automaton.getStates().size();
		var coveredStates = new HashSet<State>();
		var coveredTransitions = new HashSet<Transition>();
		alignResults.forEach(a -> {
			if (!a.path.transitions.isEmpty()) {
				coveredStates.add(a.path.getSource());
				a.path.transitions.forEach(t -> {
					coveredTransitions.add(t);
					coveredStates.add(t.target);
				});
			}
		});

		var stateCoverage = coveredStates.size() / (double) allStates;
		var transitionCoverage = coveredTransitions.size() / (double) allTransitions;
		return new CoverageResult(stateCoverage, transitionCoverage);
	}

	public void addRegex(String regex) {
		var fa = new RegExp(regex).toAutomaton();
		if (automaton == null) {
			automaton = fa;
		} else {
			automaton = automaton.intersection(fa);
		}
	}

	public String toDot() {
		return automaton.toDot();
	}

	public List<String> expandChar(char c) {
		return macros.expand(c);
	}
}
