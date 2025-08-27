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

import java.util.HashSet
import java.util.List
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.MapTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import org.eclipse.xtext.EcoreUtil2

import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl

class ExpressionsUtilities {
    static extension val ExpressionFactory EXPRESSION_FACTORY = ExpressionFactory.eINSTANCE

	/*
     * Collects all variables used in a quantifier except the quantifier iterator 
     * variable
     */
    def static List<Variable> getReferredVariablesInQuantifier(ExpressionQuantifier exp) {
        var result = new HashSet<Variable>
        val allExprVariables = EcoreUtil2::getAllContentsOfType(exp, ExpressionVariable)
        for (v : allExprVariables) {
            if (!EcoreUtil2::getAllContainers(v.variable).exists(e|e == exp)) {
                result.add(v.variable)
            }
        }
        result.toList
    }

    def static Expression createDefaultValue(TypeObject typeObj) {
        return switch (typeObj) {
            SimpleTypeDecl case typeObj.name == 'int': createExpressionConstantInt
            SimpleTypeDecl case typeObj.name == 'real': createExpressionConstantReal
            SimpleTypeDecl case typeObj.name == 'bool': createExpressionConstantBool
            SimpleTypeDecl: createExpressionConstantString

            EnumTypeDecl: createExpressionEnumLiteral => [
                type = typeObj
                typeObj.literals.head
            ]

            RecordTypeDecl: createExpressionRecord => [
                type = typeObj
                for(field: typeObj.allFields.reject[symbolic]) {
                    fields += createField => [
                        recordField = field
                        exp = field.type.typeObject.createDefaultValue
                    ]
                }
            ]

            VectorTypeDecl: typeObj.constructor.createDefaultValue
            VectorTypeConstructor: createExpressionVector => [
                val elementType = typeObj.elementType
                typeAnnotation = createTypeAnnotation => [
                    type = elementType.asType
                ]
            ]

            MapTypeDecl: typeObj.constructor.createDefaultValue
            MapTypeConstructor: createExpressionMap => [
                typeAnnotation = createTypeAnnotation => [
                    //type = 
                ]
            ]
        }
    }
}