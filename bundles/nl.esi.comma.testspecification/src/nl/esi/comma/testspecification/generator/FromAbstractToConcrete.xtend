package nl.esi.comma.testspecification.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.Binding
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.NestedKeyValuesPair
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.StepReference
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.common.util.EList

class FromAbstractToConcrete 
{
	protected AbstractTestDefinition atd

	new (AbstractTestDefinition atd) {
		this.atd = atd
	}

	def generateConcreteTest() '''
		«FOR sys : getSystems()»
		import "parameters/«sys».params"
		«ENDFOR»
		
		Test-Purpose 	"The purpose of this test is..."
		Background 		"The background of this test is..."
		
		test-sequence from_abstract_to_concrete {
			test_single_sequence
		}
		
		step-sequence test_single_sequence {
		«FOR test : atd.testSeq»
			«FOR step : test.step.filter(RunStep)»
			
			step-id    step_«step.name»
			step-type  «step.stepType.get(0)»
			step-input «step.name.split("_").get(0)»Input
			«IF !_printOutputs_(step).toString.nullOrEmpty»
			ref-to-step-output
				«_printOutputs_(step)»
			«ENDIF»
			«ENDFOR»
		«ENDFOR»
		}
		
		generate-file "./vfab2_scenario/FAST/generated_FAST/"
		
		step-parameters
		«FOR test : atd.testSeq»
		«FOR step : test.step.filter(RunStep)»
		«step.stepType.get(0)» step_«step.name»
		«ENDFOR»
		«ENDFOR»

	'''

    /*
     * Support Interleaving of Compose and Run Steps. 
     * Q1 2025.  
     */
    def _printOutputs_(RunStep rstep) 
    {
        // At most one (TODO validate this)
        // Observation: when multiple steps have indistinguishable outputs, 
        // multiple consumes from is possible. TODO Warn user.   
        var listOfComposeSteps = getComposeSteps(rstep)
        var mapLHStoRHS = resolveStepReferenceExpressions(rstep, listOfComposeSteps)

        // Get text for concrete data expressions
        var txt = prepareStepInputExpressions(rstep, listOfComposeSteps)

        // Append text for reference data expressions
        for(k : mapLHStoRHS.keySet) {
            txt += 
            '''
            «k» := «mapLHStoRHS.get(k)»
            '''
        }
        return txt
    }

    /* TODO. Q2 2025. Yuri. 
     * Fix JSON Object to ComMA Expression Reconstruction.
     */
    def prepareStepInputExpressions(RunStep rstep, HashSet<ComposeStep> listOfComposeSteps) 
    {
        return 
        '''
        «FOR composeStep : listOfComposeSteps»
        «printKVOutputPairs(rstep.name.split("_").get(0) + "Input", composeStep)»
        «ENDFOR»
        '''
    }

