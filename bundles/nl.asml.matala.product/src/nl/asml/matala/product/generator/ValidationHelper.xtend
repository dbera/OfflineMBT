package nl.asml.matala.product.generator

import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.ForAction
import java.util.List

class ValidationHelper {

    /**
     * Get variables based on the action type
     * */
    
    def static List<Pair<String, Expression>> getActionVariables(Action actionType) {
        switch (actionType) {
            AssignmentAction: {
               var result = new Pair<String, Expression>(actionType.getAssignment().getName(), actionType.getExp())
                 return #[result]
            }
            RecordFieldAssignmentAction: {
                val access = actionType.getFieldAccess() as ExpressionRecordAccess;
                val record = (new ExpressionsCommaGenerator()).exprToComMASyntax(access.getRecord()).toString();
                val rhsExp = actionType.getExp() as Expression;
                var result =  new Pair<String, Expression>(record, rhsExp);
                return #[result]
            }
            IfAction: {
                val results = newArrayList

                for (action : actionType.getThenList()?.getActions() ?: emptyList) {
                    results.addAll(getActionVariables(action))
                }
                if (actionType.getElseList() !== null) {
                    for (action : actionType.getElseList().getActions()) {
                        results.addAll(getActionVariables(action))
                    }
                }
                return results
            }
            ForAction: {
                val results = newArrayList
                for (action : actionType.getDoList()?.getActions()?: emptyList) {
                    results.addAll(getActionVariables(action))
                }
                return  results
            }
        }
    }
}