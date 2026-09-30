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
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ExecutableStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep
import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain
import nl.esi.comma.assertthat.assertThat.DataAssertionItem
import nl.esi.xtext.expressions.expression.ExpressionVariable
import nl.esi.xtext.expressions.services.ExpressionGrammarAccess
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

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

    def private generateConcreteTest(AbstractTestDefinition atd) {
        val executableSteps = atd.testSeq.flatMap[step].filter(ExecutableStep).toList
        val sutexpr = extractSUTVarExpressions(atd)

        return '''
            «FOR sys : atd.systems»
                import "parameters/«sys».params"
            «ENDFOR»
            
            Test-Purpose    "The purpose of this test is..."
            Background      "The background of this test is..."
            
            test-sequence from_abstract_to_concrete {
                test_single_sequence
            }
            
            step-sequence test_single_sequence {
            «FOR step : executableSteps SEPARATOR '\n'»
                «printStep(step)»
            «ENDFOR»
            }
            
            generate-file "«atd.filePath»"
            
            «IF !executableSteps.isEmpty»
                step-parameters
                «FOR step : executableSteps»
                    «step.stepType» step_«step.name»
                «ENDFOR»
            «ENDIF»
            
            «IF !sutexpr.empty»
                sut-param-init 
                «FOR lhs: sutexpr.keySet»
                    «FOR rhs: sutexpr.get(lhs)»
                        «lhs» := «rhs»
                    «ENDFOR»
                «ENDFOR»
            «ENDIF»
        '''
    }

    private def dispatch printStep(RunStep step) '''
        step-id    step_«step.name»
        step-type  «step.stepType»
        step-input «step.system»Input
        «printOutputs(step)»
    '''

    private def dispatch printStep(AssertionStep step) '''
        assertion-id    step_«step.name»
        assertion-type  «step.stepType»
        assertion-input «step.system»Input
        «printAssertions(step)»
        «printOutputs(step)»
    '''

    def private printAssertions(AssertionStep step) '''
        «IF !step.asserts.nullOrEmpty»
            assertion-items {
                «FOR ce : step.asserts.flatMap[ce]»
                    assertions «ce.name» {
                        «FOR dai: ce.constr»
                            «printDai(dai, step)»
                        «ENDFOR»
                    }
                «ENDFOR»
            }
        «ENDIF»
    '''

    def private printDai(DataAssertionItem item, AssertionStep step) {
        return item.serializeXtext[
            val gaExpression = semanticElement.getService(ExpressionGrammarAccess)
            if (gaExpression === null) {
                return null
            }
            var abs_assert = step
            var cexpr_handler = new ConcreteExpressionHandler()
            if (grammarElement == gaExpression.expressionLevel9Access.expressionVariableParserRuleCall_7) {
                val exprVar = semanticElement as ExpressionVariable
                return cexpr_handler.prepareAssertionStepExpressions(abs_assert, exprVar)
            }
        ]
    }

    def private String printOutputs(ExecutableStep estep) {
        // Get text for concrete data expressions
        var conDataExpr = (new ConcreteExpressionHandler()).prepareStepInputExpressions(estep, estep.stepRef)
        // Append text for reference data expressions
        val refDataExpr = (new ReferenceExpressionHandler()).resolveStepReferenceExpressions(estep)

        if (conDataExpr.isEmpty && refDataExpr.isEmpty) {
            return null
        }

        return '''
            ref-to-step-output
                «IF !conDataExpr.isEmpty»«conDataExpr»«ENDIF»
                «FOR entry : refDataExpr.entrySet»
                    «FOR v : entry.value»
                        «entry.key» := «v»
                    «ENDFOR»
                «ENDFOR»
        '''
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
