package nl.esi.comma.constraints.generator;

import java.util.HashMap
import java.util.List
import java.util.Map
import nl.esi.comma.automata.AlgorithmType
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.generator.report.ConformanceReport.ConformanceResults
import nl.esi.comma.constraints.generator.report.ConformanceReportBuilder
import nl.esi.comma.constraints.generator.report.ReportWriter
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.steps.step.Steps
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IFileSystemAccessExtension2
import nl.esi.comma.constraints.generator.visualize.ConstraintsDependencyVizGenerator

class ConstraintsAnalysisAndGeneration 
{
	var Map<String, ConstraintStateMachine> mapContraintToAutomata = new HashMap<String, ConstraintStateMachine>
	var Map<String, String> stepsMapping = new HashMap<String, String>
	// var Map<String, ArrayList<String>> seqsMapping = new HashMap<String, ArrayList<String>>
	
	def generateStateMachine(Resource res, IFileSystemAccess2 fsa, 
	                         List<Constraints> constraints, 
	                         String taskName, 
	                         Scenarios scn, int numSCN, 
	                         boolean isVisualize, boolean isCoCo, 
	                         boolean isTestGen,
	                         AlgorithmType algorithm, int k, boolean skipAny, 
	                         boolean skipDuplicateSelfLoop, boolean skipSelfLoop, 
	                         Integer timeout, Integer similarity, boolean printConstraints) 
	{
		//System.out.println(" Number of Existing SCN: " + scn.specFlowScenarios.size)
		
		val String path = "\\Constraints\\"
		var reportBuilder = new ConformanceReportBuilder()
		
		var uri = fsa.getURI("./")
		var file = ResourcesPlugin.getWorkspace().getRoot().getFile(new Path(uri.toPlatformString(true)));
		var srcGenPath = file.getLocation().toOSString;			
		
		// Multiple constraint files not supported for now. TODO
		for(constraintsSource : constraints){
		    var stepModel = getStepModel(constraintsSource) 
            computeStepsMapping(stepModel)
            // computeSequenceMapping(constraintsSource)
			// fsa.generateFile(path + "constraints.decl", generateDeclareConstraints(constraintsSource, stepModel))
            mapContraintToAutomata = (new ConstraintsStateMachineGenerator()).generateStateMachine(constraintsSource, stepsMapping, srcGenPath + path, taskName, fsa, isVisualize, printConstraints)
            
            if(scn!==null && isCoCo) {
                // old implementation
                // var crSet = (new ComformanceChecker).checkConformance(scn, mapContraintToAutomata, stepsMapping, seqsMapping, fsa, path)
                var crSet = (new CoCoGenerator).checkConformanceAndCoverage(scn, mapContraintToAutomata, fsa, path)
                for(cr : crSet) {
                    var String sValue = String.format("%.4f", cr.testCoverage).toString
                    // var Double newValue = Double.parseDouble(sValue)
                    // reportBuilder.addConformanceResult(cr.constraintName, cr.numberOfConformainfSCN, newValue)
                    reportBuilder.addConformanceResult(cr.constraintName, cr.constraintText, cr.constraintDot, cr.numberOfConformainfSCN, cr.testCoverage, cr.stateCoverage, cr.transitionCoverage) // newValue)
                    // System.out.println("Constraint Text: " + cr.constraintText)
                    // System.out.println("Constraint Dot: " + cr.constraintDot)
                    var csList = cr.listOfConformingScenarios
                    // for(cs: csList) reportBuilder.addConformingScenario(cr.constraintName, cs.scenarioName, cs.featureFileLocation, cs.conformingScenario)
                    for(cs: csList) { 
                        reportBuilder.addConformingScenario(cr.constraintName, cs.scenarioName, 
                                                            cs.configurations, cs.featureFileLocation, 
                                                            cs.conformingScenario, cs.highlightedKeywords)
                        // System.out.println("Keywords: " + cs.highlightedKeywords)
                    } 
                    var vsList = cr.listOfViolatingScenarios
                    // for(vs: vsList) reportBuilder.addViolatingScenario(cr.constraintName, vs.scenarioName, vs.featureFileLocation, vs.violatingScenario, vs.violatingAction)
                    for(vs: vsList) reportBuilder.addViolatingScenario(cr.constraintName, vs.scenarioName, vs.configurations, vs.featureFileLocation, vs.violatingScenario, vs.violatingAction, vs.highlightedKeywords)
                }
                // (new ReportWriter(fsa, "..\\test-gen\\conformance-report.html")).write(reportBuilder.build())
            }
            // Generate Tests. 
            if(isTestGen) {
               /*(new ScenarioGenerator).generateTestScenarios(mapContraintToAutomata, stepModel, 
                                                constraintsSource,
                                                numSCN, getConfigurationTags(constraintsSource), 
                                                getRequirementTags(constraintsSource), getDescTxt(constraintsSource), fsa, path, taskName, algorithm, scn)*/

                var TGReport = (new TestGenerator).generateTestScenarios(mapContraintToAutomata, stepModel, 
                                                constraintsSource, numSCN, getDescTxt(constraintsSource), 
                                                fsa, path, taskName, algorithm, k, skipAny, skipDuplicateSelfLoop, skipSelfLoop, scn, timeout, similarity)
                                                
                for(rep : TGReport) {
                    reportBuilder.addTestGenerationInfo(rep.constraintName, rep.constraintText, 
                                                        rep.constraintDot, rep.configurations, 
                                                        rep.featureFileLocation, rep.statistics, rep.similarities)
                    reportBuilder.addConformanceResult(rep.constraintName, rep.constraintDot, 0, 0.0)
                }
            }
            
			if (!isTestGen && !isCoCo){
				for(constraint : mapContraintToAutomata.keySet) {
					var constraintSM = mapContraintToAutomata.get(constraint)
					var result = new ConformanceResults(constraintSM.name, constraintSM.constraintText, constraintSM.dot, 0, 0.0, 0.0, 0.0)
					reportBuilder.addConformanceResult(result.constraintName, result.constraintDot, 0, 0.0)
				}
			}
		}
		if(printConstraints){
			(new ConstraintsDependencyVizGenerator).generateViz(res, fsa, constraints, taskName)
		}
		(new ReportWriter(fsa, "..\\test-gen\\conformance-report.html")).write(reportBuilder.build())
	}
	
