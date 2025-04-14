package nl.asml.matala.product.generator

import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.ForAction

class ValidationHelper {

    /**
     * Get variables based on the action type
     * */
    
    def static Pair<String, Expression> getActionVariables(Action actionType) {
        switch (actionType) {
            AssignmentAction: {
                return getAssignmentActionVar(actionType);
            }
            RecordFieldAssignmentAction: {
                val access = actionType.getFieldAccess() as ExpressionRecordAccess;
                val record = (new ExpressionsCommaGenerator()).exprToComMASyntax(access.getRecord()).toString();
                val rhsExp = actionType.getExp() as Expression;
                return new Pair<String, Expression>(record, rhsExp);
            }
            IfAction: {
                for (a : actionType.getThenList().getActions()) {
                    return getActionVariables(a);
                }
                if (actionType.getElseList() !== null) {
                    for (a : actionType.getElseList().getActions()) {
                        return getActionVariables(a);
                    }
                }
            }
            ForAction: {
                for (a : actionType.getDoList().getActions()) {
                    return getActionVariables(a);
                }
            }
        }
    }

    def static Pair<String, Expression> getAssignmentActionVar(AssignmentAction AssinmentExpression) {
        return new Pair<String, Expression>(AssinmentExpression.getAssignment().getName(), AssinmentExpression.getExp())
    }
}
