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

import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.utilities.ProposalHelper
import nl.esi.comma.testspecification.testspecification.RefStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import nl.esi.comma.expressions.expression.ExpressionNullLiteral

class MergeConcreteDataAssigments {
    def static void transform(Resource resource) {
        resource.contents.filter(TSMain).map[model].filter(TestDefinition).forEach[transform]
    }

    def static void transform(TestDefinition ctd) {
        ctd.stepSeq.flatMap[step].flatMap[refStep].forEach[mergeDataAssignments]
    }

    def private static void mergeDataAssignments(RefStep refStep) {
        val assignments = newHashMap
        refStep.input.actions.filter(AssignmentAction).toList.forEach[ action |
            action.mergeData(assignments.put(action.assignment.serialize(true), action))
        ]

        val recordFieldAssignments = newHashMap
        refStep.input.actions.filter(RecordFieldAssignmentAction).toList.forEach[ action |
            action.mergeData(recordFieldAssignments.put(action.fieldAccess.serialize(true), action))
        ]
    }

    def private static mergeData(AssignmentAction left, AssignmentAction right) {
        if (left === null || right === null) {
            return
        }
        val defaultValue = ProposalHelper.defaultValue(right.assignment.type, right.assignment.name)
        try {
            right.exp = mergeData(left.exp, right.exp, defaultValue)
            EcoreUtil.delete(left)
        } catch (RuntimeException e) {
            System.err.println('Failed to merge values for ' + right.assignment.serialize.unformat)
        }
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
        return if (left.serialize.unformat == defaultValue.unformat || left instanceof ExpressionNullLiteral) {
            right
        } else if (right.serialize.unformat == defaultValue.unformat || right instanceof ExpressionNullLiteral) {
            left
        } else {
            throw new RuntimeException()
        }
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