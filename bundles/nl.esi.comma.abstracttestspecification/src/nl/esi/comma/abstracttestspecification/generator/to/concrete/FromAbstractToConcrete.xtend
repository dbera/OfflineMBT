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

import java.util.HashSet
import java.util.List
import java.util.Map
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ExecutableStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain
import nl.esi.comma.assertthat.assertThat.DataAssertionItem
import nl.esi.xtext.expressions.expression.ExpressionVariable
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.abstracttestspecification.generator.to.concrete.ConcreteExpressionHandler.*
import static extension nl.esi.comma.abstracttestspecification.generator.to.concrete.ReferenceExpressionHandler.*
import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*

class FromAbstractToConcrete extends AbstractGenerator {

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val atd = res.contents.filter(TSMain).map[model].head
        if (atd === null) {
            throw new Exception('No abstract tspec found in resource: ' + res.URI)
        }

        val typesImportURIs = getTypesImports(res)
        for (sys : atd.systems) {
            val typesFile = '''types/«sys».types'''
            val typesURI = fsa.getURI(typesFile)
            val typesImports = typesImportURIs.map[resolve(res.URI).deresolve(typesURI).toString].toSet
            fsa.generateFile(typesFile, atd.generateTypesFile(sys, typesImports))
            fsa.generateFile('''parameters/«sys».params''', atd.generateParamsFile(sys))
        }
        val conTspecFileName = res.URI.trimFileExtension.appendFileExtension('tspec').lastSegment
        fsa.generateFile(conTspecFileName, atd.generateConcreteTest())
 
    }

    def private generateConcreteTest(AbstractTestDefinition atd) '''
        «FOR sys : atd.systems»
            import "parameters/«sys».params"
        «ENDFOR»
        
        test-sequence from_abstract_to_concrete {
            test_single_sequence
        }
        
        step-sequence test_single_sequence {
        «FOR step : atd.steps.filter(ExecutableStep) SEPARATOR '\n'»
            «printStep(step)»
        «ENDFOR»
        }
        
        generate-file "«atd.filePath»"
    '''

    private def printStep(ExecutableStep step) {
        val type = step instanceof AssertionStep ? 'assertion' : 'step'

        val contextAssignments = step.collectConcreteDataAssignments(step.contextData)
        val sutAssignments = step.collectConcreteDataAssignments(step.SUTData)

        // Get assignments for concrete data input
        val inputAssignments = step.collectConcreteDataAssignments(step.inputData)
        // Add assignments for reference data input
        inputAssignments.mergeAll(step.collectReferenceDataAssignments)

        return '''
            «type»-id    step_«step.name»
            «type»-type  «step.stepType»
            «IF step instanceof AssertionStep»
                assertion-items {
                    «FOR ce : step.asserts.flatMap[ce]»
                        assertions «ce.name» {
                            «FOR dai: ce.constr»
                                «step.printDai(dai)»
                            «ENDFOR»
                        }
                    «ENDFOR»
                }
            «ENDIF»
            «contextAssignments.printAssignments(type + '-context')»
            «inputAssignments.printAssignments(type + '-input')»
            «sutAssignments.printAssignments(type + '-sut')»
        '''
    }

    def private String printDai(AssertionStep step, DataAssertionItem item) {
        return item.serialize[ obj |
            if (obj instanceof ExpressionVariable) {
                val vname = obj.variable.name
                return '''«step.inputVar».«vname»'''
            }
        ].stripIndent().trim()
    }

    def private printAssignments(Map<String, List<String>> assignments, String type) '''
        «IF !assignments.isEmpty»
            «type»
                «FOR entry : assignments.entrySet»
                    «FOR rhs : entry.value»
                        «entry.key» := «rhs»
                    «ENDFOR»
                «ENDFOR»
        «ENDIF»
    '''

    def void mergeAll(Map<String, List<String>> source, Map<String, List<String>> addition) {
        addition.forEach[k, v |
            source.merge(k, v) [ v1, v2 |
                v1 += v2
                return v1
            ]
        ]
    }

    // Generate Types File for Concrete TSpec
    def private generateTypesFile(AbstractTestDefinition atd, String system, Iterable<String> typesImports) {
        var type = ''
        val ios = newLinkedHashMap
        for (estep : atd.getExecutableSteps(system)) {
            if (!estep.stepType.isNullOrEmpty) {
                type = estep.stepType
            }
            estep.input.forEach[i|ios.putIfAbsent(i.name, i)]
            estep.output.forEach[o|ios.putIfAbsent(o.name, o)]
            for (cstep : estep.chainedStepRefs.map[refStep]) {
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
        for (step : atd.getExecutableSteps(system).reject[stepType.isNullOrEmpty]) {
            if (processedTypes.add(step.stepType)) {
                paramTxt += printParams(atd, step, step.stepType)
            }
        }
        return paramTxt
    }

    def private printParams(AbstractTestDefinition atd, ExecutableStep step, String type) '''
        import "../types/«step.system».types"
        
        data-instances
        «type»Input «step.system»Input
        «type»Output «step.system»Output
        
        data-implementation
        // Empty
        
        path-prefix "«atd.filePath»"
        var-ref «step.system»Input -> file-name "«step.system»Input.json"
        var-ref «step.system»Output -> file-name "«step.system»Output.json"
    '''
    
    def private getSystems(AbstractTestDefinition atd) {
        return atd.steps.filter(ExecutableStep).map[system].toSet
    }

    def private getExecutableSteps(AbstractTestDefinition atd, String sys) {
        return atd.steps.filter(ExecutableStep).filter[system == sys]
    }

    def private Iterable<URI> getTypesImports(Resource res) {
        val typesImports = newLinkedHashSet
        for (psImport : res.getImports('ps')) {
            val psRes = psImport.resource
            for (typesImport : psRes.getImports('types')) {
                typesImports += typesImport.resolveUri.deresolve(res.URI)
            }
        }
        return typesImports;
    }
}
