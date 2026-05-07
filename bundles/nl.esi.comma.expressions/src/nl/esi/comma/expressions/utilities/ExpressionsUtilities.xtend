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
package nl.esi.comma.expressions.utilities

import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Set
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBinary
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFactory
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
import nl.esi.comma.expressions.expression.ExpressionNullLiteral
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.types.BasicTypes
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.GenericsTypeParam
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.MapTypeDecl
import nl.esi.comma.types.types.RecordFieldKind
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.emf.ecore.EObject

import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import nl.esi.comma.types.types.TypeReference

class ExpressionsUtilities {
    static extension val ExpressionFactory EXPRESSION_FACTORY = ExpressionFactory.eINSTANCE

    def static Type asExprType(Type type) {
        return switch (type) {
            VectorTypeConstructor: createVectorTypeConstructor => [
                type = type.type
                dimensions += type.dimensions.copyAll
            ]
            MapTypeConstructor: createMapTypeConstructor => [
                type = type.type
                valueType = type.valueType.asExprType
            ]
            TypeReference: createTypeReference => [
                type = type.type
            ]
            default: throw new RuntimeException('Unsupported type: ' + type.typeName)
        }
    }

    def static Expression createDefaultValue(TypeObject typeObj) {
        return switch (typeObj) {
            SimpleTypeDecl case typeObj.name == 'int': createExpressionConstantInt
            SimpleTypeDecl case typeObj.name == 'real': createExpressionConstantReal
            SimpleTypeDecl case typeObj.name == 'bool': createExpressionConstantBool
            SimpleTypeDecl: createExpressionConstantString => [ value = "" ]

            EnumTypeDecl: createExpressionEnumLiteral => [
                type = typeObj
                typeObj.literals.head
            ]

            RecordTypeDecl: createExpressionRecord => [
                type = typeObj
                for(field: typeObj.allFields.reject[kind == RecordFieldKind::SYMBOLIC]) {
                    fields += createField => [
                        recordField = field
                        exp = field.type.typeObject.createDefaultValue
                    ]
                }
            ]

            VectorTypeDecl: typeObj.constructor.createDefaultValue
            VectorTypeConstructor: createExpressionVector => [
                typeAnnotation = createTypeAnnotation => [ type = typeObj.asExprType ]
            ]

            MapTypeDecl: typeObj.constructor.createDefaultValue
            MapTypeConstructor: createExpressionMap => [
                typeAnnotation = createTypeAnnotation => [ type = typeObj.asExprType ]
            ]
        }
    }
    
        //Type computation. No checking is performed. If the type cannot be determined, null is returned
    def static TypeObject typeOf(Expression e) {
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
            ExpressionGeq : BasicTypes.getBoolType(e)
            ExpressionConstantInt |
            ExpressionModulo : BasicTypes.getIntType(e)
            ExpressionConstantReal : BasicTypes.getRealType(e)
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
                if(t.subTypeOf(BasicTypes.getIntType(e)) || t.subTypeOf(BasicTypes.getRealType(e)))
                    t
                else
                    null
            }
            ExpressionVariable : e.variable?.type.typeObject
            ExpressionConstantString : BasicTypes.getStringType(e)
            ExpressionBracket : e.sub?.typeOf
            ExpressionEnumLiteral : e.type
            ExpressionNullLiteral : BasicTypes.getAnyType(e)
            ExpressionRecord : e.type
            ExpressionRecordAccess : e.field?.type?.typeObject
            ExpressionAny : BasicTypes.getAnyType(e)
            ExpressionFunctionCall : e.inferActualReturnType.typeObject
            ExpressionVector : e.typeAnnotation?.type?.typeObject
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

    /**
     *  Resolve the actual return type
     */
    def static Type inferActualReturnType(ExpressionFunctionCall functionCall) {
        val returnType = functionCall.function.returnType
        val genericsTypeParams = getGenericsTypeParams(returnType)
        if (genericsTypeParams.empty) {
            return returnType
        }
        // Build a map from each generic type param to its resolved actual type
        val resolutionMap = newLinkedHashMap
        for (gtp : genericsTypeParams) {
            val resolved = gtp.getActualFunctionTypes(functionCall)
            if (!resolved.empty) {
                // here we just take the head, there is a validation that raises an error when there are more.
                resolutionMap.put(gtp, resolved.head)
            }
        }
        // Reconstruct the return type with generic params substituted
        return substituteGenerics(returnType, resolutionMap)
    }

    /**
     * Replace the template function param with the actual type
     */
    def static inferActualType(Type type, Expression arg){
        val genericsTypeParams = getGenericsTypeParams(type)
        if (genericsTypeParams.empty) {
            return type
        }
        val argType = arg.typeOf
        if (argType === null) return type
        val resolutionMap = newHashMap
        for (gtp : genericsTypeParams) {
            val matched = newLinkedHashSet
            collectMatchingTypes(type, argType, gtp, matched)
            if (!matched.empty) {
                resolutionMap.put(gtp, matched.head.asType)
            }
        }
        return substituteGenerics(type, resolutionMap)
    }
    
