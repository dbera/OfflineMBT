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
package nl.esi.comma.assertthat.utilities

import java.math.BigDecimal
import java.math.BigInteger
import nl.esi.comma.assertthat.assertThat.JsonArray
import nl.esi.comma.assertthat.assertThat.JsonExpression
import nl.esi.comma.assertthat.assertThat.JsonObject
import nl.esi.comma.assertthat.assertThat.JsonValue
import nl.esi.comma.expressions.evaluation.IEvaluationContext
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.expressions.utilities.ExpressionsUtilities
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeObject

import static extension nl.esi.comma.types.utilities.TypeUtilities.*

class AssertThatUtilities {
    static extension val ExpressionFactory m_expr = ExpressionFactory.eINSTANCE

    private new() {
        // Private constructor for utilities
    }

    static def Expression toExpression(JsonValue json, TypeObject typeObject, IEvaluationContext context) {
        return switch (json) {
            case null: null
            JsonExpression: json.expr
            JsonObject case typeObject.isRecordType:
                createExpressionRecord => [ rec |
                    rec.type = typeObject as RecordTypeDecl
                    rec.fields += json.members.map [ mbr |
                        createField => [ fld |
                            fld.recordField = rec.type.fields.findFirst[name == mbr.key]
                            if (fld.recordField === null) {
                                throw new RuntimeException('''Unknown record field '«mbr.key»' for type «typeObject.typeName»''')
                            }
                            fld.exp = mbr.value.toExpression(fld.recordField.type.typeObject, context)
                        ]
                    ]
                ]
            JsonObject case typeObject.isMapType:
                createExpressionMap => [ map |
                    map.typeAnnotation = createTypeAnnotation => [
                        type = ExpressionsUtilities.asExprType(typeObject.asType)
                    ]
                    map.pairs += json.members.map [ mbr |
                        createPair => [ pair |
                            pair.key = mbr.key.toExpression(typeObject.keyType, context)
                            pair.value = mbr.value.toExpression(typeObject.valueType, context)
                        ]
                    ]
                ]
            JsonArray case typeObject.isVectorType:
                createExpressionVector => [ vec |
                    vec.typeAnnotation = createTypeAnnotation => [
                        type = ExpressionsUtilities.asExprType(typeObject.asType)
                    ]
                    vec.elements += json.values.map[toExpression(typeObject.elementType, context)]
                ]
            default:
                throw new RuntimeException('''Unsupported value '«json»' for type «typeObject.typeName»''')
        }
    }

    private static def Expression toExpression(String keyValue, TypeObject keyType, extension IEvaluationContext context) {
        return switch (keyType) {
            SimpleTypeDecl case keyType.base !== null: toExpression(keyValue, keyType.base, context)
            SimpleTypeDecl case keyType.name == 'int': new BigInteger(keyValue).toIntExpr
            SimpleTypeDecl case keyType.name == 'real': new BigDecimal(keyValue).toRealExpr
            SimpleTypeDecl case keyType.name == 'bool': Boolean.parseBoolean(keyValue).toBoolExpr
            SimpleTypeDecl case keyType.name == 'string': keyValue.toStringExpr
            EnumTypeDecl: createExpressionEnumLiteral => [
                type = keyType
                literal = keyType.literals.findFirst[name == value]
            ]
            default:
                throw new RuntimeException('''Unsupported value '«keyValue»' for type «keyType.typeName»''')
        }
    }
}