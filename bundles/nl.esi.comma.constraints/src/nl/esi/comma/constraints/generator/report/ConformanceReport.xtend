/**
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
package nl.esi.comma.constraints.generator.report

import java.util.ArrayList
import nl.esi.comma.constraints.generator.report.Reports
import java.util.List
import com.google.gson.annotations.Expose
import java.io.FileInputStream
import java.io.InputStreamReader
import java.io.BufferedReader
import java.util.stream.Collectors
import java.util.Base64
import java.util.Map
import java.util.HashMap

class ConformanceReport {
	static class ConformanceResults {
		@Expose
    	public var constraintName = new String
    	
    	@Expose
    	public var constraintText = new ArrayList<String>
    	
    	@Expose
    	public var constraintDot = new String
    	
    	@Expose
    	public var numberOfConformingSCN = 0
    	
    	@Expose
    	public var testCoverage = 0.0
    	
    	@Expose
    	public var stateCoverage = 0.0
    	
    	@Expose
    	public var transitionCoverage = 0.0
    	
    	@Expose
    	public var listOfConformingScenarios = new ArrayList<ConformingScenarios>
    	
    	@Expose
    	public var listOfViolatingScenarios = new ArrayList<ViolatingScenarios>
    
	    new(String constraintName, int numberOfConformingSCN, double coverage) {
	    	this.constraintName = constraintName
	    	this.numberOfConformingSCN = numberOfConformingSCN
	    	this.testCoverage = coverage
	    }
	    
	    // constructor only called by report builder
	    new(String constraintName, List<String> Text, String dot, int numberOfConformingSCN, double testCov, double stateCov, double transitionCov){
	    	this.constraintName = constraintName
	    	for(elm : Text) constraintText.add(elm) 
	    	this.constraintDot = Base64.getEncoder().encodeToString(dot.bytes)
	    	this.numberOfConformingSCN = numberOfConformingSCN
	    	this.testCoverage = testCov
	    	this.stateCoverage = stateCov
	    	this.transitionCoverage = transitionCov
	    }
	    def getConstraintName() { return constraintName }
	    def getConstraintText() { return constraintText}
	    def getConstraintDot() { return constraintDot }
	    def getNumberOfConformainfSCN() { return numberOfConformingSCN }
	    def getTestCoverage() { return testCoverage }
	    def getStateCoverage() { return stateCoverage }
	    def getTransitionCoverage() { return transitionCoverage }
	    def getListOfConformingScenarios() { return listOfConformingScenarios }
	    def getListOfViolatingScenarios() { return listOfViolatingScenarios }
	    
	    def setConstraintName(String cname) { constraintName = cname}
	    def setConstraintText(ArrayList<String> text) {constraintText = text}
	    def setConstraintDot(String dot) { constraintDot = dot}
	    def setNumberOfConformingSCN(int n) { numberOfConformingSCN = n}
	    def setTestCoverage(double n) { testCoverage = n}
	    def setStateCoverage(double n) { stateCoverage = n}
	    def setTransitionCoverage(double n) { transitionCoverage = n}
	    def addListOfConformingScenarios(String name, String location, ArrayList<String> cScenario) { 
	        var cscn = new ConformingScenarios(name,location,cScenario)
	        listOfConformingScenarios.add(cscn)
	    }
	    /* new extensions */
	    def addListOfConformingScenarios(String name, ArrayList<String> configruations, String location, ArrayList<String> cScenario,
	    	ArrayList<String> highlightedKeywords
	    ) { 
	        var cscn = new ConformingScenarios(name, configruations, location,cScenario,highlightedKeywords)
	        listOfConformingScenarios.add(cscn)
	    }
	    def addListOfViolatingScenarios(String name, String location, ArrayList<String> violatingScenario, ArrayList<String> violatingAction) { 
	         var vscn = new ViolatingScenarios(name,location, violatingScenario, violatingAction)
	        listOfViolatingScenarios.add(vscn)
	    }
	    /* new extensions */
	    def addListOfViolatingScenarios(String name, ArrayList<String> configruations, String location, ArrayList<String> violatingScenario, 
	    	ArrayList<String> violatingAction, ArrayList<String> highlightedKeywords
	    ) { 
	         var vscn = new ViolatingScenarios(name, configruations, location, violatingScenario, violatingAction, highlightedKeywords)
	        listOfViolatingScenarios.add(vscn)
	    }
	}
	
	static class ConformingScenarios {
		@Expose
	    public var scenarioName = new String
	    
	    @Expose
	    public var configurations = new ArrayList<String>
	    
	    @Expose
	    public var featureFileLocation = new String
	    
	    @Expose
	    public var conformingScenario = new ArrayList<String>
	    
	    @Expose
	    public var highlightedKeywords = new ArrayList<String>
	    
	    @Expose
	    public var String featureContent
	    
	    new(String name, String path, ArrayList<String> cScenario) {
	        scenarioName = name
	        featureFileLocation = path
	        conformingScenario = cScenario
	        var is = new FileInputStream(featureFileLocation)
            var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
            this.featureContent = Base64.getEncoder().encodeToString(content.bytes)
            this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
	    }
	    
	    new(String name, ArrayList<String> configs, String path, ArrayList<String> cScenario, ArrayList<String> highlighted) {
	        scenarioName = name
	        for(elm : configs) this.configurations.add(elm)
	        featureFileLocation = path
	        conformingScenario = cScenario
	        for(elm : highlighted) this.highlightedKeywords.add(elm)
	        var is = new FileInputStream(featureFileLocation)
            var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
            this.featureContent = Base64.getEncoder().encodeToString(content.bytes)
            this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
	    }
	    
	    def getScenarioName() { return scenarioName }
	    def getConfigurations() { return configurations}
	    def getFeatureFileLocation() { return featureFileLocation }
	    def getConformingScenario() { return conformingScenario }
	    def getHighlightedKeywords() { return highlightedKeywords }
	}
	
	static class ViolatingScenarios {
	    @Expose
	    public var scenarioName = new String
	    @Expose
	    public var configurations = new ArrayList<String>
	    @Expose
	    public var featureFileLocation = new String
	    @Expose
	    public var violatingScenario = new ArrayList<String>
	    @Expose
	    public var violatingAction = new ArrayList<String>
	    @Expose
	    public var highlightedKeywords = new ArrayList<String>
	    @Expose
	    public var String featureContent
	    
	    new(String name, String location, ArrayList<String> vScenario, ArrayList<String> vAction) {
	        scenarioName = name
	        featureFileLocation = location
	        violatingScenario = vScenario
	        violatingAction = vAction
	        var is = new FileInputStream(featureFileLocation)
            var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
            this.featureContent = Base64.getEncoder().encodeToString(content.bytes)
            this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
	    }
	    /* new extensions */
	    new(String name, ArrayList<String> configs, String location, ArrayList<String> vScenario, ArrayList<String> vAction,
	    	ArrayList<String> highlighted
	    ) {
	        scenarioName = name
	        for(elm : configs) this.configurations.add(elm)
	        featureFileLocation = location
	        violatingScenario = vScenario
	        violatingAction = vAction
	        for(elm : highlighted) this.highlightedKeywords.add(elm)
	        var is = new FileInputStream(featureFileLocation)
            var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
            this.featureContent = Base64.getEncoder().encodeToString(content.bytes)
            this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
	    }
	    
	    def getScenarioName() { return scenarioName }
	    def getConfigurations() { return configurations}
	    def getFeatureFileLocation() { return featureFileLocation }
	    def getViolatingScenario() { return violatingScenario }
	    def getViolatingAction() { return violatingAction }
	    def getHighlightedKeywords() { return highlightedKeywords }
	}
	
	static class TestGeneration {
		@Expose
		public var constraintName = new String

		@Expose
		public var constraintText = new ArrayList<String>

		@Expose
		public var constraintDot = new String
		
		@Expose
		public var configurations = new ArrayList<String>
		
		@Expose
		public var featureFileLocation = new String
		
		@Expose
		public Statistics statistics
		
		@Expose
		public String statisticsString = new String //deprecated
		
		@Expose
		public List<Similarity> similarities = newArrayList
		
		new(String name, ArrayList<String> text, ArrayList<String> configs, String location, Statistics stats, List<Similarity> sims){
			this.constraintName = name
			for(elm : text) this.constraintText.add(elm)
			for(elm : configs) this.configurations.add(elm)
			featureFileLocation = location
			this.statistics = stats
			for (sim :sims){similarities.add(sim)}
		}
		
		new(String name, ArrayList<String> text, String dot, ArrayList<String> configs, String location, Statistics stats, List<Similarity> sims){
			this.constraintName = name
			for(elm : text) this.constraintText.add(elm)
			this.constraintDot = Base64.getEncoder().encodeToString(dot.bytes)
			for(elm : configs) this.configurations.add(elm)
			featureFileLocation = location
			this.statistics = stats
			for (sim :sims){similarities.add(sim)}
		}
		
		new(String name, ArrayList<String> text, String dot, ArrayList<String> configs, String location, String stats){
			this.constraintName = name
			for(elm : text) this.constraintText.add(elm)
			this.constraintDot = Base64.getEncoder().encodeToString(dot.bytes)
			for(elm : configs) this.configurations.add(elm)
			featureFileLocation = location
			this.statisticsString = stats
		}
	}
	
	static class Statistics {
		@Expose
		public var String algorithm
		@Expose
		public var int amountOfStatesInAutomaton
		@Expose
		public var int amountOfTransitionsInAutomaton
		@Expose
		public var int amountOfPaths
		@Expose
		public var int amountOfSteps
		@Expose
		public var double percentageTransitionsCoveredByExistingScenarios
		@Expose
		public var double averageAmountOfStepsPerSequence
		@Expose
		public var double percentageOfStatesCovered
		@Expose
		public var double percentageOfTransitionsCovered
		@Expose
		public var double averageTransitionExecution
		@Expose
		public var Map<Integer, List<String>> timesTransitionIsExecuted = new HashMap<Integer, List<String>>
		
		new(String alg, int states, int transitions, int paths, int steps, double coveredPercentage,
			double averageSteps, double percentageStatesCovered, double percentageTransitionCovered, double averageTransition,
			Map<Integer, List<String>> times
		){
			this.algorithm = alg
			this.amountOfStatesInAutomaton = states
			this.amountOfTransitionsInAutomaton = transitions
			this.amountOfPaths = paths
			this.amountOfSteps = steps
			this.percentageTransitionsCoveredByExistingScenarios = coveredPercentage * 100
			this.averageAmountOfStepsPerSequence = averageSteps
			this.percentageOfStatesCovered = percentageStatesCovered * 100
			this.percentageOfTransitionsCovered = percentageTransitionCovered * 100
			this.averageTransitionExecution = averageTransition
			if (!times.keySet.nullOrEmpty) {
				for(k : times.keySet) {
					var value = times.get(k)
					if (this.timesTransitionIsExecuted.get(k) === null) {
						this.timesTransitionIsExecuted.put(k, value)
					} else {
						this.timesTransitionIsExecuted.get(k).addAll(value)
					}
				}
			}
		}
	}
	
	static class Similarity {
		@Expose
		public var String existingTest
		
		@Expose
		public var List<SimScore> simScores = newArrayList
		
		new (String extTest, List<SimScore> scores){
			this.existingTest = extTest
			for (s : scores){ simScores.add(s)}
		}
	}
	
	static class SimScore {
		@Expose
		public var String newTestId
		
		@Expose
		public var double jaccardIndex
		
		@Expose
		public var double normalizedEditDistance
		
		new (String newId, double jaccardIdx, double distance){
			this.newTestId = newId
			this.jaccardIndex = jaccardIdx
			this.normalizedEditDistance = distance
		}
	}
	
	@Expose
    public val List<ConformanceResults> conformanceResults
    
    @Expose
    public val List<TestGeneration> testGenerations
    
    new(List<ConformanceResults> conformanceResults, List<TestGeneration> testGenerations) {
    	if (conformanceResults === null){
			this.conformanceResults = new ArrayList<ConformanceResults>
		} else {
			this.conformanceResults = conformanceResults
		}
		if (testGenerations === null){
			this.testGenerations = new ArrayList<TestGeneration>
		} else {
			this.testGenerations = testGenerations
		}
    }

    def String toJson() {
		return Reports.toJson(this)
	}
}