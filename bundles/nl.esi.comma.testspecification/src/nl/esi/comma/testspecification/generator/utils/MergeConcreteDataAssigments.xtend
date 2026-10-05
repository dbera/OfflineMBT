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

import nl.esi.comma.testspecification.testspecification.AbstractStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction
import nl.esi.xtext.expressions.expression.Expression
import nl.esi.xtext.expressions.expression.ExpressionMap
import nl.esi.xtext.expressions.expression.ExpressionNullLiteral
import nl.esi.xtext.expressions.expression.ExpressionRecord
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess
import nl.esi.xtext.expressions.expression.ExpressionVector
import nl.esi.xtext.expressions.utilities.ProposalHelper
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import java.util.ArrayList

class MergeConcreteDataAssigments {
    def static void transform(Resource resource) {
        resource.contents.filter(TSMain).map[model].filter(TestDefinition).forEach[transform]
    }

    def static void transform(TestDefinition ctd) {
        ctd.stepSeq.flatMap[step].forEach[mergeDataAssignments]
    }

    def private static void mergeDataAssignments(AbstractStep step) {
        val inputAssignments = newHashMap
        new ArrayList(step.input).forEach[ action |
            action.mergeData(inputAssignments.putIfAbsent(action.fieldAccess.serialize(true), action))
        ]
    }

    def private static mergeData(RecordFieldAssignmentAction left, RecordFieldAssignmentAction right) {
        if (left === null || right === null) {
            return
        }
        val recordAccess = right.fieldAccess as ExpressionRecordAccess
        val defaultValue = ProposalHelper.defaultValue(recordAccess.field.type, recordAccess.field.name)
        try {
            //println('''mergeData(«left.exp.serialize.unformat», «right.exp.serialize.unformat», «defaultValue.unformat»)''')
            right.exp = mergeData(left.exp, right.exp, defaultValue)
            EcoreUtil.delete(left)
        } catch (RuntimeException e) {
            System.err.println('Failed to merge values for ' + recordAccess.serialize.unformat)
        }
    }

    def dispatch private static Expression mergeData(Expression left, Expression right, String defaultValue) {
        if (left instanceof ExpressionNullLiteral) {
            return right
        }
        if (right instanceof ExpressionNullLiteral) {
            return left
        }
        val unfDefault = defaultValue.unformat
        val unfLeft = left.serialize.unformat
        if (unfLeft == unfDefault) {
            return right
        }
        val unfRight = right.serialize.unformat
        if (unfRight == unfDefault) {
            return left
        }
        if (unfLeft == unfRight) {
            return left
        }
        throw new RuntimeException('Cannot merge')
    }

    def dispatch private static Expression mergeData(ExpressionVector left, ExpressionVector right, String defaultValue) {
        right.elements += left.elements
        return right
    }

    def dispatch private static Expression mergeData(ExpressionMap left, ExpressionMap right, String defaultValue) {
        right.pairs += left.pairs
        return right
    }

    def dispatch private static Expression mergeData(ExpressionRecord left, ExpressionRecord right, String defaultValue) {
        val leftFields = left.fields.toMap[recordField]
        for (rightField : right.fields) {
            val leftField = leftFields.remove(rightField.recordField)
            if (leftField !== null) {
                val fieldDefaultValue = ProposalHelper.defaultValue(rightField.recordField.type, rightField.recordField.name)
                rightField.exp = mergeData(leftField.exp, rightField.exp, fieldDefaultValue)
            }
        }
        right.fields += leftFields.values
        return right
    }

    def private static String unformat(String text) {
        return text.trim.replaceAll("\\s+", "");
    }
}