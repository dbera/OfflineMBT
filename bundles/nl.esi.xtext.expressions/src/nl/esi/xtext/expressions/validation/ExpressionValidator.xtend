/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.validation

import com.google.inject.Inject
import java.util.List
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionAddition
import nl.esi.xtext.expressions.expression.ExpressionAnd
import nl.esi.xtext.expressions.expression.ExpressionDivision
import nl.esi.xtext.expressions.expression.ExpressionEnumLiteral
import nl.esi.xtext.expressions.expression.ExpressionEqual
import nl.esi.xtext.expressions.expression.ExpressionFunctionCall
import nl.esi.xtext.expressions.expression.ExpressionGeq
import nl.esi.xtext.expressions.expression.ExpressionGreater
import nl.esi.xtext.expressions.expression.ExpressionLeq
import nl.esi.xtext.expressions.expression.ExpressionLess
import nl.esi.xtext.expressions.expression.ExpressionMap
import nl.esi.xtext.expressions.expression.ExpressionMapRW
import nl.esi.xtext.expressions.expression.ExpressionMaximum
import nl.esi.xtext.expressions.expression.ExpressionMinimum
import nl.esi.xtext.expressions.expression.ExpressionMinus
import nl.esi.xtext.expressions.expression.ExpressionModulo
import nl.esi.xtext.expressions.expression.ExpressionMultiply
import nl.esi.xtext.expressions.expression.ExpressionNot
import nl.esi.xtext.expressions.expression.ExpressionOr
import nl.esi.xtext.expressions.expression.ExpressionPackage
import nl.esi.xtext.expressions.expression.ExpressionPlus
import nl.esi.xtext.expressions.expression.ExpressionPower
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.ExpressionSubtraction
import nl.esi.xtext.expressions.expression.ExpressionVector
import nl.esi.xtext.expressions.expression.FunctionDecl
import nl.esi.xtext.expressions.expression.VariableDecl
import nl.esi.xtext.types.BasicTypes
import nl.esi.xtext.types.types.Dimension
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.TypeObject
import nl.esi.xtext.types.types.TypesFactory
import nl.esi.xtext.types.types.VectorTypeConstructor
import nl.esi.xtext.types.types.VectorTypeDecl
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.validation.Check

import static extension nl.esi.xtext.expressions.utilities.ExpressionsUtilities.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*

/*
 * This class mainly captures the XPlus type system for expressions. Constraints are not formulated
 * in text here. Consult the document with the formal definition of the XPlus type system.
 */
class ExpressionValidator extends AbstractExpressionValidator {
	@Inject protected IScopeProvider scopeProvider
	
    static def boolean numeric(TypeObject t) {
        return t.subTypeOf(BasicTypes.getIntType(t)) || t.subTypeOf(BasicTypes.getRealType(t))
    }

   //Type checking
    @Check
    def checkUnusedTemplateVariable(FunctionDecl fd){
        for (tp: fd.typeParams){
            if(fd.params.findFirst[!type.genericsTypeParams.filter[it === tp].empty] === null){
               warning('''Generics type param «tp.name» not used ''',fd, ExpressionPackage.Literals.FUNCTION_DECL__TYPE_PARAMS, fd.typeParams.indexOf(tp))
            }
        }
   }
    
    //Type checking
    @Check
    def checkVariableDecl(VariableDecl vd){
        val lhs = vd.variable.type.typeObject
        var rhs = vd.expression
        if (rhs !== null && !lhs.isAssignableFrom(rhs)) {
            error('''Type mismatch: declared type '«lhs.typeName»' does not match the expected type '«rhs.typeOf.typeName»' ''', ExpressionPackage.Literals.VARIABLE_DECL__VARIABLE)
        }
    }
	
