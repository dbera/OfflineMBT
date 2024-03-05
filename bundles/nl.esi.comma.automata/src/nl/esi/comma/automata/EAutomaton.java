package nl.esi.comma.automata;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
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
	
	public ScenarioComputeResult computeScenarios(AlgorithmType algorithmType) {
		return computeScenarios(algorithmType, new ArrayList<>(), 1);
	}
	
	public ScenarioComputeResult computeScenarios(AlgorithmType algorithmType, List<String> existingScenarios, int k) {
		List<Path> paths = null;
		var minimize = algorithmType == AlgorithmType.PREFIX_SUFFIX_MINIMIZED;
		if (algorithmType == AlgorithmType.BFS || algorithmType == AlgorithmType.DFS) {
			paths = PathsComputerDfsBfs.compute(automaton, algorithmType);
		} else if (algorithmType == AlgorithmType.PREFIX_SUFFIX || 
				algorithmType == AlgorithmType.PREFIX_SUFFIX_MINIMIZED) {
			paths = PathsComputerPrefixSuffix.compute(automaton, minimize);
		}
		
		// Remove already existing scenarios; a path is skipped when all of its transitions are already covered
		var aligned = alignScenarios(existingScenarios);
		var coveredTransitions = aligned.stream().map(r -> r.path.transitions)
			.flatMap(List::stream).collect(Collectors.toSet());
		paths = paths.stream().filter(p -> p.transitions.stream().anyMatch(t -> !coveredTransitions.contains(t)))
			.collect(Collectors.toList());
		
		// var k = 1;
		var scenarios = SequenceComputer.compute(macros, paths, minimize, k);
		 	
		return new ScenarioComputeResult(scenarios, paths, automaton, algorithmType, aligned);
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
