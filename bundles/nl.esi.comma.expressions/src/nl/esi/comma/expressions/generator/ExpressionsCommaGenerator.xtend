package nl.esi.comma.expressions.generator

import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.types.generator.TypesCommaGenerator
import nl.esi.comma.expressions.expression.ExpressionMap

class ExpressionsCommaGenerator extends TypesCommaGenerator {
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantBool e)
	'''«e.value»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantString e)
	'''"«e.value»"'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantInt e)
	'''«e.value»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionConstantReal e)
	'''«e.value»'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionEnumLiteral e){
		typeToComMASyntax(e.type) + "::" + e.literal.name
	}
	
	def dispatch CharSequence exprToComMASyntax(ExpressionRecord e)
	'''«typeToComMASyntax(e.type)»{«FOR f : e.fields SEPARATOR ', '»«f.recordField.name» = «exprToComMASyntax(f.exp)»«ENDFOR»}'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionVector e)
	'''<«typeToComMASyntax(e.typeAnnotation.type)»>[«FOR el : e.elements SEPARATOR ', '»«exprToComMASyntax(el)»«ENDFOR»]'''
	
	def dispatch CharSequence exprToComMASyntax(ExpressionMap e)
	'''<«typeToComMASyntax(e.typeAnnotation.type)»>{«FOR el : e.pairs SEPARATOR ', '»«exprToComMASyntax(el.key)» -> «exprToComMASyntax(el.value)»«ENDFOR»}'''
	
}