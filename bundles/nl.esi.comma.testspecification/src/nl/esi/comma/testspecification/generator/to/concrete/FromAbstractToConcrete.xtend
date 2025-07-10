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
package nl.esi.comma.testspecification.generator.to.concrete

import java.util.HashMap
import java.util.HashSet
import java.util.Map
import nl.asml.matala.product.product.Product
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.Binding
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSMain
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.testspecification.generator.utils.Utils.*
import static extension nl.esi.comma.types.utilities.EcoreUtil3.*

class FromAbstractToConcrete extends AbstractGenerator {

    Map<String, String> rename  = new HashMap<String,String>()
    Map<String, String> args = new HashMap<String,String>()

    new(){}

    new(Map<String,String> rename, Map<String,String> params) {
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
        fsa.generateFile(res.URI.lastSegment, atd.generateConcreteTest())
        doGenerateFAST(res,fsa,ctx)
    }

    def doGenerateFAST(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val atd = res.contents.filter(TSMain).map[model].filter(AbstractTestDefinition).head
        if (atd === null) {
            throw new Exception('No abstract tspec found in resource: ' + res.URI)
        }

        fsa.generateFile('data.kvp', (new DataKVPGenerator()).generateFAST(atd))
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
            «FOR step : test.step.filter(RunStep)»
                
                step-id    step_«step.name»
                step-type  «step.stepType.get(0)»
                step-input «step.system»Input
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

    def private _printOutputs_(RunStep rstep) {
        // At most one (TODO validate this)
        // Observation: when multiple steps have indistinguishable outputs, 
        // multiple consumes from is possible. TODO Warn user.   
        val composeSteps = rstep.composeSteps
        // Get text for concrete data expressions
        var conDataExpr = (new ConcreteExpressionHandler()).prepareStepInputExpressions(rstep, composeSteps)
        // Append text for reference data expressions
        val refDataExpr = (new ReferenceExpressionHandler(false)).resolveStepReferenceExpressions(rstep, composeSteps)

        return '''
            «conDataExpr»
            «FOR entry : refDataExpr.entrySet»
                «FOR v : entry.value»
                    «entry.key» := «v»
                «ENDFOR»
            «ENDFOR»
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
    def private generateParamsFile(AbstractTestDefinition atd, String system) {
        var paramTxt = ''
        val processedTypes = new HashSet<String>()
        for (step : atd.getRunSteps(system)) {
            for (type : step.stepType.filter[processedTypes.add(it)]) {
                paramTxt += printParams(step, type)
            }
        }
        return paramTxt
    }

    def private printParams(RunStep step, String type) '''
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
        return atd.steps.filter(RunStep).map[system].toSet
    }

    def private getRunSteps(AbstractTestDefinition atd, String sys) {
        return atd.steps.filter(RunStep).filter[system == sys]
    }

    def private Iterable<String> getTypesImports(Resource res) {
        val typesImports = newLinkedHashSet
        for (psImport : res.contents.filter(TSMain).flatMap[imports].filter[importURI.endsWith('.ps')]) {
            for (typesImport : psImport.resource.contents.filter(Product).flatMap[imports].filter[importURI.endsWith('.types')]) {
                typesImports += typesImport.resolveUri.toString
            }
        }
        return typesImports;
    }
}