    def resolveStepReferenceExpressions(RunStep rstep, HashSet<ComposeStep> listOfComposeSteps) 
    {
        // System.out.println("Run Step: " + rstep.name)
        var mapLHStoRHS = new HashMap<String,String>
        // Find preceding Compose Step
        for(cstep : listOfComposeSteps) // at most one 
        {
            // System.out.println("    -> compose-name: " + cstep.name)
            var refTxt = new String
            for(cons : cstep.refs) {
                // System.out.println("    -> constraint-var: " + cons.name)
                for(refcons : cons.ce) {
                    for (a : refcons.act.actions) {
                        var constraint = _printRecord_(cstep.name, 
                                                    rstep.name, cstep.stepRef, 
                                                    a as RecordFieldAssignmentAction, true)
                        refTxt += constraint.getText + "\n" 
                        mapLHStoRHS.put(constraint.lhs, constraint.rhs)
                    }
                }
            }
            // if(!refTxt.isEmpty) System.out.println("\nLocal Constraints:\n" + refTxt)
            var cstepList = getNestedComposeSteps(cstep, new ArrayList<ComposeStep>)
            for(cs : cstepList) {
                // System.out.println("        -> compose-name: " + cs.name)
                refTxt = new String
                for(cons : cs.refs) {
                    // System.out.println("        -> constraint-var: " + cons.name)
                    for(refcons : cons.ce) {
                        for (a : refcons.act.actions) {
                            var constraint = _printRecord_(cs.name, rstep.name, cs.stepRef, 
                                                a as RecordFieldAssignmentAction, false)
                            refTxt += constraint.getText + "\n"
                            mapLHStoRHS.put(constraint.lhs, constraint.rhs) 
                        }
                    }
                }
            }
            // if(!refTxt.isEmpty) System.out.println("\nRef Constraints:\n" + refTxt)
        }
        // Rewrite expressions in mapLHStoRHS
        // TODO Validate that LHS and RHS are unique. 
        // No collisions are allowed.
        var refKeyList = new ArrayList<String>
        for(k : mapLHStoRHS.keySet) {
            for(_k : mapLHStoRHS.keySet) { 
                if(_k.equals(mapLHStoRHS.get(k))) { // if LHS equals RHS
                    mapLHStoRHS.put(k, mapLHStoRHS.get(_k)) // rewrite
                    refKeyList.add(_k)
                }
            }
        }
        // remove intermediate expressions
        for(k : refKeyList) mapLHStoRHS.remove(k)

        return mapLHStoRHS
    }

    def _printRecord_(String composeStepName, String runStepName, 
        EList<StepReference> stepRef, RecordFieldAssignmentAction rec, boolean isFirstCompose) {

        // Run block input data structure = Concrete TSpec step input data structure
        var blockInputName = new String 
        var pi = new String

        // System.out.println(" Field: " + printField(rec.fieldAccess, true))
        var field = new String
        if(isFirstCompose) {
            blockInputName = runStepName.split("_").get(0) + "Input" 
            pi = blockInputName + "."
            field = printField(rec.fieldAccess, true)
        } else field = printField(rec.fieldAccess, true)

        var value = (new ExpressionGenerator(stepRef, runStepName)).exprToComMASyntax(rec.exp)
        // System.out.println(" value: " + value)

        if (!(rec.exp instanceof ExpressionVector || rec.exp instanceof ExpressionFunctionCall)) {
            // For record expressions. 
            // The rest is handled as override functions in ExpressionGenerator.
            for(csref : stepRef) {
                for(csrefdata : csref.refData) {
                    // System.out.println(" Replacing: " + sd.name + " with " + sr.refStep.name)
                    if(csref.refStep instanceof RunStep && 
                        value.toString.contains(csrefdata.name)) {
                        value = "step_" + csref.refStep.name + ".output." + value
                    }
                }
            }
        }
        return new StepConstraint ( runStepName,
                                    composeStepName, 
                                    pi + field, // lhs
                                    value.toString, // rhs
                                    pi + field + " := " + value // text
                                  ) 
    }


    // Gets the list of referenced compose steps by a compose step, recursively!
    // RULE. Compose Step may reference at most one preceding Compose Step. 
    // RULE. Each Compose Step must reference at least one Run Step. 
    def List<ComposeStep> getNestedComposeSteps(ComposeStep cstep, List<ComposeStep> listOfComposeSteps) 
    {
        if(cstep.stepRef.isNullOrEmpty) return listOfComposeSteps

        for(elm : cstep.stepRef) 
        {
            if(elm.refStep instanceof ComposeStep) {
                listOfComposeSteps.add(elm.refStep as ComposeStep)
                getNestedComposeSteps(elm.refStep as ComposeStep, listOfComposeSteps)
            }
        }
        return listOfComposeSteps
    }

    // Gets the list of referenced compose steps
    // RULE. Exactly one referenced Compose Step. 
    def getComposeSteps(RunStep rstep) {
        var listOfComposeSteps = new HashSet<ComposeStep>
        for(elm : rstep.stepRef) {
            for(cstep: atd.eAllContents.filter(ComposeStep).toIterable) {
                if(elm.refStep.name.equals(cstep.name)) {
                    listOfComposeSteps.add(cstep)
                }
            }
        }
        listOfComposeSteps
    }

