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
package nl.asml.matala.product.generator;

import static nl.esi.xtext.common.lang.utilities.EcoreUtil3.serialize;

import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import nl.esi.comma.actions.actions.Action;
import nl.esi.comma.actions.actions.AssignmentAction;
import nl.esi.comma.actions.actions.ForAction;
import nl.esi.comma.actions.actions.IfAction;
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionAddition;
import nl.esi.comma.expressions.expression.ExpressionAnd;
import nl.esi.comma.expressions.expression.ExpressionAny;
import nl.esi.comma.expressions.expression.ExpressionBracket;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionDivision;
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral;
import nl.esi.comma.expressions.expression.ExpressionEqual;
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
import nl.esi.comma.expressions.expression.ExpressionNullLiteral;
import nl.esi.comma.expressions.expression.ExpressionOr;
import nl.esi.comma.expressions.expression.ExpressionPlus;
import nl.esi.comma.expressions.expression.ExpressionPower;
import nl.esi.comma.expressions.expression.ExpressionRecord;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.expression.ExpressionSubtraction;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;
import nl.esi.comma.types.types.EnumTypeDecl;
import nl.esi.comma.types.types.MapTypeConstructor;
import nl.esi.comma.types.types.MapTypeDecl;
import nl.esi.comma.types.types.RecordFieldKind;
import nl.esi.comma.types.types.RecordTypeDecl;
import nl.esi.comma.types.types.SimpleTypeDecl;
import nl.esi.comma.types.types.Type;
import nl.esi.comma.types.types.TypeDecl;
import nl.esi.comma.types.types.VectorTypeConstructor;
import nl.esi.comma.types.types.VectorTypeDecl;
import nl.esi.comma.types.utilities.TypeUtilities;

class SnakesHelper {
	static String defaultValue(Type type, String targetName) {
		// TypeReference | VectorTypeConstructor | MapTypeConstructor
		if (type instanceof VectorTypeConstructor) {
			return "[]";
		} else if (type instanceof MapTypeConstructor) {
			return "{}";
		} else {
			return defaultValue(type.getType(), targetName);
		}
	}

	static String defaultValue(TypeDecl type, String targetName) {
		if (type instanceof SimpleTypeDecl) {
			SimpleTypeDecl t = (SimpleTypeDecl) type;
			if (t.getBase() != null) return defaultValue(t.getBase(), targetName);
			else if (t.getName().equals("int")) return "0";
			else if (t.getName().equals("real")) return "0.0";
			else if (t.getName().equals("bool")) return "True";
			else if (t.getName().equals("string")) return "\"\"";
			else return "\"\""; // Custom types without base (e.g. type DateTime)
		} else if (type instanceof VectorTypeDecl) {
			return "[]";
		} else if (type instanceof EnumTypeDecl) {
			EnumTypeDecl t = (EnumTypeDecl) type;
			return String.format("\"%s::%s\"", t.getName(), t.getLiterals().get(0).getName());
		} else if (type instanceof MapTypeDecl) {
			return "{" + 
					defaultValue(((MapTypeDecl) type).getConstructor().getType(), targetName) + 
					":" +
					defaultValue(((MapTypeDecl) type).getConstructor().getValueType().getType(), targetName) +
					"}";
		} else if (type instanceof RecordTypeDecl recType) {
			String value = TypeUtilities.getAllFields(recType).stream()
				.filter(f -> !RecordFieldKind.SYMBOLIC.equals(f.getKind()))
				.map(f -> String.format("\"%s\":%s", f.getName(), defaultValue(f.getType(), f.getName())))
				.collect(Collectors.joining(","));
			return String.format("{%s}", value);
		} 
		
		throw new RuntimeException("Not supported");
	}

