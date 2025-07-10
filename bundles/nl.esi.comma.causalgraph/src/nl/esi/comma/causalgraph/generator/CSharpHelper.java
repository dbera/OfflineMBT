/*
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
package nl.esi.comma.causalgraph.generator;

import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import nl.esi.comma.actions.actions.Action;
import nl.esi.comma.actions.actions.AssignmentAction;
import nl.esi.comma.actions.actions.CommandReply;
import nl.esi.comma.actions.actions.EventCall;
import nl.esi.comma.actions.actions.ForAction;
import nl.esi.comma.actions.actions.FunctionCall;
import nl.esi.comma.actions.actions.IfAction;
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction;
// import nl.esi.comma.behavior.behavior.TriggeredTransition;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionAddition;
import nl.esi.comma.expressions.expression.ExpressionAnd;
import nl.esi.comma.expressions.expression.ExpressionAny;
import nl.esi.comma.expressions.expression.ExpressionBracket;
import nl.esi.comma.expressions.expression.ExpressionBulkData;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionDivision;
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral;
import nl.esi.comma.expressions.expression.ExpressionEqual;
import nl.esi.comma.expressions.expression.ExpressionFnCall;
import nl.esi.comma.expressions.expression.ExpressionFunctionCall;
import nl.esi.comma.expressions.expression.ExpressionGeq;
import nl.esi.comma.expressions.expression.ExpressionGreater;
import nl.esi.comma.expressions.expression.ExpressionLeq;
import nl.esi.comma.expressions.expression.ExpressionLess;
import nl.esi.comma.expressions.expression.ExpressionMap;
import nl.esi.comma.expressions.expression.ExpressionMapRW;
import nl.esi.comma.expressions.expression.ExpressionMaximum;
import nl.esi.comma.expressions.expression.ExpressionMinimum;
import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionModulo;
import nl.esi.comma.expressions.expression.ExpressionMultiply;
import nl.esi.comma.expressions.expression.ExpressionNEqual;
import nl.esi.comma.expressions.expression.ExpressionNot;
import nl.esi.comma.expressions.expression.ExpressionOr;
import nl.esi.comma.expressions.expression.ExpressionPlus;
import nl.esi.comma.expressions.expression.ExpressionPower;
import nl.esi.comma.expressions.expression.ExpressionQuantifier;
import nl.esi.comma.expressions.expression.ExpressionRecord;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.expression.ExpressionSubtraction;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.expressions.expression.QUANTIFIER;
import nl.esi.comma.expressions.expression.Variable;
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator;
import nl.esi.comma.signature.interfaceSignature.DIRECTION;
import nl.esi.comma.types.types.EnumTypeDecl;
import nl.esi.comma.types.types.MapTypeDecl;
import nl.esi.comma.types.types.RecordTypeDecl;
import nl.esi.comma.types.types.SimpleTypeDecl;
import nl.esi.comma.types.types.TypeDecl;
import nl.esi.comma.types.types.VectorTypeDecl;


class CSharpHelper {
	static String defaultValue(TypeDecl type) {
		if (type instanceof SimpleTypeDecl) {
			SimpleTypeDecl t = (SimpleTypeDecl) type;
			if (t.getBase() != null) return defaultValue(t.getBase());
			else if (t.getName().equals("int")) return "0";
			else if (t.getName().equals("real")) return "0.0";
			else if (t.getName().equals("bool")) return "True";
			else if (t.getName().equals("string")) return "\"\"";
			else return "\"\""; // Custom types without base (e.g. type DateTime)
		} else if (type instanceof VectorTypeDecl) {
			return "[]";
		} else if (type instanceof EnumTypeDecl) {
			EnumTypeDecl t = (EnumTypeDecl) type;
			return String.format("\"%s:%s\"", t.getName(), t.getLiterals().get(0).getName());
		} else if (type instanceof MapTypeDecl) {
			return "{}";
		} else if (type instanceof RecordTypeDecl) {
			String value = ((RecordTypeDecl) type).getFields().stream()
				.map(f -> String.format("\"%s\":%s", f.getName(), defaultValue(f.getType().getType())))
				.collect(Collectors.joining(","));
			return String.format("{%s}", value);
		} 
		
		throw new RuntimeException("Not supported");
	}

	static String expression(Expression expression, Function<String, String> variablePrefix) {
		if (expression instanceof ExpressionConstantInt) {
			return Long.toString(((ExpressionConstantInt) expression).getValue());
		} else if (expression instanceof ExpressionConstantString) {
			return String.format("\"%s\"", ((ExpressionConstantString) expression).getValue());
		} else if (expression instanceof ExpressionNot) {
			return String.format("not (%s)", expression(((ExpressionNot) expression).getSub(), variablePrefix));
		} else if (expression instanceof ExpressionConstantReal) {
			return Double.toString(((ExpressionConstantReal) expression).getValue());
		} else if (expression instanceof ExpressionConstantBool) {
			return ((ExpressionConstantBool) expression).isValue() ? "True" : "False";
		} else if (expression instanceof ExpressionAny) {
			return "\"*\"";
		} else if (expression instanceof ExpressionAddition) {
			ExpressionAddition e = (ExpressionAddition) expression;
			return String.format("%s + %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionSubtraction) {
			ExpressionSubtraction e = (ExpressionSubtraction) expression;
			return String.format("%s - %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMultiply) {
			ExpressionMultiply e = (ExpressionMultiply) expression;
			return String.format("%s * %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionDivision) {
			ExpressionDivision e = (ExpressionDivision) expression;
			return String.format("%s / %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionModulo) {
			ExpressionModulo e = (ExpressionModulo) expression;
			return String.format("%s % %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMinimum) {
			ExpressionMinimum e = (ExpressionMinimum) expression;
			return String.format("min(%s, %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMaximum) {
			ExpressionMaximum e = (ExpressionMaximum) expression;
			return String.format("max(%s, %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionPower) {
			ExpressionPower e = (ExpressionPower) expression;
			return String.format("pow(%s, %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionVariable) {
			ExpressionVariable v = (ExpressionVariable) expression;
			// return String.format("%s%s", variablePrefix.apply(v.getVariable().getName()), v.getVariable().getName());
			return String.format("%s", variablePrefix.apply(v.getVariable().getName()));
		} else if (expression instanceof ExpressionGreater) {
			ExpressionGreater e = (ExpressionGreater) expression;
			return String.format("%s > %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLess) {
			ExpressionLess e = (ExpressionLess) expression;
			return String.format("%s < %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLeq) {
			ExpressionLeq e = (ExpressionLeq) expression;
			return String.format("%s <= %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionGeq) {
			ExpressionGeq e = (ExpressionGeq) expression;
			return String.format("%s >= %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEqual) {
			ExpressionEqual e = (ExpressionEqual) expression;
			return String.format("%s == %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionNEqual) {
			ExpressionNEqual e = (ExpressionNEqual) expression;
			return String.format("%s != %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionAnd) {
			ExpressionAnd e = (ExpressionAnd) expression;
			return String.format("%s and %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionOr) {
			ExpressionOr e = (ExpressionOr) expression;
			return String.format("%s or %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEnumLiteral) {
			ExpressionEnumLiteral e = (ExpressionEnumLiteral) expression;
			return String.format("\"%s:%s\"", e.getType().getName(), e.getLiteral().getName());
		} else if (expression instanceof ExpressionVector) {
			ExpressionVector e = (ExpressionVector) expression;
			return String.format("[%s]", e.getElements().stream().map(ee -> expression (ee, variablePrefix)).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMinus) {
			ExpressionMinus e = (ExpressionMinus) expression;
			return String.format("%s * -1", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionPlus) {
			ExpressionPlus e = (ExpressionPlus) expression;
			return expression(e.getSub(), variablePrefix);
		} else if (expression instanceof ExpressionBracket) {
			ExpressionBracket e = (ExpressionBracket) expression;
			//return expression(e.getSub(), variablePrefix);
			return String.format("(%s)", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionFnCall) {
			ExpressionFnCall e = (ExpressionFnCall) expression;
			String str = new String();
			for(Expression arg : e.getArgs()) {
				if(!str.isEmpty()) str += ", ";
				str += expression(arg, variablePrefix);
			}
			String fnName = e.getFunctionName().getName();
			fnName = fnName.replaceAll("_DOT_", ".");
			fnName = fnName.replaceAll("_PTR_", ".");
			fnName = fnName.replaceAll("_SCOPE_", "::");
			fnName = fnName.replaceAll("_REF_", "->");
			return fnName + "(" + str + ")";
		} else if (expression instanceof ExpressionFunctionCall) {
			ExpressionFunctionCall e = (ExpressionFunctionCall) expression;
			if (e.getFunctionName().equals("add")) {
				return String.format("%s + [%s]", expression(e.getArgs().get(0), variablePrefix), expression(e.getArgs().get(1), variablePrefix));
			} else if (e.getFunctionName().equals("size")) {
				return String.format("len(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("isEmpty")) {
				return String.format("len(%s) == 0", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("contains")) {
				return String.format("%s in %s", expression(e.getArgs().get(1), variablePrefix), expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("abs")) {
				return String.format("abs(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("asReal")) {
				return String.format("float(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("hasKey")) {
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("(%s in %s)", key, map);
			} else if (e.getFunctionName().equals("get")) { // added 18.08.2024
				String lst = expression(e.getArgs().get(0), variablePrefix);
				String idx = expression(e.getArgs().get(1), variablePrefix);
				return String.format("%s[%s]", lst, idx);
			} else if (e.getFunctionName().equals("deleteKey")) {
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("{_k: _v for _k, _v in %s.items() if _k != %s}", map, key);
			}
		} else if (expression instanceof ExpressionQuantifier) {
			ExpressionQuantifier e = (ExpressionQuantifier) expression;
			String collection = expression(e.getCollection(), variablePrefix);
			String it = e.getIterator().getName();
			String condition = expression(e.getCondition(), (String variable) -> "");
			if (e.getQuantifier() == QUANTIFIER.EXISTS) {
				return String.format("len([%s for %s in %s if %s]) != 0", it, it, collection, condition);
			} else if (e.getQuantifier() == QUANTIFIER.DELETE) {
				return String.format("[%s for %s in %s if not (%s)]", it, it, collection, condition);
			} else if (e.getQuantifier() == QUANTIFIER.FORALL) {
				return String.format("len([%s for %s in %s if %s]) == len(%s)", it, it, collection, condition, collection);
			}
		} else if (expression instanceof ExpressionMap) {
			ExpressionMap e = (ExpressionMap) expression;
			return String.format("{%s}", e.getPairs().stream().map(p -> {
				String key = expression(p.getKey(), variablePrefix);
				String value = expression(p.getValue(), variablePrefix);
				return String.format("%s: %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW) {
			ExpressionMapRW e = (ExpressionMapRW) expression;
			String map = expression(e.getMap(), variablePrefix);
			String key = expression(e.getKey(), variablePrefix);
			if (e.getValue() == null) {
				return String.format("%s[%s]", map, key);
			} else {
				String value = expression(e.getValue(), variablePrefix);
				return String.format("{**%s, **{%s: %s}}", map, key, value);
			}
		} else if (expression instanceof ExpressionRecord) {
			ExpressionRecord e = (ExpressionRecord) expression;
			return String.format("{%s}", e.getFields().stream().map(p -> {
				String key = p.getRecordField().getName();
				String value = expression(p.getExp(), variablePrefix);
				return String.format("\"%s\": %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionRecordAccess) {
			ExpressionRecordAccess e = (ExpressionRecordAccess) expression;
			String map = expression(e.getRecord(), variablePrefix);
			return String.format("%s[\"%s\"]", map, e.getField().getName());
		} else if (expression instanceof ExpressionBulkData) {
			return "[]";
		} 
		
		throw new RuntimeException("Not supported");
	}
	
//	static List<String> parameters(Object event, Function<String, String> variablePrefix) {
//		if (event instanceof CommandReply) {
//			CommandReply r = (CommandReply) event;
//			return r.getParameters().stream().map(p -> expression(p, variablePrefix)).collect(Collectors.toList());
//		} else if (event instanceof EventCall) {
//			EventCall e = (EventCall) event;
//			return e.getParameters().stream().map(p -> expression(p, variablePrefix)).collect(Collectors.toList());
//		} else if (event instanceof TriggeredTransition) {
//			TriggeredTransition t = (TriggeredTransition) event;
//			return t.getTrigger().getParameters().stream()
//					.filter(p -> p.getDirection() != DIRECTION.OUT)
//					.map(p -> {
//						int index = t.getTrigger().getParameters().indexOf(p);
//						Variable v = t.getParameters().get(index);
//						return String.format("%s%s", variablePrefix.apply(v.getName()), v.getName());
//					})
//					.collect(Collectors.toList());
//		}
//		 
//		throw new RuntimeException("Not supported");
//	}
//
//	static String name(Object event, TriggeredTransition triggerTransition) {
//		if (event instanceof CommandReply) {
//			return triggerTransition.getTrigger().getName() + "_reply";
//		} else if (event instanceof EventCall) {
//			EventCall e = (EventCall) event;
//			return e.getEvent().getName();
//		} else if (event instanceof TriggeredTransition) {
//			TriggeredTransition t = (TriggeredTransition) event;
//			return t.getTrigger().getName();
//		}
//		 
//		throw new RuntimeException("Not supported");
//	}
	
	/*static String action(Action action, Function<String, String> variablePrefix) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
			// String variable = String.format("%s%s", variablePrefix.apply(a.getAssignment().getName()), a.getAssignment().getName());
			String variable = String.format("%s", variablePrefix.apply(a.getAssignment().getName()));
			return String.format("%s = %s", variable, expression(a.getExp(), variablePrefix));
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String record = expression(access.getRecord(), variablePrefix);
			String field = access.getField().getName();
			String value = expression(a.getExp(), variablePrefix);
			return String.format("%s[\"%s\"] = %s", record, field, value);
		} else if(action instanceof IfAction) {
			var txt = new String();
			var act = (IfAction) action;
			txt += String.format("if %s:\n",expression(act.getGuard(), variablePrefix));
			for(var a : act.getThenList().getActions()) {
				txt += String.format("    %s\n", action(a,variablePrefix)); 
			}
			if(act.getElseList()!= null) {
				txt += "else:\n";
				for(var a : act.getElseList().getActions()) {
					txt += String.format("    %s\n", action(a,variablePrefix)); 
				}
			}
			return txt;
		} else if(action instanceof ForAction) {
			var txt = new String();
			var act = (ForAction) action;
			txt += String.format("for %s in %s:\n", act.getVar().getName(), expression(act.getExp(), variablePrefix));
			for(var a : act.getDoList().getActions()) {
				txt += String.format("    %s\n", action(a,variablePrefix));
			}
			return txt;
		}
		
		throw new RuntimeException("Not supported");
	}*/

