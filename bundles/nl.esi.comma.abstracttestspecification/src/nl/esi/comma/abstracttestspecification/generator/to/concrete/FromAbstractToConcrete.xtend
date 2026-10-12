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

import java.util.List
import java.util.Map
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
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

        val baseName = res.URI.trimFileExtension.lastSegment
        val typesFile = baseName + '.types'
        val typesImports = getTypesImports(res).map[resolve(res.URI).deresolve(fsa.getURI(typesFile)).toString].toSet
        fsa.generateFile(typesFile, atd.generateTypesFile(typesImports))
        fsa.generateFile(baseName + '.tspec', atd.generateConcreteTest(typesFile))
    }

    def private generateConcreteTest(AbstractTestDefinition atd, String typesFile) '''
        import "«typesFile»"
        
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
    def private generateTypesFile(AbstractTestDefinition atd, Iterable<String> typesImports) {
        val sysStepTypes = atd.steps.filter(ExecutableStep).reject[stepType.isNullOrEmpty].groupBy[stepType]
        val sysStepTypeInputs = sysStepTypes.mapValues[it.flatMap[input].map['''«name.type.typeName» «varField»''']]
        val sysStepTypeOutputs = sysStepTypes.mapValues[it.flatMap[output].map['''«name.type.typeName» «varField»''']]

        return '''
            «FOR ti : typesImports»
                import "«ti»"
            «ENDFOR»

            «FOR stepType : sysStepTypes.keySet SEPARATOR '\n'»
                record «stepType» {
                    «IF !sysStepTypeInputs.get(stepType).nullOrEmpty»«stepType»Input input«ENDIF»
                    «IF !sysStepTypeOutputs.get(stepType).nullOrEmpty»«stepType»Output output«ENDIF»
                }

                «IF !sysStepTypeInputs.get(stepType).nullOrEmpty»
                    record «stepType»Input {
                        «sysStepTypeInputs.get(stepType).toSet.join('\n')»
                    }
                «ENDIF»

                «IF !sysStepTypeOutputs.get(stepType).nullOrEmpty»
                    record «stepType»Output {
                        «sysStepTypeOutputs.get(stepType).toSet.join('\n')»
                    }
                «ENDIF»
            «ENDFOR»
        '''
    }

// FIXME: Remove params language!
//    // Generate Parameters File for Concrete TSpec
//    def private generateParamsFile(AbstractTestDefinition atd, String system) {
//        val steps = atd.getExecutableSteps(system).reject[stepType.isNullOrEmpty]
//
//        return '''
//            import "../types/«system».types"
//            
//            data-instances
//            «FOR step : steps»
//                «step.stepType»Input «step.inputVar»
//                «step.stepType»Output «step.outputVar»
//            «ENDFOR»
//            
//            data-implementation
//            // Empty
//            
//            path-prefix "«atd.filePath»"
//            «FOR step : steps»
//                var-ref «step.inputVar» -> file-name "«step.inputVar».json"
//                var-ref «step.outputVar» -> file-name "«step.outputVar».json"
//            «ENDFOR»
//        '''
//    }
//    
//    def private getSystems(AbstractTestDefinition atd) {
//        return atd.steps.filter(ExecutableStep).map[system].toSet
//    }
//
//    def private getExecutableSteps(AbstractTestDefinition atd, String sys) {
//        return atd.steps.filter(ExecutableStep).filter[system == sys]
//    }

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
