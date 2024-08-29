package nl.esi.comma.testspecification.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import nl.esi.comma.testspecification.testspecification.TestDefinition
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.AbstractStep
import nl.esi.comma.testspecification.testspecification.ConstraintStep
import nl.esi.comma.testspecification.testspecification.AssertStep

class FromAbstractToConcrete 
{

	def generateAbstractTest(AbstractTestDefinition atd) {
		var tspec = ""
		// TODO: import params
//		tspec += 'Test-Purpose' + purpose + "\n"
//		tspec += 'Background' + background + "\n"
//		tspec += 'Stakeholders' + stakeholders + "\n"

		tspec += '''
		test-sequence from_abstract_to_concrete {
			test_single_sequence
		}
		
		step-sequence test_single_sequence {
		
		'''

		for (test : atd.testSeq) {
			test.name
			for (step : test.step) {
				getStep(step)
			}
		}
		return tspec + "}\n\n"
	}

	def dispatch getStep(AbstractStep step) {
//		step.g
		return ""
	} 
	
	def dispatch getStep(ConstraintStep step) {
		return ""
	}
	
	def dispatch getStep(AssertStep step) {
		return ""
	}
	

	
}