//	static boolean isSymbolicAction(Action action) {
//		if (action instanceof AssignmentAction) {
//			AssignmentAction a = (AssignmentAction) action;
//			if(a.isSymbolic()) return true;
//			
//		} else if (action instanceof RecordFieldAssignmentAction) {
//			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
//			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
//			
//		} else if(action instanceof IfAction) {
//			var act = (IfAction) action;
//			if(act.getElseList()!= null) {
//				
//			}
//		} else if(action instanceof ForAction) {
//			
//		}
//		
//		return false;
//	}
	
	static String action(Action action, Function<String, String> variablePrefix, String indent) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
			String QUOTE = "\"";
			// String variable = String.format("%s%s", variablePrefix.apply(a.getAssignment().getName()), a.getAssignment().getName());
			String variable = String.format("%s", variablePrefix.apply(a.getAssignment().getName()));
			// if(a.isSymbolic()) return String.format("%s = %s%s%s", variable, QUOTE, expression(a.getExp(), variablePrefix).replace("\"", "\\\""), QUOTE);
			if(a.isSymbolic()) return String.format("%s = %s%s%s", variable, QUOTE, (new ExpressionsCommaGenerator()).exprToComMASyntax(a.getExp()).toString(), QUOTE);
			// else return String.format("%s = %s", variable, expression(a.getExp(), variablePrefix));
			else return String.format("%s = %s%s%s", variable, QUOTE, (new ExpressionsCommaGenerator()).exprToComMASyntax(a.getExp()).toString(), QUOTE);
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String QUOTE = "\"";
			if(a.isSymbolic()) {
				String record = (new ExpressionsCommaGenerator()).exprToComMASyntax(access.getRecord()).toString();
				String field = access.getField().getName();
				String value = (new ExpressionsCommaGenerator()).exprToComMASyntax(a.getExp()).toString();
				return String.format("%s.%s = %s%s%s", record, field, QUOTE, value, QUOTE);
				// return QUOTE + (new ActionsUmlGenerator()).generateAction(a).toString() + QUOTE;
			} else {
				String record = expression(access.getRecord(), variablePrefix);
				String field = access.getField().getName();
				String value = expression(a.getExp(), variablePrefix);
				return String.format("%s[\"%s\"] = %s", record, field, value);
			}
		} else if(action instanceof IfAction) {
			var txt = new String();
			var indent_level = indent + "	";
			var act = (IfAction) action;
			txt += String.format("if %s:\n",expression(act.getGuard(), variablePrefix));
			for(var a : act.getThenList().getActions()) {
				txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level)); 
			}
			if(act.getElseList()!= null) {
				txt += "else:\n";
				for(var a : act.getElseList().getActions()) {
					txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level)); 
				}
			}
			return txt.trim();
		} else if(action instanceof ForAction) {
			var txt = new String();
			var indent_level = indent + "	";
			var act = (ForAction) action;
			txt += String.format("for %s in %s:\n", act.getVar().getName(), expression(act.getExp(), variablePrefix));
			for(var a : act.getDoList().getActions()) {
				txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level));
			}
			return txt.trim();
		} else if(action instanceof FunctionCall) {
			var act = (FunctionCall) action;
			//return expression(act.getExp(), variablePrefix);
			return (new ExpressionsCommaGenerator()).exprToComMASyntax(act.getExp()).toString();
		} 
		
		throw new RuntimeException("Not supported");
	}

	static String commaAction(Action action, Function<String, String> variablePrefix, String indent) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
			String QUOTE = "";
			String variable = String.format("%s", variablePrefix.apply(a.getAssignment().getName()));
			return String.format("%s = %s%s%s", variable, QUOTE, (new ExpressionsCommaGenerator()).exprToComMASyntax(a.getExp()).toString(), QUOTE); //.replace("\"", "\\\"")
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String QUOTE = "";
			String record = (new ExpressionsCommaGenerator()).exprToComMASyntax(access.getRecord()).toString();
			String field = access.getField().getName();
			String value = (new ExpressionsCommaGenerator()).exprToComMASyntax(a.getExp()).toString();
			return String.format("%s.%s = %s%s%s", record, field, QUOTE, value, QUOTE); //.replace("\"", "\\\"")
		} else if(action instanceof IfAction) {
			var txt = new String();
			var indent_level = indent + "	";
			var act = (IfAction) action;
			txt += String.format("if %s:\n",expression(act.getGuard(), variablePrefix));
			for(var a : act.getThenList().getActions()) {
				txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level)); 
			}
			if(act.getElseList()!= null) {
				txt += "else:\n";
				for(var a : act.getElseList().getActions()) {
					txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level)); 
				}
			}
			return txt.trim();
		} else if(action instanceof ForAction) {
			var txt = new String();
			var indent_level = indent + "	";
			var act = (ForAction) action;
			txt += String.format("for %s in %s:\n", act.getVar().getName(), expression(act.getExp(), variablePrefix));
			for(var a : act.getDoList().getActions()) {
				txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level));
			}
			return txt.trim();
		} else if(action instanceof FunctionCall) {
			var act = (FunctionCall) action;
			// return expression(act.getExp(), variablePrefix);
			return (new ExpressionsCommaGenerator()).exprToComMASyntax(act.getExp()).toString();
		}
		
		throw new RuntimeException("Not supported");
	}

}
