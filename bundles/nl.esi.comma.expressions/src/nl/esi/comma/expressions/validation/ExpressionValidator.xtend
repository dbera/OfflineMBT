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
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBinary
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
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
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.InterfaceAwareType
import nl.esi.comma.expressions.expression.QUANTIFIER
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.types.Dimension
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.TypesPackage
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.validation.Check

import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import nl.esi.comma.expressions.expression.ExpressionFnCall
import static nl.esi.comma.types.utilities.TypeUtilities.subTypeOf

/*
 * This class mainly captures the ComMA type system for expressions. Constraints are not formulated
 * in text here. Consult the document with the formal definition of the ComMA type system.
 */
class ExpressionValidator extends AbstractExpressionValidator {
	@Inject protected IScopeProvider scopeProvider
	
    protected static val SimpleTypeDecl anyType = TypeUtilities.ANY_TYPE;

	protected static val SimpleTypeDecl boolType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
	    name = 'bool'
	]
	protected static val SimpleTypeDecl intType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
        name = 'int'
    ]
	protected static val SimpleTypeDecl realType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
        name = 'real'
    ]
	protected static val SimpleTypeDecl stringType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
        name = 'string'
    ]
	protected static val SimpleTypeDecl voidType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
        name = 'void'
    ]
	protected static val SimpleTypeDecl idType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
        name = 'id'
    ]
	protected static val SimpleTypeDecl bulkdataType = TypesFactory.eINSTANCE.createSimpleTypeDecl() => [
        name = 'bulkdata'
    ]

    static def boolean numeric(TypeObject t) {
        return t.subTypeOf(intType) || t.subTypeOf(realType)
    }
	
	//Type computation. No checking is performed. If the type cannot be determined, null is returned
	static def TypeObject typeOf(Expression e) {
		if(e === null) return null
		switch(e){
			ExpressionConstantBool |
			ExpressionAnd |
			ExpressionOr |
			ExpressionNot |
			ExpressionEqual |
			ExpressionNEqual |
			ExpressionLess |
			ExpressionGreater |
			ExpressionLeq |
			ExpressionGeq : boolType
			ExpressionConstantInt |
			ExpressionModulo : intType
			ExpressionConstantReal : realType
			ExpressionAddition |
			ExpressionSubtraction |
			ExpressionDivision | 
			ExpressionMultiply |
			ExpressionPower |
			ExpressionMinimum |
			ExpressionMaximum : inferTypeBinaryArithmetic(e)
			ExpressionMinus |
			ExpressionPlus : {
				val t = e.sub.typeOf
				if(t.subTypeOf(intType) || t.subTypeOf(realType))
					t
				else
					null
			}
			ExpressionVariable : e.variable?.type.typeObject
			ExpressionConstantString : stringType
			ExpressionBracket : e.sub?.typeOf
			ExpressionEnumLiteral : e.type
			ExpressionRecord : e.type
			ExpressionRecordAccess : e.field?.type?.typeObject
			ExpressionBulkData : bulkdataType
			ExpressionAny : anyType
			ExpressionFnCall : e.function.returnType.type
			ExpressionFunctionCall : ExpressionFunction.valueOf(e)?.inferType(e.args, ExpressionFunction.RETURN_ARG)
			ExpressionVector : e.typeAnnotation?.type?.typeObject
			ExpressionQuantifier : {
				if(e.quantifier == QUANTIFIER::DELETE)
					e.collection.typeOf
				else
					boolType
			}
			ExpressionMap : e.typeAnnotation?.type?.typeObject
			ExpressionMapRW : {
				val t = e.map.typeOf
				if(t !== null && t.mapType)
					if(e.value !== null){
						t
					}else{
						t.valueType
					}
				else
					null
			}
			
		}
	}
		
	static def TypeObject inferTypeBinaryArithmetic(ExpressionBinary e){
		val leftType = e.left.typeOf
		val rightType = e.right.typeOf
		switch(e){
			ExpressionAddition : {
				if(leftType.subTypeOf(intType) && rightType.subTypeOf(intType)) return intType
				if(leftType.subTypeOf(realType) && rightType.subTypeOf(realType)) return realType
				if(leftType.subTypeOf(stringType) && rightType.subTypeOf(stringType)) return stringType
				return null
			}
			ExpressionSubtraction |
			ExpressionDivision |
			ExpressionPower | 
			ExpressionMultiply |
			ExpressionMinimum |
			ExpressionMaximum : {
				if(leftType.subTypeOf(intType) && rightType.subTypeOf(intType)) return intType
				if(leftType.subTypeOf(realType) && rightType.subTypeOf(realType)) return realType
				return null
			}
			default : null
		}
	}
	
	//Type checking
	
	@Check
	def checkTypingExpression(Expression e){
		switch(e){
		    ExpressionEqual:{
		        val leftType = e.left.typeOf
		        val rightType = e.right.typeOf
                if(leftType != rightType){
                    error("Type mismatch: actual type does not match the expected type", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
                }
		    }
			ExpressionAnd |
			ExpressionOr : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
		
				if((leftType !== null) && !leftType.identical(boolType)){ //use subtype instead!
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
				if((rightType !== null) && !rightType.identical(boolType)){
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_BINARY__RIGHT)
				}
			}
			ExpressionNot: {
				val t = e.sub.typeOf
				if((t !== null) && !t.identical(boolType)){
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
				if(!leftType.synonym(intType) && !leftType.synonym(realType)){
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
					if(!leftType.synonym(intType)){
						error("Type mismatch: expected type int", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
					}
					return
				}
				if(e instanceof ExpressionAddition){
					if(!leftType.synonym(intType) && !leftType.synonym(realType) && !leftType.synonym(stringType)){
						error("Type mismatch: expected type int, real or string", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
					return
				}
				if(!leftType.synonym(intType) && !leftType.synonym(realType)){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
				
			}
			ExpressionMinus |
			ExpressionPlus : {
				val t = e.sub.typeOf
				if((t !== null) && !t.subTypeOf(intType) && !t.subTypeOf(realType)){
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
			ExpressionFunctionCall : {
			    val func = ExpressionFunction.valueOf(e)
			    if (func === null) {
			        error("Unknown function", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			    } else {
			        switch (result: func.validate(e.args)) {
			        	case null: { /* No Error */ }
			        	case result.key < 0: error(result.value, ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			        	default: error(result.value, ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, result.key)
			        }
			    }
			}
            ExpressionFnCall: {
                if (e.args.size != e.function.params.size) {
                    error('''Function «e.function.name» expects «e.function.params.size» arguments.''', null)
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
			//TODO consider adding a new check if the type of the iterator is compatible with the type of
			//the vector elements
			ExpressionQuantifier: {
				val collectionType = e.collection.typeOf
				if(collectionType !== null && !isVectorType(collectionType))
					error("Expression must be of type vector", ExpressionPackage.Literals.EXPRESSION_QUANTIFIER__COLLECTION)
				val condType = e.condition.typeOf
				if(condType !== null && !condType.subTypeOf(boolType))
					error("Condition expression must be of type boolean", ExpressionPackage.Literals.EXPRESSION_QUANTIFIER__CONDITION)
	
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
		if(lit.interface === null){
			if(isAmbigousType(lit, lit.type.name, ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__TYPE))
				error('Several enum types with this name exist. Use an explicit interface name.', ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__TYPE)
		}
	}
	
	@Check
	def checkDuplicatedRecordTypes(ExpressionRecord er){
		if(er.interface === null){
			if(isAmbigousType(er, er.type.name, ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE))
				error('Several record types with this name exist. Use an explicit interface name.', ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE)
		}
	}
	
	@Check
	def checkDuplicatedTypeInTypeReference(InterfaceAwareType type){
		var String name = (type as Type).type.name
		var EReference ref = TypesPackage.Literals.TYPE__TYPE
		var Signature i = (type as InterfaceAwareType).interface
		
		if(i === null){
			if(isAmbigousType(type, name, ref))
				error('Several types with this name exist. Use an explicit interface name.', ref)
		}
	}	
}