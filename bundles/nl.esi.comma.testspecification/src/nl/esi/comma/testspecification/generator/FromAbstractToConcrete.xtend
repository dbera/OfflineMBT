package nl.esi.comma.testspecification.generator

import java.util.HashSet
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.testspecification.testspecification.AbstractStep
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.Binding
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.ConstraintStep
import nl.esi.comma.testspecification.testspecification.NestedKeyValuesPair
import nl.esi.comma.testspecification.testspecification.RunStep
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.common.util.EList
import nl.esi.comma.testspecification.testspecification.StepReference
import nl.esi.comma.testspecification.testspecification.TSMain
import java.util.List

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
			«IF !printOutputs(step).toString.nullOrEmpty»
			ref-to-step-output
				«printOutputs(step)»
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

	def printKVInputPairs(String prefix, String field, EList<NestedKeyValuesPair> pairs) {
		var kv = ""
		for (p : pairs) {
			for (a : p.actions) {
				kv += prefix + "." + field + printRecord("", null, a as RecordFieldAssignmentAction) + "\n"
			}
		}
		return kv
	}

	def printRecord(String prefix, EList<StepReference> stepRef, RecordFieldAssignmentAction rec) {
		var field = printField(rec.fieldAccess)
		var value = (new ExpressionGenerator(stepRef)).exprToComMASyntax(rec.exp)
		var p = (rec.exp instanceof ExpressionVector) ? "" : prefix
		return field + " := " + p + value
	}

	dispatch def String printField(ExpressionRecordAccess exp) {
		return printField(exp.record) + "." + exp.field.name
	}

	dispatch def String printField(ExpressionVariable exp) {
		return ""
	}

	def printOutputs(RunStep step) '''
«FOR composeStep : previousComposeStep(step)»
«printKVOutputPairs(step.name.split("_").get(0) + "Input", composeStep)»
«ENDFOR»
«FOR symbolicStep : previousSymbolicContraint(step)»
«printSymbolicContraint(step.name.split("_").get(0) + "Input", symbolicStep, previousRunStep(step), previousComposeStep(step))»
«ENDFOR»
	'''
	

	def printKVOutputPairs(String prefix, ComposeStep step) {
		var kv = ""
		if (!step.suppress) {
			for (o : step.output) {
				kv += printKVInputPairs(prefix, o.name.name, o.kvPairs)
			}
		}
		return kv
	}

	def printSymbolicContraint(String prefix, ConstraintStep step, EList<RunStep> runSteps, EList<ComposeStep> composeSteps) {
		var sc = ""
		for (s : step.ce) {
			for (a : s.act.actions) {
				for (rs : runSteps.filter[r | !r.suppress]) {
					for (cs : composeSteps) {
						var pi = prefix + "." + step.name
						var po = "step_" + rs.name + ".output."
						sc += pi + printRecord(po, cs.stepRef, a as RecordFieldAssignmentAction) + "\n"
					}
				}
			}
		}
		return sc
	}

	def previousRunStep(RunStep step) {
		var composeSteps = new BasicEList<RunStep>()
		var AbstractStep prev
		for (absStep : atd.eAllContents.filter(AbstractStep).toIterable) {
			if (absStep === step) {
				composeSteps.add(prev as RunStep)
			}
			if (absStep instanceof RunStep) {
				prev = absStep
			}
		}
		return composeSteps
	}

	def previousComposeStep(RunStep step) {
		var composeSteps = new BasicEList<ComposeStep>()
		var AbstractStep prev
		for (absStep : atd.eAllContents.filter(AbstractStep).toIterable) {
			if (absStep === step) {
				composeSteps.add(prev as ComposeStep)
			}
			prev = absStep
		}
		return composeSteps
	}

	def previousSymbolicContraint(RunStep step) {
		var SymbolicContraints = new BasicEList<ConstraintStep>()
		var ConstraintStep prev = null
		for (testSeq : atd.testSeq) {
			for (s : testSeq.step) {
				if (s === step && prev !== null) {
					SymbolicContraints.add(prev)
				}
				prev = (s instanceof ConstraintStep) ? s as ConstraintStep : null
			}
		}
		return SymbolicContraints
	}

	def generateTypesFile(String sys, List<String> typesImports) {
		var typ = ""
		var ios = new BasicEList<Binding>()
		for (s : atd.eAllContents.filter(RunStep).filter[s | s.name.split("_").get(0).equalsIgnoreCase(sys)].toIterable) {
			for (t : s.stepType) {
				typ = t
			}
			ios.addAll(s.input)
			ios.addAll(s.output)
			for (p : previousComposeStep(s)) {
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