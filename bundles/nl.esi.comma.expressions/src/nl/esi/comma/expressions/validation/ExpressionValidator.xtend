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
package nl.esi.comma.expressions.validation

import com.google.inject.Inject
import java.util.List
import nl.esi.comma.expressions.evaluation.IEvaluationContext
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFnCall
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.expressions.functions.ExpressionFunctionsRegistry
import nl.esi.comma.types.BasicTypes
import nl.esi.comma.types.types.Dimension
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.validation.Check

import static extension nl.esi.comma.expressions.utilities.ExpressionsUtilities.*
import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import nl.esi.comma.expressions.expression.VariableDecl
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.SimpleTypeDecl

/*
 * This class mainly captures the ComMA type system for expressions. Constraints are not formulated
 * in text here. Consult the document with the formal definition of the ComMA type system.
 */
class ExpressionValidator extends AbstractExpressionValidator {
	@Inject protected IScopeProvider scopeProvider
	@Inject ExpressionFunctionsRegistry registry
	IEvaluationContext evaluationContext = new IEvaluationContext(){
    
    override getExpression(Variable variable) {
        throw new UnsupportedOperationException("TODO: auto-generated method stub")
    }
	    
	}
	
    static def boolean numeric(TypeObject t) {
        return t.subTypeOf(BasicTypes.getIntType(t)) || t.subTypeOf(BasicTypes.getRealType(t))
    }


    //Type checking
    @Check
    def checkVariableDecl(VariableDecl vd){
        val lhs = vd.variable.type.typeObject
        var rhs = typeOf(vd.expression)
        if (lhs instanceof SimpleTypeDecl){
            if(rhs instanceof MapTypeConstructor) {
                rhs = rhs.valueType.typeObject
            }
        }
        if (rhs !== null && !subTypeOf(lhs,rhs)) {
            error('''Type mismatch: declared type '«lhs.typeName»' does not match the expected type '«rhs.typeName»' ''', ExpressionPackage.Literals.VARIABLE_DECL__VARIABLE)
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
            ExpressionFnCall: {
                if (e.function === null || e.function.name === null) {
                    error('''Function declaration not found. Name or number of args («e.args.size») is wrong''', null)
                    return
                }
                if (e.args.size != e.function.params.size) {
                    error('''No Function «e.function.name» declared with «e.args.size» arguments.''', null)
                } else {
                    for (var i = 0; i < e.args.size; i++) {
                        val paramType = e.function.params.get(i).type.typeObject
                        val argType = typeOf(e.args.get(i))
                        if (!subTypeOf(argType, paramType)) {
                            error('''Function «e.function.name» expects argument «i + 1» to be of type «paramType.typeName».''',
                                ExpressionPackage.Literals.EXPRESSION_FN_CALL__ARGS, i)
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