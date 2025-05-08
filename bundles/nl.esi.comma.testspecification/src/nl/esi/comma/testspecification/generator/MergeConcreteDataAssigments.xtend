package nl.esi.comma.testspecification.generator

import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.utilities.ProposalHelper
import nl.esi.comma.testspecification.testspecification.RefStep
import nl.esi.comma.testspecification.testspecification.TSMain
import nl.esi.comma.testspecification.testspecification.TestDefinition
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension nl.esi.comma.types.utilities.EcoreUtil3.serialize

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
            action.mergeData(assignments.put(action.assignment.serialize, action))
        ]

        val recordFieldAssignments = newHashMap
        refStep.input.actions.filter(RecordFieldAssignmentAction).toList.forEach[ action |
            action.mergeData(recordFieldAssignments.put(action.fieldAccess.serialize, action))
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
            e.printStackTrace
        }
    }

    def private static mergeData(RecordFieldAssignmentAction left, RecordFieldAssignmentAction right) {
        if (left === null || right === null) {
            return
        }
        val recordAccess = right.fieldAccess as ExpressionRecordAccess
        val defaultValue = ProposalHelper.defaultValue(recordAccess.field.type, recordAccess.field.name)
        try {
            right.exp = mergeData(left.exp, right.exp, defaultValue)
            EcoreUtil.delete(left)
        } catch (RuntimeException e) {
            e.printStackTrace
        }
    }

    def dispatch private static Expression mergeData(Expression left, Expression right, String defaultValue) {
        return if (left.serialize == defaultValue) {
            right
        } else if (right.serialize == defaultValue) {
            left
        } else {
            throw new RuntimeException('Cannot merge')
        }
    }

    def dispatch private static Expression mergeData(ExpressionVector left, ExpressionVector right, String defaultValue) {
        right.elements += left.elements
        return right
    }
}