	//Type checking
	@Check
	def checkTypingExpression(Expression e){
		switch(e){
		    ExpressionEqual:{
		        val leftType = e.left.typeOf
		        val rightType = e.right.typeOf
		        if(leftType === null || rightType === null) {return}
		        if(leftType.identical(BasicTypes.anyType) || rightType.identical(BasicTypes.anyType)) {return}
                if(!leftType.synonym(rightType)){
                    error("Type mismatch: actual type does not match the expected type", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
                }
		    }
			ExpressionAnd |
			ExpressionOr : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
		
				if((leftType !== null) && !leftType.identical(BasicTypes.getBoolType(e))){ //use subtype instead!
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
				if((rightType !== null) && !rightType.identical(BasicTypes.getBoolType(e))){
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_BINARY__RIGHT)
				}
			}
			ExpressionNot: {
				val t = e.sub.typeOf
				if((t !== null) && !t.identical(BasicTypes.getBoolType(e))){
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_UNARY__SUB)
				}
			}
			ExpressionLess |
			ExpressionGreater |
			ExpressionLeq |
			ExpressionGeq : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
		
				if(leftType === null || rightType === null) {return}
				if(!leftType.synonym(rightType)){
					error("Arguments must be of compatible types", e.eContainer, e.eContainingFeature)
					return
				}
				if(!leftType.synonym(BasicTypes.getIntType(e)) && !leftType.synonym(BasicTypes.getRealType(e))){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
			}
			ExpressionAddition |
			ExpressionSubtraction | 
			ExpressionMultiply |
			ExpressionDivision |
			ExpressionModulo |
			ExpressionPower |
			ExpressionMinimum |
			ExpressionMaximum : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
				if(leftType === null || rightType === null) {return}
				if(!leftType.synonym(rightType)){
					error("Arguments must be of compatible types", e.eContainer, e.eContainingFeature)
					return
				}
				if(e instanceof ExpressionModulo){
					if(!leftType.synonym(BasicTypes.getIntType(e))){
						error("Type mismatch: expected type int", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
					}
					return
				}
				if(e instanceof ExpressionAddition){
					if(!leftType.synonym(BasicTypes.getIntType(e)) && !leftType.synonym(BasicTypes.getRealType(e)) && !leftType.synonym(BasicTypes.getStringType(e))){
						error("Type mismatch: expected type int, real or string", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
					return
				}
				if(!leftType.synonym(BasicTypes.getIntType(e)) && !leftType.synonym(BasicTypes.getRealType(e))){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
				
			}
			ExpressionMinus |
			ExpressionPlus : {
				val t = e.sub.typeOf
				if((t !== null) && !t.subTypeOf(BasicTypes.getIntType(e)) && !t.subTypeOf(BasicTypes.getRealType(e))){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_UNARY__SUB)
				}
			}
			ExpressionRecord : {
				if(e.fields.size()!=getAllFields(e.type).size()) {
					//error('Wrong number of fields', ExpressionPackage.Literals.EXPRESSION_RECORD__FIELDS)
					//return
				} 
				for(f : e.fields){
				    var counter = e.fields.stream.filter(r| r.recordField.name == f.recordField.name).count
				    if (counter > 1) {
				        error('Duplicated field name', e, ExpressionPackage.Literals.EXPRESSION_RECORD__FIELDS, e.fields.indexOf(f))
				    }
				    for(var i=0; i<getAllFields(e.type).size;i++) {
				        var field = getAllFields(e.type).get(i)
				        if (f.recordField.name.equals(field.name)){
				            //type checking
				            if (!f.exp.typeOf.subTypeOf(field.type.typeObject)){
				                error('Type mismatch', e, ExpressionPackage.Literals.EXPRESSION_RECORD__FIELDS, e.fields.indexOf(f))
				            }
				        }
				    }
				}
				
			}
			ExpressionMapRW : {
				val mapType = e.map.typeOf
				if(mapType === null) {return}
				if(!mapType.isMapType){
					error("Expression is not a map", ExpressionPackage.Literals.EXPRESSION_MAP_RW__MAP)
					return
				}
				val keyType = e.key.typeOf
				if(keyType !== null && !keyType.identical(mapType.keyType)){
					error("Type of expression does not conform to map key type", ExpressionPackage.Literals.EXPRESSION_MAP_RW__KEY)
				}
				if(e.value !== null){
					val valType = e.value.typeOf
					if(valType !== null && !valType.subTypeOf(mapType.valueType)){
						error("Type of expression does not conform to map value type", ExpressionPackage.Literals.EXPRESSION_MAP_RW__VALUE)
					}
				}
			}
			ExpressionMap : {
				if(e.typeAnnotation?.type === null) {return}
				val mapType = e.typeAnnotation.type
				if(! mapType.isMapType){
					error("The type must be a map type", e.typeAnnotation, ExpressionPackage.Literals.TYPE_ANNOTATION__TYPE)
					return
				}
				//check the pairs
				val keyType = mapType.typeObject.keyType
				val valueType = mapType.typeObject.valueType
				for(p : e.pairs){
					val pairKeyType = p.key.typeOf
					val pairValueType = p.value.typeOf
					if(pairKeyType !== null && ! pairKeyType.identical(keyType)){
						error("Type of expression does not conform to map key type", p, ExpressionPackage.Literals.PAIR__KEY)
					}
					if(pairValueType !== null && ! pairValueType.subTypeOf(valueType)){
						error("Type of expression does not conform to map value type", p, ExpressionPackage.Literals.PAIR__VALUE)
					}
				}
			}
			ExpressionVector : {
				if(e.typeAnnotation?.type === null) {return}
				val vectorType = e.typeAnnotation.type
				if(! isVectorType(vectorType)){
					error("The type must be a vector type", e.typeAnnotation, ExpressionPackage.Literals.TYPE_ANNOTATION__TYPE)
					return
				}
				val s = getFirstDimension(vectorType.typeObject)
				if(s > 0 && (e.elements.size != s)){
					error("Expected size of the vector is " + s, ExpressionPackage.Literals.EXPRESSION_VECTOR__ELEMENTS)
					return
				}
				//check the elements
				val expectedType = getBaseTypeToCheck(vectorType.typeObject)
				for(el : e.elements){
					val t = el.typeOf
					if(t !== null && !t.subTypeOf(expectedType))
						error("The element does not conform to the base type", ExpressionPackage.Literals.EXPRESSION_VECTOR__ELEMENTS, e.elements.indexOf(el))
				}
			}
            ExpressionFunctionCall: {
                if (e.function === null || e.function.name === null) {
                    error('''Function declaration not found. Name or number of args («e.args.size») is wrong''', null)
                    return
                }
                if (e.args.size != e.function.params.size) {
                    error('''No Function «e.function.name» declared with «e.args.size» arguments.''', null)
                } else {
                    val ambiguousTypes = e.function.typeParams.filter[tp |tp.getActualFunctionTypes(e).size>1].toList

                    for (var i = 0; i < e.args.size; i++) {
                        val arg = e.args.get(i)
                        val param = e.function.params.get(i)
                        val paramType = param.type.inferActualType(arg)?.typeObject
                        val argType = arg.typeOf
                        if (!argType.subTypeOf(paramType) ) {
                            error('''Function «e.function.name» expects argument «param.name» to be of type «paramType.typeName».''',
                                e, ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, i)
                        }
                        val containedGenerics = param.type.genericsTypeParams
                        val isAmbiguous = !containedGenerics.filter[ambiguousTypes.contains(it)].empty
                        if (isAmbiguous){
                            error('''Function «e.function.name» generic type mismatch typeParam «param.name» resolving is ambiguous''',
                               e,  ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, i)
                        }
                    }
                }
            }
		}
	}
	
	static def getBaseTypeToCheck(TypeObject vt){
		var TypeDecl base
		var List<Dimension> dimensions
		if(vt instanceof VectorTypeDecl){
			base = vt.constructor.type
			dimensions = vt.constructor.dimensions
		}
		else{
			base = (vt as VectorTypeConstructor).type
			dimensions = (vt as VectorTypeConstructor).dimensions
		}
		
		if(dimensions.size == 1){
			base
		}
		else{
			var result = TypesFactory.eINSTANCE.createVectorTypeConstructor
			result.type = base
			for(i : 1..< dimensions.size){
				var newDimension = TypesFactory.eINSTANCE.createDimension
				newDimension.size = dimensions.get(i).size
				result.dimensions.add(newDimension)
			}
			result
		}
	}
	
	//Check some expressions for possible ambiguous types
	
	private def boolean isAmbigousType(EObject context, String typeName, EReference ref){
		var scopeElements = scopeProvider.getScope(context, ref).allElements.filter(od | (od.name.lastSegment == typeName) && (od.name.segmentCount == 1))	
		scopeElements.size > 1
	}
	
	//In order to avoid the code duplication below, the type can be made to refer
	//just to a type declaration and then via validation and scoping make sure that 
	//only the relevant types are bound.
	//For now this is not implemented
	@Check
	def checkDuplicatedEnumTypes(ExpressionEnumLiteral lit){
		if(isAmbigousType(lit, lit.type.name, ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__TYPE))
			error('Several enum types with this name exist. Use an explicit interface name.', ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__TYPE)
	}
	
	@Check
	def checkDuplicatedRecordTypes(ExpressionRecord er){
		if(isAmbigousType(er, er.type.name, ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE))
			error('Several record types with this name exist. Use an explicit interface name.', ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE)
	}
	
}