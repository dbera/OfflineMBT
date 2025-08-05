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
package nl.esi.comma.abstracttestspecification.generator.to.concrete

import java.util.HashMap
import java.util.HashSet
import java.util.Map
import nl.asml.matala.product.product.Product
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ExecutableStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain
import nl.esi.comma.assertthat.assertThat.DataAssertionItem
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*
import static extension nl.esi.comma.types.utilities.EcoreUtil3.*

class FromAbstractToConcrete extends AbstractGenerator {

    Map<String, String> rename = new HashMap<String, String>()
    Map<String, String> args = new HashMap<String, String>()

    new() {
    }

    new(Map<String, String> rename, Map<String, String> params) {
        this.rename = rename
        this.args = params
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val atd = res.contents.filter(TSMain).map[model].filter(AbstractTestDefinition).head
        if (atd === null) {
            throw new Exception('No abstract tspec found in resource: ' + res.URI)
        }

        val typesImports = getTypesImports(res)
        for (sys : atd.systems) {
            fsa.generateFile('''types/«sys».types''', atd.generateTypesFile(sys, typesImports))
            fsa.generateFile('''parameters/«sys».params''', atd.generateParamsFile(sys))
        }
        val conTspecFileName = res.URI.lastSegment.replaceAll('\\.atspec$','.tspec')
        fsa.generateFile(conTspecFileName, atd.generateConcreteTest())
        fsa.generateFile("reference.kvp", (new RefKVPGenerator()).generateRefKVP(atd))
        fsa.generateFile("vfd.xml", (new VFDXMLGenerator(this.args, this.rename)).generateXMLFromSUTVars(atd))
 
    }

    def private generateConcreteTest(AbstractTestDefinition atd) '''
        «FOR sys : atd.systems»
            import "parameters/«sys».params"
        «ENDFOR»
        
        Test-Purpose    "The purpose of this test is..."
        Background      "The background of this test is..."
        
        test-sequence from_abstract_to_concrete {
            test_single_sequence
        }
        
        step-sequence test_single_sequence {
        «FOR test : atd.testSeq»
            «FOR step : test.step.filter(ExecutableStep)»
                
                «printStep(step)»
            «ENDFOR»
        «ENDFOR»
        }
        
        generate-file "./vfab2_scenario/FAST/generated_FAST/"
        
        step-parameters
        «FOR test : atd.testSeq»
            «FOR step : test.step.filter(ExecutableStep)»
                «step.stepType.get(0)» step_«step.name»
            «ENDFOR»
        «ENDFOR»
    '''
    
    def printStep(ExecutableStep step) {
        return switch (step) {
        	RunStep: printStep(step as RunStep)
        	AssertionStep: printStep(step as AssertionStep)
            default: throw new UnsupportedOperationException("Unsupported ExecutableStep sub-type")
        }
    }
    def printStep(RunStep step) '''
        step-id    step_«step.name»
        step-type  «step.stepType.get(0)»
        step-input «step.system»Input
        «IF !_printOutputs_(step).toString.nullOrEmpty»
            ref-to-step-output
                «_printOutputs_(step)»
        «ENDIF»
    '''

    def printStep(AssertionStep step) '''
        /*
        assertion-id    step_«step.name»
        assertion-type  «step.stepType.get(0)»
        assertion-input «step.system»Input
        «IF !step.asserts.nullOrEmpty»
        «_printAssertions(step)»
        «ENDIF»
        «IF !_printOutputs_(step).toString.nullOrEmpty»
            ref-to-step-output
                «_printOutputs_(step)»
        «ENDIF»
        */
    '''
    
    def _printAssertions(AssertionStep step) '''
    assertion-items {
    «FOR ce : step.asserts.flatMap[ce]»
        assertions «ce.name» { 
            «FOR dai: ce.constr»
                «printDai(dai, step)»
            «ENDFOR»
         }
    «ENDFOR»
    }
    '''
    
    def printDai(DataAssertionItem item, AssertionStep step) {
        return item.serialize
    }

