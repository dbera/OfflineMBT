package nl.asml.matala.product.generator;

import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;



import nl.esi.comma.actions.actions.Action;
import nl.esi.comma.actions.actions.AssignmentAction;
import nl.esi.comma.actions.actions.ForAction;
import nl.esi.comma.actions.actions.IfAction;
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator;

public class ValidationHelper {
	
	/**
	 * Get variables based on the action type
	 * */
	
	public static Map<String, Object> action(Action action) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
		    return assignmentAction(a);			
		} 
		else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String record = (new ExpressionsCommaGenerator()).exprToComMASyntax(access.getRecord()).toString();			
			Map<String, Object> map = new HashMap<>();
			map.put("LHS", record); 
			map.put("RHS", a.getExp());
			return map;
		}
		else if(action instanceof IfAction) {
			var act = (IfAction) action;
			var getGuard = act.getGuard();	
			for(var a : act.getThenList().getActions()) {
				return action(a);
			}
			if(act.getElseList()!= null) {
				for(var a : act.getElseList().getActions()) {
					return action(a);
				}
			}
			
		} 
		else if(action instanceof ForAction) {			
			var act = (ForAction) action;
			
			for(var a : act.getDoList().getActions()) {
				return action(a);
			}
			
		}
		Map<String, Object> map = new HashMap<>();		
		return map;
	}
	
	public static Map<String, Object> assignmentAction(AssignmentAction action){
		Map<String, Object> map = new HashMap<>();		
		map.put("LHS", action.getAssignment().getName()); 
		map.put("RHS", action.getExp());
		return map;
	}

}
