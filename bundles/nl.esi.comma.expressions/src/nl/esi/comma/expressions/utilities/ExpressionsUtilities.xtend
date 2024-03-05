package nl.esi.comma.expressions.utilities

import java.util.HashSet
import java.util.List
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Variable
import org.eclipse.xtext.EcoreUtil2

class ExpressionsUtilities {
	/*
	 * Collects all variables used in a quantifier except the quantifier iterator 
	 * variable
	 */
	def static List<Variable> getReferredVariablesInQuantifier(ExpressionQuantifier exp){
		var result = new HashSet<Variable>
		val allExprVariables = EcoreUtil2::getAllContentsOfType(exp, ExpressionVariable)
		for(v : allExprVariables){
			if(!EcoreUtil2::getAllContainers(v.variable).exists(e | e == exp)){
				result.add(v.variable)
			}
		}
		result.toList
	}	
}