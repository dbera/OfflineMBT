package nl.esi.comma.constraints.generator.report

import java.util.ArrayList
import java.util.List
import nl.esi.comma.constraints.generator.report.ConformanceReport.ConformanceResults
import nl.esi.comma.constraints.generator.report.ConformanceReport.TestGeneration
import nl.esi.comma.constraints.generator.report.ConformanceReport.Statistics
import nl.esi.comma.constraints.generator.report.ConformanceReport.Similarity

class ConformanceReportBuilder {
	val List<ConformanceResults> results = newArrayList
	val List<TestGeneration> testGenerations = newArrayList
	
	def ConformanceReportBuilder addConformanceResult(String constraintName, String dot, int numScn, double coverage){
		var cr = new ConformanceResults(constraintName, numScn, coverage)
		cr.constraintDot = dot
		results.add(cr)
		return this
	}
	
	/* new extension */
	def ConformanceReportBuilder addConformanceResult(String constraintName, ArrayList<String> constraintText, String dot, int numScn, double testCov, double stateCov, double transitionCov){
		var cr = new ConformanceResults(constraintName, constraintText, dot, numScn, testCov, stateCov, transitionCov)
		results.add(cr)
		return this
	}
	
	def ConformanceReportBuilder addConformingScenario(String constraintName, String name, String location, ArrayList<String> cScenario){
		for(result : results){
			if (result.constraintName.equals(constraintName)){
				result.addListOfConformingScenarios(name, location, cScenario)
			}
		}
		return this
	}
	
	/* new table with extension */
	def ConformanceReportBuilder addConformingScenario(String constraintName, String name, ArrayList<String> configurations, 
		String location, ArrayList<String> cScenario, ArrayList<String> highlightedKeywords
	){
		for(result : results){
			if (result.constraintName.equals(constraintName)){
				result.addListOfConformingScenarios(name, configurations, location, cScenario, highlightedKeywords)
			}
		}
		return this
	}
	
	def ConformanceReportBuilder addViolatingScenario(String constraintName, String name, String location, ArrayList<String> violatingScenario, ArrayList<String> violatingAction){
		for(result : results){
			if (result.constraintName.equals(constraintName)){
				result.addListOfViolatingScenarios(name, location, violatingScenario, violatingAction)
			}
		}
		return this
	}
	
	/* new table with extension */
	def ConformanceReportBuilder addViolatingScenario(String constraintName, String name, ArrayList<String> configurations,
		String location, ArrayList<String> violatingScenario, ArrayList<String> violatingAction, ArrayList<String> highlightedKeywords
	){
		for(result : results){
			if (result.constraintName.equals(constraintName)){
				result.addListOfViolatingScenarios(name, configurations, location, violatingScenario, violatingAction, highlightedKeywords)
			}
		}
		return this
	}
	
	def ConformanceReportBuilder addTestGenerationInfo(String constraintName, ArrayList<String> text, String dot, ArrayList<String> configurations, 
		String location, Statistics stats, List<Similarity> sims
	){
		var testGeneration = new TestGeneration(constraintName, text, configurations, location, stats, sims)
		//dot is already encoded, so assign it directly
		testGeneration.constraintDot = dot
		testGenerations.add(testGeneration)
		return this
	}
	
	def ConformanceReport build(){
		return new ConformanceReport(results, testGenerations)
	}
}