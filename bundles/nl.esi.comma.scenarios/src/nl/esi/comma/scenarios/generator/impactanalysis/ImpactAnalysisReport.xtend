package nl.esi.comma.scenarios.generator.impactanalysis

import com.google.gson.annotations.Expose
import java.time.LocalDateTime
import java.util.List
import java.util.Objects
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.stream.Collectors
import java.io.FileInputStream
import java.util.Base64
import java.util.ArrayList

class ImpactAnalysisReport {
	static val regex = "((?=((@[^\n@]*(\n|\\s)*)*)(?=(Scenario:|Scenario Outline:))))"
	static class Meta {
		@Expose
		public val LocalDateTime createdAt
		
		@Expose
		public val String taskName

		new(LocalDateTime createdAt, String taskName) {
			this.createdAt = createdAt
			this.taskName = taskName
		}
	}
	
	static class Config {
		@Expose
		public val String configFilePath
		@Expose
		public val String assemblyFilePath
		@Expose
		public val String testFilePathPrefix
		@Expose
		public val String defaultConfigName
		
		new(String configFP, String assemFP, String testFPPrefix, String defaultName){
			this.configFilePath = configFP
			this.assemblyFilePath = assemFP
			this.testFilePathPrefix = testFPPrefix
			this.defaultConfigName = defaultName
		}
	}
	
	static class ImpactedTest {
		@Expose
		public val String scnID //scn name
		
		@Expose
		public val List<String> configs
		
		@Expose
		public val String filePath
		
		@Expose
		public var String featureContent
		
		@Expose
		public val List<String> reason
		
		new(String scnID, List<String> configs, String filePath, List<String> reason) {
			this.scnID = scnID
			this.configs = configs
			this.filePath = filePath
			if(!filePath.equals("")){
				var is = new FileInputStream(filePath)
				var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
				var result = ImpactAnalysisReport.getScenarioText(content, scnID)
            	this.featureContent = Base64.getEncoder().encodeToString(result.bytes)
            	this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
			} else {
				this.featureContent = ""
			}
			this.reason = reason
		}
	}
	static class ProgressionTest {
		@Expose
		public val String scnID
		
		@Expose
		public val List<String> configs
		
		@Expose
		public val String filePath
		
		@Expose
		public var String featureContent
		
		@Expose
		public val List<String> reason
		
		new(String scnID, List<String> configs, String filePath, List<String> reason) {
			this.scnID = scnID
			this.configs = configs
			this.filePath = filePath
			if(!filePath.equals("")){
				var is = new FileInputStream(filePath)
				var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
				var result = ImpactAnalysisReport.getScenarioText(content, scnID)
            	this.featureContent = Base64.getEncoder().encodeToString(result.bytes)
            	this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
			} else {
				this.featureContent = ""
			}
			this.reason = reason
		}
	}
	static class RegressionTest {
		@Expose
		public val String scnID
		
		@Expose
		public val List<String> configs
		
		@Expose
		public val String filePath

        @Expose
        public var String featureContent
		
		@Expose
		public val List<String> reason
		
		new(String scnID, List<String> configs, String filePath, List<String> reason) {
			this.scnID = scnID
			this.configs = configs
			this.filePath = filePath
			if(!filePath.equals("")){
				var is = new FileInputStream(filePath)
            	var content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"))
            	var result = ImpactAnalysisReport.getScenarioText(content, scnID)
            	this.featureContent = Base64.getEncoder().encodeToString(result.bytes)
            	this.featureContent = this.featureContent.replaceAll('[\u003d]', "")
			} else {
				this.featureContent = ""
			}
			this.reason = reason
		}
	}
	static class StatisticsInfo {
		@Expose
		public int definedTests
		
		@Expose
		public int definedConfigurations
		
		@Expose
		public int definedTestConfigPairs
		
		@Expose
		public String estBuildTimeDefined
		
		@Expose
		public int selectedTests
		
		@Expose
		public int selectedConfigurations
		
		@Expose
		public int selectedTestConfigPairs
		
		@Expose
		public String estBuildTimeSelected
		
		new(){
			this.definedTests = 0
			this.definedConfigurations = 0
			this.definedTestConfigPairs = 0
			this.estBuildTimeDefined = ""
			this.selectedTests = 0
			this.selectedConfigurations = 0
			this.selectedTestConfigPairs = 0
			this.estBuildTimeSelected = ""
		}
		
		new(int definedTests, int definedConfigurations, int definedTestConfigPairs, String estBuildTimeDefined,
			int selectedTests, int selectedConfigurations, int selectedTestConfigPairs, String estBuildTimeSelected){
			this.definedTests = definedTests
			this.definedConfigurations = definedConfigurations
			this.definedTestConfigPairs = definedTestConfigPairs
			this.estBuildTimeDefined = estBuildTimeDefined
			this.selectedTests = selectedTests
			this.selectedConfigurations = selectedConfigurations
			this.selectedTestConfigPairs = selectedTestConfigPairs
			this.estBuildTimeSelected = estBuildTimeSelected
		}
	}
	static class SelectionTest {
		@Expose
		public val String config
		
		@Expose
		public val List<String> selectedTests
		
		@Expose
		public val String category
		
		new(String config, List<String> selectedTests, String category){
			this.config = config
			this.selectedTests = selectedTests
			this.category = category
		}
	}
	
	@Expose
	public val Meta meta
	
	@Expose
	public val Config config
	
	@Expose
	public val StatisticsInfo statistics
	
	@Expose
	public val List<ImpactedTest> impactedTestSet
	
	@Expose
	public val List<ProgressionTest> progressionTestSet
	
	@Expose
	public val List<RegressionTest> regressionTestSet
	
	@Expose
	public val List<SelectionTest> testSelectionOverview
	
	new(Meta meta, Config config, StatisticsInfo statistics, List<ImpactedTest> impactedTestSet, List<ProgressionTest> progressionTestSet,
		List<RegressionTest> regressionTestSet, List<SelectionTest> testSelectionOverview) {
		this.meta = Objects.requireNonNull(meta, "meta must not be null")
		this.config = Objects.requireNonNull(config, "config must not be null")
		this.statistics = statistics
		if (impactedTestSet === null){
			this.impactedTestSet = new ArrayList<ImpactedTest>
		} else {
			this.impactedTestSet = impactedTestSet
		}
		if (progressionTestSet === null){
			this.progressionTestSet = new ArrayList<ProgressionTest>
		} else {
			this.progressionTestSet = progressionTestSet
		}
		if (regressionTestSet === null){
			this.regressionTestSet = new ArrayList<RegressionTest>
		} else {
			this.regressionTestSet = regressionTestSet
		}
		if (testSelectionOverview === null){
			this.testSelectionOverview = new ArrayList<SelectionTest>
		} else {
			this.testSelectionOverview = testSelectionOverview
		}
	}
	
	def String toJson() {
		return Reports.toJson(this)
	}
	
	def static getScenarioText(String content, String scnID) {
		var text = ""
		var tags = ""
		var result = content.split(regex)
		for(str : result){
			if (!str.contains("Feature:") && !str.contains("Narrative:")){
				if (str.startsWith("@")){
					tags += str
				}
				if (str.startsWith("Scenario:")||str.startsWith("Scenario Outline:")){
					var lines = str.split("\n")
					if (lines.get(0).equals(scnID)){
						text = tags + str
					} else {
						tags = ""
					}
				}
			}
		}
		return text
	}
}