    /*
     * End of Feature Update: Support Interleaving of Compose and Run Steps
     * Q1 2025. 
     */

      /* Removed ComMA Expression Printing 04.04.2025 */
      /* TODO Rewrite this function to parse JSON Object */
      def printKVOutputPairs(String prefix, ComposeStep step) {
          var kv = ""
//        if (!step.suppress) {
//            for (o : step.output) {
//                kv += printKVInputPairs(prefix, o.name.name, o.kvPairs)
//            }
//        }
          return kv
      }

    def printKVInputPairs(String prefix, String field, EList<NestedKeyValuesPair> pairs) {
        var kv = ""
        for (p : pairs) {
            for (a : p.actions) {
                kv += prefix + "." + field + printRecord("", "", null, a as RecordFieldAssignmentAction) + "\n"
            }
        }
        return kv
    }

    def printRecord(String stepName, String prefix, EList<StepReference> stepRef, RecordFieldAssignmentAction rec) {
        var field = printField(rec.fieldAccess, false)
        var value = (new ExpressionGenerator(stepRef,stepName)).exprToComMASyntax(rec.exp)
        var p = (rec.exp instanceof ExpressionVector || rec.exp instanceof ExpressionFunctionCall) ? "" : prefix
        return field + " := " + p + value
    }

    dispatch def String printField(ExpressionRecordAccess exp, boolean printVar) {
        return printField(exp.record, printVar) + "." + exp.field.name
    }

    dispatch def String printField(ExpressionVariable exp, boolean printVar) {
        if(printVar) return exp.getVariable().getName()
        else return ""
    }

    // Generate Types File for Concrete TSpec
	def generateTypesFile(String sys, List<String> typesImports) {
		var typ = ""
		var ios = new BasicEList<Binding>()
		for (s : atd.eAllContents.filter(RunStep).filter[s | s.name.split("_").get(0).equalsIgnoreCase(sys)].toIterable) {
			for (t : s.stepType) {
				typ = t
			}
			ios.addAll(s.input)
			ios.addAll(s.output)
			// for (p : previousComposeStep(s)) {
			for (p : getComposeSteps(s)) {
				ios.addAll(p.input)
				ios.addAll(p.output)
			}
		}
		var uniqueIos = new BasicEList<Binding>()
		for (io : ios) {
			if (!uniqueIos.exists[u | u.name == io.name]) {
				uniqueIos.add(io)
			}
		}
		return printTypes(uniqueIos, typ, typesImports)
	}

	def printTypes(EList<Binding> ios, String type, List<String> typesImports) '''
		«FOR ti : typesImports»
		import "«ti»"
		«ENDFOR»
		
		record «type» {
			«type»Input input
			«type»Output output
		}
		
		record «type»Input {
			«FOR i : ios» 
			«i.name.type.type.name» «i.name.name»
			«ENDFOR»
		}
		
		record «type»Output {
			«FOR o : ios» 
			«o.name.type.type.name» «o.name.name»
			«ENDFOR»
		}
	'''

    // Generate Parameters File for Concrete TSpec
	def generateParamsFile(String sys) {
		var paramTxt = ""
		var processedTypes = new HashSet<String>()
		for (s : atd.eAllContents.filter(RunStep).filter[s | s.name.split("_").get(0).equalsIgnoreCase(sys)].toIterable) {
			for (t : s.stepType) {
				if (processedTypes.add(t)) { // true if not in set
					paramTxt += printParams(s, t)
				}
			}
		}
		return paramTxt
	}

	def printParams(RunStep step, String type) {
		var sys = step.name.split("_").get(0)
		return '''
		import "../types/«sys».types"
		
		data-instances
		«type»Input «sys»Input
		«type»Output «sys»Output
		
		data-implementation
		// Empty
		
		path-prefix "./vfab2_scenario/FAST/generated_FAST/dataset/"
		var-ref «sys»Input -> file-name "«sys»Input.json"
		var-ref «sys»Output -> file-name "«sys»Output.json"
		'''
	}

