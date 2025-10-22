package nl.asml.matala.bpmn4s.bpmn4s

import java.io.StringReader
import java.util.List
import java.util.Map
import nl.asml.matala.product.ProductStandaloneSetup
import nl.asml.matala.product.services.ProductGrammarAccess
import nl.esi.comma.actions.services.ActionsGrammarAccess
import nl.esi.comma.assertthat.services.AssertThatGrammarAccess
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.services.ExpressionGrammarAccess
import nl.esi.comma.types.utilities.EcoreUtil3
import org.eclipse.xtext.CrossReference
import org.eclipse.xtext.ParserRule
import org.eclipse.xtext.parser.IParser

class DataExpressionsHelper {
    val IParser parser
    val List<CrossReference> variableReferences

    val ProductGrammarAccess ga_prd
    val AssertThatGrammarAccess ga_ast
    val ActionsGrammarAccess ga_act
    val ExpressionGrammarAccess ga_exp

    new() {
        val injector = new ProductStandaloneSetup().createInjectorAndDoEMFRegistration();
        parser = injector.getInstance(IParser);

        ga_prd = injector.getInstance(ProductGrammarAccess);
        ga_ast = injector.getInstance(AssertThatGrammarAccess);
        ga_act = injector.getInstance(ActionsGrammarAccess);
        ga_exp = injector.getInstance(ExpressionGrammarAccess);

        variableReferences = ga_prd.findCrossReferences(ExpressionPackage.Literals.VARIABLE);
    }

    def String processGuard(String text, Map<String, String> variableMapping) {
        return process(text, ga_exp.expressionRule, variableMapping)
    }

    def String processAssertions(String text, Map<String, String> variableMapping) {
        return process(
            '''
                assertions default {
                    «text»
                }
            ''',
            ga_ast.dataAssertionsRule,
            variableMapping
        )
    }

    def String processInit(String text, Map<String, String> variableMapping) '''
        init
        «process(text, ga_act.actionListRule, variableMapping)»
    '''

    def String processUpdate(String text, Map<String, String> variableMapping) '''
        updates:
            «process(text, ga_act.actionListRule, variableMapping)»
    '''

    def String processSymUpdate(String text, Map<String, String> variableMapping) {
        return process(
            '''

                constraints {
                    «text»
                }''',
            ga_prd.dataConstraintsRule,
            variableMapping
        )
    }

    def String processRefUpdate(String text, Map<String, String> variableMapping) {
        return process(
            '''

                references {
                    «text»
                }''',
            ga_prd.dataReferencesRule,
            variableMapping
        )
    }

    private def String process(CharSequence text, ParserRule rule, Map<String, String> variableMapping) {
        val parseResult = parser.parse(rule, new StringReader(text.toString));
        if (parseResult.rootASTElement === null) {
            return text.toString
        }
        return EcoreUtil3.serializeXtext(parseResult.rootASTElement) [ iNode |
            if (variableReferences.contains(iNode.grammarElement)) {
                return variableMapping.get(iNode.text)
            }
        ]
    }
}
