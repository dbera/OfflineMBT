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
package nl.esi.comma.scenarios.generator.impactanalysis

import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.ImpactedTest
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.RegressionTest
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.Meta
import java.util.List
import java.time.LocalDateTime
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.ProgressionTest
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.StatisticsInfo
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.SelectionTest
import nl.esi.comma.scenarios.generator.impactanalysis.ImpactAnalysisReport.Config

class ImpactReportBuilder {
	var Meta meta = null
	var Config config = null
	val List<ImpactedTest> impactedTests = newArrayList
	val List<ProgressionTest> progressionTests = newArrayList
	val List<RegressionTest> regressionTests= newArrayList
	val StatisticsInfo statistics = new StatisticsInfo
	val List<SelectionTest> testSelectionOverview = newArrayList
	
	def ImpactReportBuilder withMeta(LocalDateTime createdAt, String taskName) {
		this.meta = new Meta(createdAt, taskName)
		return this
	}
	
	def ImpactReportBuilder withConfig(String configFP, String assemFP, String testFPPrefix, String defaultName){
		this.config = new Config(configFP, assemFP, testFPPrefix, defaultName)
		return this
	}
	
	def ImpactReportBuilder addSelectionTest(String config, List<String> SCNIds, String category) {
		testSelectionOverview.add(new SelectionTest(config, SCNIds, category))
		return this
	}
	
	def ImpactReportBuilder addImpactedTest(String scnID, List<String> configs, String filePath, List<String> reason) {
		impactedTests.add(new ImpactedTest(scnID, configs, filePath, reason))
		return this
	}
	
	def ImpactReportBuilder addRegressionTest(String scnID, List<String> configs, String filePath, List<String> reason) {
		regressionTests.add(new RegressionTest(scnID, configs, filePath, reason))
		return this
	}
	
	def ImpactReportBuilder addProgressionTest(String scnID, List<String> configs, String filePath, List<String> reason) {
		progressionTests.add(new ProgressionTest(scnID, configs, filePath, reason))
		return this
	}
	
	def ImpactReportBuilder addNumDefinedTestsAndConfigs(int numTests, int numConfigs, int numPairs, String buildTime){
		statistics.definedTests = numTests
		statistics.definedConfigurations = numConfigs
		statistics.definedTestConfigPairs = numPairs
		statistics.estBuildTimeDefined = buildTime
		return this
	}
	
	def ImpactReportBuilder addNumSelectedTestsAndConfig(int numTests, int numConfigs, int numPairs, String buildTime){
		statistics.selectedTests = numTests
		statistics.selectedConfigurations = numConfigs
		statistics.selectedTestConfigPairs = numPairs
		statistics.estBuildTimeSelected = buildTime
		return this
	}
	
	def ImpactAnalysisReport build() {
		if (meta === null) {
			meta = new Meta(LocalDateTime.now, "demo")
		}
		if (config === null){
			config = new Config("","","","")
		}
		
		return new ImpactAnalysisReport(meta, config, statistics, impactedTests, progressionTests, regressionTests, testSelectionOverview)
	}
}