package nl.esi.comma.causalgraph.generator

import nl.esi.comma.actions.actions.ActionsFactory
import nl.esi.comma.causalgraph.CausalGraphStandaloneSetup
import nl.esi.comma.causalgraph.causalGraph.CausalGraphFactory
import nl.esi.comma.causalgraph.causalGraph.ScenarioStep
import nl.esi.comma.causalgraph.causalGraph.StepType
import nl.esi.comma.causalgraph.causalGraph.VariableAccess
import nl.esi.comma.causalgraph.utilities.CausalGraphRefinements
import nl.esi.comma.causalgraph.utilities.NodeAttributes
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.types.BasicTypes
import org.eclipse.emf.common.util.URI
import org.eclipse.lsat.common.xtend.annotations.IntermediateProperty
import org.eclipse.xtext.resource.XtextResourceSet

class ReducedCausalGraphGenerator {
    static extension val CausalGraphFactory m_cg = CausalGraphFactory::eINSTANCE
    static extension val ExpressionFactory m_exp = ExpressionFactory::eINSTANCE
    static extension val ActionsFactory m_act = ActionsFactory::eINSTANCE

    @IntermediateProperty(ScenarioStep)
    static Boolean function = false

    @IntermediateProperty(ScenarioStep)
    static String stepName

    @IntermediateProperty(ScenarioStep)
    static StepType stepType = StepType.THEN

    def static void main(String[] args) {
        CausalGraphStandaloneSetup.doSetup

        val scenario1 = createScenarioDecl => [
            name = 'S1'
            requirements += createRequirementDecl => [
                name = 'R1'
            ]
        ]

        val variableX = createVariable => [
            name = 'x'
            type = createTypeReference => [
                type = createAliasTypeDecl => [
                    name = 'x_type'
                    alias = 'some_type'
                ]
            ]
        ]

        val steps = newArrayList(
            createScenarioStep => [
                stepType = StepType.WHEN
                stepName = 'someFunction()'
                function = true
                scenario = scenario1
                stepVariables += createStepVariable => [
                    variable = variableX
                    access = VariableAccess.WRITE
                ]
                stepBody = createLanguageBody => [
                    body = '''
                        Very complex C++ code with all kinds of strange characters
                        !$#&$&@*(&)*%W#{}}|{><><<?/,.,/
                        And of course the variable assignment followed by the function call
                        var «variableX.name» = some value
                        someFunction(«variableX.name»)
                    '''
                ]
            ],
            createScenarioStep => [
                stepName = 'MyAsserts'
                scenario = scenario1
                stepVariables += createStepVariable => [
                    variable = variableX
                    access = VariableAccess.READ
                ]
                stepBody = createLanguageBody => [
                    body = '''
                        assert on «variableX.name»
                    '''
                ]
            ],
            createScenarioStep => [
                stepType = StepType.WHEN
                stepName = 'parameterizedStep(arg1)'
                function = true
                scenario = scenario1
                stepArguments += createAssignmentAction => [
                    assignment = createVariable => [
                        name = '_param1'
                        type = createTypeReference => [
                            type = BasicTypes.stringType
                        ]
                    ]
                    exp = createExpressionConstantString => [
                        value = 'Argument Value'
                    ]
                ]
                stepBody = createLanguageBody => [
                    body = 'call parameterizedStep(_param1)'
                ]
            ]
        )

        val graph = CausalGraphRefinements.createCausalGraph(steps, [new NodeAttributes(function, stepName, stepType)])
        graph.name = 'Example'
        graph.language = 'CPP'

        val resourceSet = new XtextResourceSet
        val resource = resourceSet.createResource(URI.createFileURI('resources/Example.rcg'))
        resource.contents += graph
        resource.save(null)
    }
}