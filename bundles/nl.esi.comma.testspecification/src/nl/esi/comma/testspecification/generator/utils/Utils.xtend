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
package nl.esi.comma.testspecification.generator.utils

import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.serialize

class Utils 
{
    private new() {
        // Empty
    }

    dispatch static def String printField(ExpressionRecordAccess exp) {
        return exp.record.printField + '.' + exp.field.name
    }

    dispatch static def String printField(ExpressionVariable exp) {
        return exp.variable.name
    }

    // Types utilities

    static def Type getOuterDimension(VectorTypeConstructor type) {
        return if (type.dimensions.size > 1) {
            EcoreUtil.copy(type) => [
                dimensions.removeLast
            ]
        } else {
            TypesFactory.eINSTANCE.createTypeReference => [
                type = type.type
            ]
        }
    }

    dispatch static def String getTypeName(TypeReference type) '''
        «type.type.name»'''

    dispatch static def String getTypeName(VectorTypeConstructor type) '''
        «type.type.name»«FOR dimension : type.dimensions»[]«ENDFOR»'''

    dispatch static def String getTypeName(MapTypeConstructor type) '''
        map<«type.type.name», «type.valueType.typeName»>'''

}