	def getSystems() {
		var bbs = new HashSet<String>()
		for (s : atd.eAllContents.filter(RunStep).toIterable) {
			bbs.add(s.name.split("_").get(0))
		}
		return bbs
	}

}

class StepConstraint 
{
    public var composeStepName = new String
    public var runStepName = new String
    public var lhs = new String
    public var rhs = new String
    public var text = new String

    new(String runStepName, String composeStepName, String lhs, String rhs, String text) {
        this.runStepName = runStepName
        this.composeStepName = composeStepName
        this.lhs = lhs
        this.rhs = rhs
        this.text = text
    }
    
    def getComposeStepName() { return composeStepName }
    def getRunStepName() { return runStepName }
    def getLHS() { return lhs }
    def getRHS() { return rhs }
    def getText() { return text }

    def void print(StepConstraint sc) {
        System.out.println(" RUN-STEP-NAME: " + runStepName)
        System.out.println(" COMPOSE-STEP-NAME: " + composeStepName)
        sc.printLHSandRHS()
    }

    def printLHSandRHS() {
        System.out.println("    -> LHS: " + lhs + "  RHS: " + rhs)
    }
}

/* OLD DEPRECATED LOGIC FOR COMPOSE AND RUN STEPS */
// Developed in Q4 2024.
//  def printOutputs(RunStep step) '''
//«FOR composeStep : previousComposeStep(step)»
//«printKVOutputPairs(step.name.split("_").get(0) + "Input", composeStep)»
//«ENDFOR»
//«FOR symbolicStep : previousSymbolicContraint(step)»
//«printSymbolicContraint(step.name.split("_").get(0) + "Input", symbolicStep, previousRunStep(step), previousComposeStep(step))»
//«ENDFOR»
//  '''

//  def printSymbolicContraint(String prefix, ConstraintStep step, EList<RunStep> runSteps, EList<ComposeStep> composeSteps) {
//      var sc = ""
//      for (s : step.ce) {
//          for (a : s.act.actions) {
//              for (rs : runSteps.filter[r | r !== null && !r.suppress]) {
//                  for (cs : composeSteps) {
//                      var pi = prefix + "." + step.name
//                      var po = "step_" + rs.name + ".output."
//                      sc += pi + printRecord(prefix, po, cs.stepRef, a as RecordFieldAssignmentAction) + "\n"
//                  }
//              }
//          }
//      }
//      return sc
//  }
//
//  def previousRunStep(RunStep step) {
//      var composeSteps = new BasicEList<RunStep>()
//      var AbstractStep prev
//      for (absStep : atd.eAllContents.filter(AbstractStep).toIterable) {
//          if (absStep === step) {
//              composeSteps.add(prev as RunStep)
//          }
//          if (absStep instanceof RunStep) {
//              prev = absStep
//          }
//      }
//      return composeSteps
//  }
//
//  def previousComposeStep(RunStep step) {
//      var composeSteps = new BasicEList<ComposeStep>()
//      var AbstractStep prev
//      for (absStep : atd.eAllContents.filter(AbstractStep).toIterable) {
//          if (absStep === step) {
//              composeSteps.add(prev as ComposeStep)
//          }
//          prev = absStep
//      }
//      return composeSteps
//  }
//
//  def previousSymbolicContraint(RunStep step) {
//      var SymbolicContraints = new BasicEList<ConstraintStep>()
//      var ConstraintStep prev = null
//      for (testSeq : atd.testSeq) {
//          for (s : testSeq.step) {
//              if (s === step && prev !== null) {
//                  SymbolicContraints.add(prev)
//              }
//              prev = (s instanceof ConstraintStep) ? s as ConstraintStep : null
//          }
//      }
//      return SymbolicContraints
//  }

