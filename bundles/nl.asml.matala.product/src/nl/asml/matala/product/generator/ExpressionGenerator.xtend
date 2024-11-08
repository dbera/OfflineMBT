package nl.asml.matala.product.generator

import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.expressions.expression.ExpressionConstantString

class ExpressionGenerator extends ExpressionsCommaGenerator {

	override dispatch CharSequence exprToComMASyntax(ExpressionConstantString e)
	'''"«e.value.replace("\"", "\\\\\"")»"'''
	
}