    def private _printOutputs_(RunStep rstep) {
        // At most one (TODO validate this)
        // Observation: when multiple steps have indistinguishable outputs, 
        // multiple consumes from is possible. TODO Warn user.   
        val composeSteps = rstep.composeSteps
        // Get text for concrete data expressions
        var conDataExpr = (new ConcreteExpressionHandler()).prepareStepInputExpressions(rstep, composeSteps)
        // Append text for reference data expressions
        val refDataExpr = (new ReferenceExpressionHandler()).resolveStepReferenceExpressions(rstep, composeSteps)

        return '''
            «conDataExpr»
            «FOR entry : refDataExpr.entrySet»
                «FOR v : entry.value»
                    «entry.key» := «v»
                «ENDFOR»
            «ENDFOR»
        '''
    }

    def private _printOutputs_(AssertionStep astep) {
        // At most one (TODO validate this)
        // Observation: when multiple steps have indistinguishable outputs, 
        // multiple consumes from is possible. TODO Warn user.   
        val runSteps = astep.runSteps
        // Get text for concrete data expressions
        var conDataExpr = (new ConcreteExpressionHandler()).prepareStepInputExpressions(astep, runSteps)
        // Append text for reference data expressions
//        val refDataExpr = (new ReferenceExpressionHandler()).resolveStepReferenceExpressions(astep, runSteps)

        return '''
            «conDataExpr»
«««            «FOR entry : refDataExpr.entrySet»
«««                «FOR v : entry.value»
«««                    «entry.key» := «v»
«««                «ENDFOR»
«««            «ENDFOR»
        '''
    }

    // Generate Types File for Concrete TSpec
    def generateTypesFile(AbstractTestDefinition atd, String system, Iterable<String> typesImports) {
        var type = ''
        val ios = newLinkedHashMap
        for (rstep : atd.getRunSteps(system)) {
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
        for (astep : atd.getAssertionSteps(system)) {
            if (!astep.stepType.isEmpty) {
                type = astep.stepType.last
            }
            astep.input.forEach[i|ios.putIfAbsent(i.name, i)]
            astep.output.forEach[o|ios.putIfAbsent(o.name, o)]
            for (cstep : astep.runSteps) {
                cstep.input.forEach[i|ios.putIfAbsent(i.name, i)]
                cstep.output.forEach[o|ios.putIfAbsent(o.name, o)]
            }
        }
        return printTypes(ios.values, type, typesImports)
    }

    // Print types for each step
    def private printTypes(Iterable<Binding> ios, String type, Iterable<String> typesImports) '''
        «FOR ti : typesImports»
            import "../«ti»"
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
    def private generateParamsFile(AbstractTestDefinition atd, String system) {
        var paramTxt = ''
        val processedTypes = new HashSet<String>()
        for (step : atd.getExecutableSteps(system)) {
            for (type : step.stepType.filter[processedTypes.add(it)]) {
                paramTxt += printParams(step, type)
            }
        }
        return paramTxt
    }

    def private printParams(ExecutableStep step, String type) '''
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

    def private getSystems(AbstractTestDefinition atd) {
        return atd.steps.filter(ExecutableStep).map[system].toSet
    }

    def private getRunSteps(AbstractTestDefinition atd, String sys) {
        return atd.steps.filter(RunStep).filter[system == sys]
    }

    def private getAssertionSteps(AbstractTestDefinition atd, String sys) {
        return atd.steps.filter(AssertionStep).filter[system == sys]
    }

    def private getExecutableSteps(AbstractTestDefinition atd, String sys) {
        return atd.steps.filter(ExecutableStep).filter[system == sys]
    }

    def private Iterable<String> getTypesImports(Resource res) {
        val typesImports = newLinkedHashSet
        for (psImport : res.contents.filter(TSMain).flatMap[imports].filter[importURI.endsWith('.ps')]) {
            for (typesImport : psImport.resource.contents.filter(Product).flatMap[imports].filter [
                importURI.endsWith('.types')
            ]) {
                val typesImportURI = typesImport.resolveUri.deresolve(res.URI)
                typesImports += typesImportURI.toString
            }
        }
        return typesImports;
    }
}