        /**
     *  Resolve the actual return type
     */
    def static List<Type> getActualFunctionTypes(GenericsTypeParam type, ExpressionFunctionCall functionCall) {
        val result = newLinkedHashSet
        val argIter = functionCall.args.iterator
        val parIter = functionCall.function.params.iterator
        while(argIter.hasNext && parIter.hasNext) {
            val arg = argIter.next
            val param = parIter.next
            collectMatchingTypes(param.type, arg.typeOf, type, result)
        }
       return result.map[asType].toList
    }

    def static boolean isAssignableFrom(TypeObject lhs, Expression rhs) {
        TypeUtilities.subTypeOf(lhs, rhs.typeOf) || rhs instanceof ExpressionNullLiteral
    }

    def static TypeObject inferTypeBinaryArithmetic(ExpressionBinary e){
        val leftType = e.left.typeOf
        val rightType = e.right.typeOf
        switch(e){
            ExpressionAddition : {
                if(leftType.subTypeOf(BasicTypes.getIntType(e)) && rightType.subTypeOf(BasicTypes.getIntType(e))) return BasicTypes.getIntType(e)
                if(leftType.subTypeOf(BasicTypes.getRealType(e)) && rightType.subTypeOf(BasicTypes.getRealType(e))) return BasicTypes.getRealType(e)
                if(leftType.subTypeOf(BasicTypes.getStringType(e)) && rightType.subTypeOf(BasicTypes.getStringType(e))) return BasicTypes.getStringType(e)
                return null
            }
            ExpressionSubtraction |
            ExpressionDivision |
            ExpressionPower | 
            ExpressionMultiply |
            ExpressionMinimum |
            ExpressionMaximum : {
                if(leftType.subTypeOf(BasicTypes.getIntType(e)) && rightType.subTypeOf(BasicTypes.getIntType(e))) return BasicTypes.getIntType(e)
                if(leftType.subTypeOf(BasicTypes.getRealType(e)) && rightType.subTypeOf(BasicTypes.getRealType(e))) return BasicTypes.getRealType(e)
                return null
            }
            default : null
        }
    }

    def static List<GenericsTypeParam> getGenericsTypeParams(Type type) {
        val seen = newLinkedHashSet
        val result = newLinkedHashSet
        collect(type, GenericsTypeParam, seen, result)
        return result.toList
    }

    private def static <T extends EObject> void collect(EObject object, Class<T> clazz, Set<EObject> seen, Collection<T> result) {
        if( object === null) {
            return
        }
        if (clazz.isInstance(object)) {
            result.add(clazz.cast(object))
            return
        }
        if (seen.add(object)){
            object.eContents.forEach[collect(it, clazz, seen, result)]
            object.eCrossReferences.forEach[collect(it, clazz, seen, result)]
        }
    }

    /**
     * Recursively substitute generic type parameters in a type structure.
     */
    private def static Type substituteGenerics(Type type, Map<GenericsTypeParam, Type> resolutionMap) {
        if (type === null) return null
        return switch (type) {
            VectorTypeConstructor: createVectorTypeConstructor => [
                type = substituteGenerics(type.typeObject.elementType.asType, resolutionMap).type
                dimensions += type.dimensions.copyAll
            ]
            MapTypeConstructor: createMapTypeConstructor => [
                type = substituteGenerics(type.typeObject.keyType.asType, resolutionMap).type
                valueType = substituteGenerics(type.typeObject.valueType.asType, resolutionMap).asExprType
            ]
            TypeReference: {
                // resolve generics or just the original type decl
                return resolutionMap.getOrDefault(type.type,type)
            }
            default:
               type
        }
    }

    /**
     * Recursively walk the declared parameter type and the actual argument type in parallel,
     * collecting actual types that correspond to the given generic type parameter.
     */
    private def static void collectMatchingTypes(Type declaredType, TypeObject actualType, GenericsTypeParam genParam, Set<TypeObject> result) {
        if (declaredType === null || actualType === null) {
            return
        }
        if (declaredType.isMapType && actualType.isMapType) {
            collectMatchingTypes(declaredType.typeObject.keyType.asType, actualType.keyType, genParam, result)
            collectMatchingTypes(declaredType.typeObject.valueType.asType, actualType.valueType, genParam, result)
        } else if (declaredType.isVectorType && actualType.isVectorType) {
            collectMatchingTypes(declaredType.typeObject.elementType.asType, actualType.elementType, genParam, result)
        } else if (declaredType.type == genParam) {
            result.add(actualType)
        }
    }

    /**
     * Check if a TypeDecl reference matches the generic param; if so, collect the actual type.
     */
    private def static void collectFromTypeDecl(TypeDecl typeDecl, TypeObject actualType, GenericsTypeParam genParam, Set<TypeObject> result) {
        if (typeDecl == genParam && actualType !== null) {
            result.add(actualType)
        }
    }

}