	static String expression(Expression expression, Function<String, String> variablePrefix) {
		if (expression instanceof ExpressionConstantInt e) {
			return Long.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantString e) {
			String value = e.getValue();
			return String.format("\"%s\"", value == null ? "" : value.replace("\"", "\\\""));
		} else if (expression instanceof ExpressionNot e) {
			return String.format("not (%s)", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionConstantReal e) {
			return Double.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantBool e) {
			return e.isValue() ? "True" : "False";
		} else if (expression instanceof ExpressionAny) {
			return "\"*\"";
		} else if (expression instanceof ExpressionAddition e) {
			return String.format("%s + %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionSubtraction e) {
			return String.format("%s - %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMultiply e) {
			return String.format("%s * %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionDivision e) {
			return String.format("%s / %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionModulo e) {
			return String.format("%s %% %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMinimum e) {
			return String.format("min(%s, %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMaximum e) {
			return String.format("max(%s, %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionPower e) {
			return String.format("pow(%s, %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionVariable e) {
			return String.format("%s", variablePrefix.apply(e.getVariable().getName()));
		} else if (expression instanceof ExpressionGreater e) {
			return String.format("%s > %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLess e) {
			return String.format("%s < %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLeq e) {
			return String.format("%s <= %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionGeq e) {
			return String.format("%s >= %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEqual e) {
			return String.format("%s == %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionNEqual e) {
			return String.format("%s != %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionAnd e) {
			return String.format("%s and %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionOr e) {
			return String.format("%s or %s", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEnumLiteral e) {
			return String.format("\"%s::%s\"", e.getType().getName(), e.getLiteral().getName());
		} else if (expression instanceof ExpressionNullLiteral) {
			return "None";
		} else if (expression instanceof ExpressionVector e) {
			return String.format("[%s]", e.getElements().stream().map(ee -> expression (ee, variablePrefix)).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMinus e) {
			return String.format("%s * -1", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionPlus e) {
			return expression(e.getSub(), variablePrefix);
		} else if (expression instanceof ExpressionBracket e) {
			return String.format("(%s)", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionFunctionCall e) {
			var fnName = e.getFunction().getName();
			if (fnName.equals("add")) {
				return String.format("%s + [%s]", expression(e.getArgs().get(0), variablePrefix), expression(e.getArgs().get(1), variablePrefix));
			} else if (fnName.equals("size")) {
				return String.format("len(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (fnName.equals("isEmpty")) {
				return String.format("len(%s) == 0", expression(e.getArgs().get(0), variablePrefix));
			} else if (fnName.equals("contains")) {
				return String.format("%s in %s", expression(e.getArgs().get(1), variablePrefix), expression(e.getArgs().get(0), variablePrefix));
			} else if (fnName.equals("abs")) {
				return String.format("abs(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (fnName.equals("asReal")) {
				return String.format("float(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (fnName.equals("hasKey")) {
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("(%s in %s)", key, map);
			} else if (fnName.equals("get")) { // added 18.08.2024
				String lst = expression(e.getArgs().get(0), variablePrefix);
				String idx = expression(e.getArgs().get(1), variablePrefix);
				return String.format("%s[%s]", lst, idx);
			} else if (fnName.equals("at")) {
				String lst = expression(e.getArgs().get(0), variablePrefix);
				String idx = expression(e.getArgs().get(1), variablePrefix);
				String val = expression(e.getArgs().get(2), variablePrefix);
				return String.format("%s; %s[%s] = %s", lst, lst, idx, val);
			} else if (fnName.equals("deleteKey")) {
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("{_k: _v for _k, _v in %s.items() if _k != %s}", map, key);
			} else if (fnName.equals("range")) {
			    if (e.getArgs().size() == 1) {
			        return String.format("list(range(%s))", expression(e.getArgs().get(0), variablePrefix));
			    } else if (e.getArgs().size() == 2) {
			        return String.format("list(range(%s, %s))", expression(e.getArgs().get(0), variablePrefix), expression(e.getArgs().get(1), variablePrefix));
			    } else if (e.getArgs().size() == 3) {
			        return String.format("list(range(%s, %s, %s))", expression(e.getArgs().get(0), variablePrefix), expression(e.getArgs().get(1), variablePrefix), expression(e.getArgs().get(2), variablePrefix));
			    }
			} else if (fnName.equals("toString")) {
			    return String.format("str(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (fnName.equals("concat")) {
			    return String.format("%s + %s", expression(e.getArgs().get(0), variablePrefix), expression(e.getArgs().get(1), variablePrefix));
			} 
		} else if (expression instanceof ExpressionMap e) {
			return String.format("{%s}", e.getPairs().stream().map(p -> {
				String key = expression(p.getKey(), variablePrefix);
				String value = expression(p.getValue(), variablePrefix);
				return String.format("%s: %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW e) {
			String map = expression(e.getMap(), variablePrefix);
			String key = expression(e.getKey(), variablePrefix);
			if (e.getValue() == null) {
				return String.format("%s[%s]", map, key);
			} else {
				String value = expression(e.getValue(), variablePrefix);
				return String.format("{**%s, **{%s: %s}}", map, key, value);
			}
		} else if (expression instanceof ExpressionRecord e) {
			return String.format("{%s}", e.getFields().stream().map(p -> {
				String key = p.getRecordField().getName();
				String value = expression(p.getExp(), variablePrefix);
				return String.format("\"%s\": %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionRecordAccess e) {
			String map = expression(e.getRecord(), variablePrefix);
			return String.format("%s[\"%s\"]", map, e.getField().getName());
		} 
		
		throw new RuntimeException("Not supported");
	}
	
	static List<String> parameters(Object event, Function<String, String> variablePrefix) {
		throw new RuntimeException("Not supported");
	}

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
			if(a.isSymbolic()) return String.format("%s = %s%s%s", variable, QUOTE, serialize(a.getExp()).toString().replace("\"", "\\\""), QUOTE);
			else return String.format("%s = %s", variable, expression(a.getExp(), variablePrefix));
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String QUOTE = "\"";
			if(a.isSymbolic()) {
				String record = serialize(access.getRecord()).toString();
				String field = access.getField().getName();
				String value = serialize(a.getExp()).toString();
				return String.format("%s.%s = %s%s%s", record, field, QUOTE, value.replace("\"", "\\\""), QUOTE);
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
		}
		
		throw new RuntimeException("Not supported");
	}

	static String commaAction(Action action, Function<String, String> variablePrefix, String indent) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
			String QUOTE = "\"";
			String variable = String.format("%s", variablePrefix.apply(a.getAssignment().getName()));
			return String.format("%s = %s%s%s", variable, QUOTE, serialize(a.getExp()).toString(), QUOTE); //.replace("\"", "\\\"")
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String QUOTE = "\"";
			String record = serialize(access.getRecord()).toString();
			String field = access.getField().getName();
			String value = serialize(a.getExp()).toString();
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
		}
		
		throw new RuntimeException("Not supported");
	}

}
