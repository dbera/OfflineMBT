package nl.esi.comma.testspecification.generator

import java.util.HashSet
import nl.esi.comma.testspecification.abstspec.generator.ConcreteExpressionHandler
import nl.esi.comma.testspecification.abstspec.generator.DataKVPGenerator
import nl.esi.comma.testspecification.abstspec.generator.ReferenceExpressionHandler
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.Binding
import nl.esi.comma.testspecification.testspecification.RunStep

import static extension nl.esi.comma.testspecification.abstspec.generator.Utils.*

class FromAbstractToConcrete {
    protected AbstractTestDefinition atd

    new(AbstractTestDefinition atd) {
        this.atd = atd
    }

    def __generateConcreteTest() {
        return (new DataKVPGenerator()).generateFAST(atd)
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

    def _printOutputs_(RunStep rstep) {
        // At most one (TODO validate this)
        // Observation: when multiple steps have indistinguishable outputs, 
        // multiple consumes from is possible. TODO Warn user.   
        val composeSteps = rstep.composeSteps
        // Get text for concrete data expressions
        var conDataExpr = (new ConcreteExpressionHandler())
            .prepareStepInputExpressions(rstep, composeSteps)
        // Append text for reference data expressions
        val refDataExpr = (new ReferenceExpressionHandler(false))
            .resolveStepReferenceExpressions(rstep, composeSteps)

        return '''
            «conDataExpr»
            «FOR entry : refDataExpr.entrySet»
                «entry.key» := «entry.value»
            «ENDFOR»
        '''
    }

    // Generate Types File for Concrete TSpec
    def generateTypesFile(String system, Iterable<String> typesImports) {
        var type = ''
        val ios = newLinkedHashMap
        for (rstep : system.runSteps) {
            if (!rstep.stepType.isEmpty) {
                type = rstep.stepType.last
            }
            rstep.input.forEach[i|ios.putIfAbsent(i.name, i)]
            rstep.output.forEach[o|ios.putIfAbsent(o.name, o)]
            for (cstep : rstep.composeSteps) {
                cstep.input.forEach[i|ios.putIfAbsent(i.name, i)]
                cstep.output.forEach[o|ios.putIfAbsent(o.name, o)]
            }
        }
        return printTypes(ios.values, type, typesImports)
    }

    // Print types for each step
    def private printTypes(Iterable<Binding> ios, String type, Iterable<String> typesImports) '''
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
    def generateParamsFile(String system) {
        var paramTxt = ''
        val processedTypes = new HashSet<String>()
        for (step : system.runSteps) {
            for (type : step.stepType.filter[processedTypes.add(it)]) {
                paramTxt += printParams(step, type)
            }
        }
        return paramTxt
    }

    private def printParams(RunStep step, String type) '''
        import "../types/«step.system».types"
        
        data-instances
        «type»Input «step.system»Input
        «type»Output «step.system»Output
        
        data-implementation
        // Empty
        
        path-prefix "./vfab2_scenario/FAST/generated_FAST/dataset/"
        var-ref «step.system»Input -> file-name "«step.system»Input.json"
        var-ref «step.system»Output -> file-name "«step.system»Output.json"
    '''

    def getSystems() {
        return atd.steps.filter(RunStep).map[system].toSet
    }

    def getRunSteps(String sys) {
        return atd.steps.filter(RunStep).filter[system == sys]
    }
}
