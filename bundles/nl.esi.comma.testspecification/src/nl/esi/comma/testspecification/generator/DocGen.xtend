package nl.esi.comma.testspecification.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.List

class DocGen 
{
	def getStep(ArrayList<Step> listStepInstances, String name) {
		for(elm : listStepInstances) {
			if(elm.id.equals(name)) return elm
		}
	}
	
	def generateMDFile(TestSpecificationInstance tsInst, 
		HashMap<String, String> mapStepToInputData,
		ConcreteSUTHandler _sutHandler, 
		List<String> featureList,
		String configName
	) {
		var txt = ''''''
		txt +=
		'''
		# «tsInst.title»
		
		# Purpose
		> «tsInst.testpurpose»
		
		# Background
		> «tsInst.background»
		
		# Stakeholders
		|Name|Function|Comments|
		|--|--|--|
		«FOR stk: tsInst.stakeholders»
			|«stk»|
		«ENDFOR»
		
		# Variants
		«FOR feature : featureList»
			## «_sutHandler.vartosutMap.get(feature)»
			«FOR sutTxt : _sutHandler.concreteSUTMap.get(_sutHandler.vartosutMap.get(feature))»
				«sutTxt»
			«ENDFOR»
		«ENDFOR»
			
		# Flow
		![«configName»_Flow](«configName».svg)
		
		# Input Data
		«FOR k : mapStepToInputData.keySet»
			## «k»
			```json 
			«FOR elm : mapStepToInputData.get(k).split(" ,")»
				«elm»
			«ENDFOR»
			```
		«ENDFOR»
		'''
		return txt
	}
	
	def generatePlantUMLFile(
		ArrayList<Step> listStepInstances, 
		HashMap<String, List<String>> mapStepSeqToSteps
	) {
		var txt = ''''''
		var idx = 0
		
		txt +=
		'''
		@startuml
		«IF mapStepSeqToSteps.isEmpty»
			«FOR step : listStepInstances»
				component «step.id» <<«step.type»>>
			«ENDFOR»
		«ELSE»
			«FOR step_seq : mapStepSeqToSteps.keySet»
				package "«step_seq»" {
				«FOR step : mapStepSeqToSteps.get(step_seq)»
					[«step»] <<«getStep(listStepInstances,step).type»>>
				«ENDFOR»
				}
			«ENDFOR»
		«ENDIF»
		«FOR step : listStepInstances»
			«IF idx < listStepInstances.size-1»
				[«listStepInstances.get(idx).id»] --> [«listStepInstances.get(idx+1).id»]
				«{idx++ ""}»
			«ENDIF»
		«ENDFOR»
		«FOR step : listStepInstances»
			«FOR param : step.parameters»
				«FOR k : param.refKey»
					[«k»] <.. [«step.id»]
				«ENDFOR»
			«ENDFOR»
		«ENDFOR»
		«FOR step : listStepInstances»
			«FOR param : step.parameters»
				«IF param.refKey.size > 0»
					note right of «step.id»
					«FOR elm : param.refVal»
						«FOR e : elm.split(" ,")»
							«e»
						«ENDFOR»
					«ENDFOR»
					end note
				«ENDIF»
			«ENDFOR»
		«ENDFOR»
		@enduml
		'''
		
		return txt
	}
}

// : «FOR elm : param.refVal»«elm»«ENDFOR»