	def computeStepsMapping(Steps stepModel) {
		if (stepModel instanceof Steps && stepModel !== null) {
			for (act : stepModel.actionList.acts){
				stepsMapping.put(act.name, act.stepWithOutData.name)
			}
		}
	}
	
	def String getDescTxt(Constraints constraintsSource) {
	    var str = new String
	    for(elm : constraintsSource.composition) {
	        str = elm.descTxt
	    }
	    return str
	}


    def getStepModel(Constraints model) {
        var Steps stepModel = null
        for(imp : model.imports) {
            val Resource r = EcoreUtil2.getResource(imp.eResource, imp.importURI)
            if (r === null){
                new IllegalArgumentException("Cannot resolve the imported Steps model in the Constraints model.")
            } else {
                val root = r.allContents.head
                if (root instanceof Steps) {
                    stepModel = root
                }
            }
        }
        return stepModel
    }

    def getPrefix(IFileSystemAccess fsa, Resource r) {
        var uri = (fsa as IFileSystemAccessExtension2).getURI("") //r.getURI.trimSegments(5);
        var pathPrefix = new String
        if (uri.isPlatformResource()) {
            var file = ResourcesPlugin.getWorkspace().getRoot().getFile(new Path(uri.toPlatformString(true)));
            pathPrefix = file.getLocation().removeLastSegments(1).toOSString
        }
        return pathPrefix
    }
}	

    // asequences cannot be used for conformance checking
    /*def computeSequenceMapping(Constraints constraints) {
        for(sequenceDef : constraints.ssequences){
            var stepsList = newArrayList
            for(step : sequenceDef.stepList){
                stepsList.add(step.name)
            }
            seqsMapping.put(sequenceDef.name, stepsList)
        }
    }*/
    
    // TODO deprecate following two funcions. Has moved to test scenario generation.
	// TODO this aggregates all tags in a given constraint file. Does not generate scenarios with specific tags.
	// move this and specialize it for given a composition find set of tags
	/*def getRequirementTags(Constraints constraintsSource) {
	    var tagList = new HashSet<String>
	    for(elm : constraintsSource.composition) {
            for(f : elm.tagStr)
               tagList.add(f)
        }
	    tagList
	}

    // TODO this aggregates all tags in a given constraint file. Does not generate scenarios with specific tags.
    // move this and specialize it for given a composition find set of tags	
	def getConfigurationTags(Constraints constraintsSource) {
	    var tagList = new HashSet<String>
	    for(elm : constraintsSource.commonFeatures) {
	        tagList.add(elm.name)
	    }
	    for(elm : constraintsSource.composition) {
	        for(f : elm.features)
	           tagList.add(f.name)
	    }
	    tagList
	}*/
	
	/*def generateDeclareConstraints(Constraints model, Steps stepModel) 
	{
		getStepModel(model)
		return
		'''
		«FOR action : stepModel.actionList.acts»
			activity «action.name»
		«ENDFOR»
		«FOR templates : model.templates»
			«FOR _elm : templates.type»
				«IF _elm instanceof Existential»
					«FOR elm : _elm.type»
						«IF elm instanceof Participation»
							Existence[«getRefName(elm.ref)»] | |
						«ELSEIF elm instanceof AtMostOne»
							Absence2[«getRefName(elm.ref)»] | |
						«ELSEIF elm instanceof Init»
							Init[«getRefName(elm.ref)»] | |
						«ELSEIF elm instanceof End»
							End[«getRefName(elm.ref)»] | |
						«ENDIF»
					«ENDFOR»
				«ELSEIF _elm instanceof Relation»
					«FOR elm : _elm.type»
					«IF elm instanceof RespondedExistence»
						Responded Existence[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof Response»
						Response[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof AlternateResponse»
						Alternate Response[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof ChainResponse»
						Chain Response[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof Precedence»
						Precedence[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof AlternatePrecedence»
						Alternate Precedence[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof ChainPrecedence»
						Chain Precedence[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ENDIF»
					«ENDFOR»
				«ELSEIF _elm instanceof Coupling»
					«FOR elm : _elm.type»
					«IF elm instanceof CoExistance»
						Co-Existence[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof Succession»
						Succession[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof AlternateSuccession»
						Alternate Succession[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof ChainSuccession»
						Chain Succession[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ENDIF»
					«ENDFOR»
				«ELSEIF _elm instanceof Negative»
					«FOR elm : _elm.type»
					«IF elm instanceof NotSuccession»
						Not Succession[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof NotCoExistance»
						Not Co-Existence[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ELSEIF elm instanceof NotChainSuccession»
						Not Chain Succession[«getRefName(elm.refA)», «getRefName(elm.refB)»] | | |
					«ENDIF»
					«ENDFOR»
				«ENDIF»
			«ENDFOR»
		«ENDFOR»		
		'''
	}*/
    
	/*def getRefName(Ref ref){
		var refName = ""
		if(ref instanceof RefStep){
			refName = ref.step.name
		} else {
			if(ref instanceof RefStepSequence){
				refName = ref.seq.name
			}
		}
		return refName
	}

	def getStepModel(Constraints model) {
		var stepModel = null
		for(imp : model.imports){
			val Resource r = EcoreUtil2.getResource(imp.eResource, imp.importURI)
			if (r === null){
				new IllegalArgumentException("Cannot resolve the imported Steps model in the Constraints model.")
			} else {
				val root = r.allContents.head
				if (root instanceof Steps) {
					stepModel = root
				}
			}
		}
		stepModel
	}*/

