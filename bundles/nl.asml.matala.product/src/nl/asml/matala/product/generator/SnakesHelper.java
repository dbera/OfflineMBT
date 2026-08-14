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

import java.util.function.Function;
import java.util.stream.Collectors;

import nl.esi.xtext.actions.actions.Action;
import nl.esi.xtext.actions.actions.ActionList;
import nl.esi.xtext.actions.actions.AssignmentAction;
import nl.esi.xtext.actions.actions.ForAction;
import nl.esi.xtext.actions.actions.FunctionCall;
import nl.esi.xtext.actions.actions.IfAction;
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction;
import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionAddition;
import nl.esi.xtext.expressions.expression.ExpressionAnd;
import nl.esi.xtext.expressions.expression.ExpressionAny;
import nl.esi.xtext.expressions.expression.ExpressionBracket;
import nl.esi.xtext.expressions.expression.ExpressionConditional;
import nl.esi.xtext.expressions.expression.ExpressionConstantBool;
import nl.esi.xtext.expressions.expression.ExpressionConstantInt;
import nl.esi.xtext.expressions.expression.ExpressionConstantReal;
import nl.esi.xtext.expressions.expression.ExpressionConstantString;
import nl.esi.xtext.expressions.expression.ExpressionDivision;
import nl.esi.xtext.expressions.expression.ExpressionEnumLiteral;
import nl.esi.xtext.expressions.expression.ExpressionEqual;
import nl.esi.xtext.expressions.expression.ExpressionFunctionCall;
import nl.esi.xtext.expressions.expression.ExpressionGeq;
import nl.esi.xtext.expressions.expression.ExpressionGreater;
import nl.esi.xtext.expressions.expression.ExpressionLeq;
import nl.esi.xtext.expressions.expression.ExpressionLess;
import nl.esi.xtext.expressions.expression.ExpressionMap;
import nl.esi.xtext.expressions.expression.ExpressionMapRW;
import nl.esi.xtext.expressions.expression.ExpressionMaximum;
import nl.esi.xtext.expressions.expression.ExpressionMinimum;
import nl.esi.xtext.expressions.expression.ExpressionMinus;
import nl.esi.xtext.expressions.expression.ExpressionModulo;
import nl.esi.xtext.expressions.expression.ExpressionMultiply;
import nl.esi.xtext.expressions.expression.ExpressionNEqual;
import nl.esi.xtext.expressions.expression.ExpressionNot;
import nl.esi.xtext.expressions.expression.ExpressionNullCoalescing;
import nl.esi.xtext.expressions.expression.ExpressionNullLiteral;
import nl.esi.xtext.expressions.expression.ExpressionOr;
import nl.esi.xtext.expressions.expression.ExpressionPlus;
import nl.esi.xtext.expressions.expression.ExpressionPower;
import nl.esi.xtext.expressions.expression.ExpressionRecord;
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess;
import nl.esi.xtext.expressions.expression.ExpressionSubtraction;
import nl.esi.xtext.expressions.expression.ExpressionVariable;
import nl.esi.xtext.expressions.expression.ExpressionVector;
import nl.esi.xtext.expressions.utilities.ExpressionsUtilities;
import nl.esi.xtext.types.types.EnumTypeDecl;
import nl.esi.xtext.types.types.MapTypeConstructor;
import nl.esi.xtext.types.types.MapTypeDecl;
import nl.esi.xtext.types.types.RecordFieldKind;
import nl.esi.xtext.types.types.RecordTypeDecl;
import nl.esi.xtext.types.types.SimpleTypeDecl;
import nl.esi.xtext.types.types.Type;
import nl.esi.xtext.types.types.TypeDecl;
import nl.esi.xtext.types.types.VectorTypeConstructor;
import nl.esi.xtext.types.types.VectorTypeDecl;
import nl.esi.xtext.types.utilities.TypeUtilities;

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

	static String expression(Expression expression) {
		return expression(expression, Function.identity());
	}
	
	static String expression(Expression expression, Function<String, String> variableRename) {
		if (expression instanceof ExpressionConstantInt e) {
			return Long.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantString e) {
			String value = e.getValue();
			return String.format("\"%s\"", value == null ? "" : value.replace("\"", "\\\""));
		} else if (expression instanceof ExpressionNot e) {
			return String.format("not (%s)", expression(e.getSub(), variableRename));
		} else if (expression instanceof ExpressionConstantReal e) {
			return Double.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantBool e) {
			return e.isValue() ? "True" : "False";
		} else if (expression instanceof ExpressionAny) {
			return "\"*\"";
		} else if (expression instanceof ExpressionAddition e) {
			return String.format("%s + %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionSubtraction e) {
			return String.format("%s - %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionMultiply e) {
			return String.format("%s * %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionDivision e) {
			return String.format("%s / %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionModulo e) {
			return String.format("%s %% %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionMinimum e) {
			return String.format("min(%s, %s)", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionMaximum e) {
			return String.format("max(%s, %s)", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionPower e) {
			return String.format("pow(%s, %s)", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionNullCoalescing e) {
			return String.format("%s if (%s) is not None else %s", expression(e.getLeft(), variableRename), expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionConditional e) {
			return String.format("%s if %s else %s", expression(e.getMiddle(), variableRename), expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionVariable e) {
			return String.format("%s", variableRename.apply(e.getVariable().getName()));
		} else if (expression instanceof ExpressionGreater e) {
			return String.format("%s > %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionLess e) {
			return String.format("%s < %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionLeq e) {
			return String.format("%s <= %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionGeq e) {
			return String.format("%s >= %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionEqual e) {
			return String.format("%s == %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionNEqual e) {
			return String.format("%s != %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionAnd e) {
			return String.format("%s and %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionOr e) {
			return String.format("%s or %s", expression(e.getLeft(), variableRename), expression(e.getRight(), variableRename));
		} else if (expression instanceof ExpressionEnumLiteral e) {
			return String.format("\"%s::%s\"", e.getType().getName(), e.getLiteral().getName());
		} else if (expression instanceof ExpressionNullLiteral) {
			return "None";
		} else if (expression instanceof ExpressionVector e) {
			return String.format("[%s]", e.getElements().stream().map(ee -> expression (ee, variableRename)).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMinus e) {
			return String.format("%s * -1", expression(e.getSub(), variableRename));
		} else if (expression instanceof ExpressionPlus e) {
			return expression(e.getSub(), variableRename);
		} else if (expression instanceof ExpressionBracket e) {
			return String.format("(%s)", expression(e.getSub(), variableRename));
		} else if (expression instanceof ExpressionFunctionCall e) {
			var fnName = e.getFunction().getName();
			if (fnName.equals("add")) {
				return String.format("%s + [%s]", expression(e.getArgs().get(0), variableRename), expression(e.getArgs().get(1), variableRename));
			} else if (fnName.equals("size")) {
				return String.format("len(%s)", expression(e.getArgs().get(0), variableRename));
			} else if (fnName.equals("isEmpty")) {
				return String.format("len(%s) == 0", expression(e.getArgs().get(0), variableRename));
			} else if (fnName.equals("contains")) {
				return String.format("%s in %s", expression(e.getArgs().get(1), variableRename), expression(e.getArgs().get(0), variableRename));
			} else if (fnName.equals("abs")) {
				return String.format("abs(%s)", expression(e.getArgs().get(0), variableRename));
			} else if (fnName.equals("asReal")) {
				return String.format("float(%s)", expression(e.getArgs().get(0), variableRename));
			} else if (fnName.equals("hasKey")) {
				String map = expression(e.getArgs().get(0), variableRename);
				String key = expression(e.getArgs().get(1), variableRename);
				return String.format("(%s in %s)", key, map);
			} else if (fnName.equals("get")) {
				Expression arg0 = e.getArgs().get(0);
				String col = expression(arg0, variableRename);
				String idx = expression(e.getArgs().get(1), variableRename);
				if (TypeUtilities.isMapType(ExpressionsUtilities.typeOf(arg0))) {
					return String.format("list(%s.items())[%s][1]", col, idx);
				} else {
					return String.format("%s[%s]", col, idx);
				}
			} else if (fnName.equals("at")) {
				String lst = expression(e.getArgs().get(0), variableRename);
				String idx = expression(e.getArgs().get(1), variableRename);
				String val = expression(e.getArgs().get(2), variableRename);
				return String.format("%s; %s[%s] = %s", lst, lst, idx, val);
			} else if (fnName.equals("deleteKey")) {
				String map = expression(e.getArgs().get(0), variableRename);
				String key = expression(e.getArgs().get(1), variableRename);
				return String.format("{_k: _v for _k, _v in %s.items() if _k != %s}", map, key);
			} else if (fnName.equals("range")) {
			    if (e.getArgs().size() == 1) {
			        return String.format("list(range(%s))", expression(e.getArgs().get(0), variableRename));
			    } else if (e.getArgs().size() == 2) {
			        return String.format("list(range(%s, %s))", expression(e.getArgs().get(0), variableRename), expression(e.getArgs().get(1), variableRename));
			    } else if (e.getArgs().size() == 3) {
			        return String.format("list(range(%s, %s, %s))", expression(e.getArgs().get(0), variableRename), expression(e.getArgs().get(1), variableRename), expression(e.getArgs().get(2), variableRename));
			    }
			} else if (fnName.equals("toString")) {
			    return String.format("str(%s)", expression(e.getArgs().get(0), variableRename));
			} else if (fnName.equals("concat")) {
			    return String.format("%s + %s", expression(e.getArgs().get(0), variableRename), expression(e.getArgs().get(1), variableRename));
			} 
		} else if (expression instanceof ExpressionMap e) {
			return String.format("{%s}", e.getPairs().stream().map(p -> {
				String key = expression(p.getKey(), variableRename);
				String value = expression(p.getValue(), variableRename);
				return String.format("%s: %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW e) {
			String map = expression(e.getMap(), variableRename);
			String key = expression(e.getKey(), variableRename);
			if (e.getValue() == null) {
				return String.format("%s[%s]", map, key);
			} else {
				String value = expression(e.getValue(), variableRename);
				return String.format("{**%s, **{%s: %s}}", map, key, value);
			}
		} else if (expression instanceof ExpressionRecord e) {
			return String.format("{%s}", e.getFields().stream().map(p -> {
				String key = p.getRecordField().getName();
				String value = expression(p.getExp(), variableRename);
				return String.format("\"%s\": %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionRecordAccess e) {
			String map = expression(e.getRecord(), variableRename);
			if (e.isNullSafe()) {
				return String.format("(%s and %s[\"%s\"])", map, map, e.getField().getName());
			} else {
				return String.format("%s[\"%s\"]", map, e.getField().getName());
			}
		} 
		
		throw new RuntimeException("Not supported");
	}
	
	static String action(Action action) {
		return action(action, Function.identity());
	}

	static String action(Action action, Function<String, String> variableRename) {
		return action(action, variableRename, "");
	}
	
	private static String action(Action action, Function<String, String> variableRename, String indent) {
		if (action instanceof AssignmentAction a) {
			// String variable = String.format("%s%s", variablePrefix.apply(a.getAssignment().getName()), a.getAssignment().getName());
			String variable = String.format("%s", variableRename.apply(a.getAssignment().getName()));
			// if(a.isSymbolic()) return String.format("%s = %s%s%s", variable, QUOTE, expression(a.getExp(), variablePrefix).replace("\"", "\\\""), QUOTE);
			return String.format("%s = %s", variable, expression(a.getExp(), variableRename));
		} else if (action instanceof RecordFieldAssignmentAction a) {
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String record = expression(access.getRecord(), variableRename);
			String field = access.getField().getName();
			String value = expression(a.getExp(), variableRename);
			return String.format("%s[\"%s\"] = %s", record, field, value);
		} else if(action instanceof IfAction act) {
			var txt = new String();
			txt += String.format("if %s:\n",expression(act.getGuard(), variableRename));
			txt += indentActionList(act.getThenList(), variableRename, indent);
			if(act.getElseList()!= null) {
				txt += "else:\n";
				txt += indentActionList(act.getElseList(), variableRename, indent);
			}
			return txt.trim();
		} else if(action instanceof ForAction act) {
			var txt = new String();
			txt += String.format("for %s in %s:\n", act.getVar().getName(), expression(act.getExp(), variableRename));
			txt += indentActionList(act.getDoList(), variableRename, indent);
			return txt.trim();
		} else if(action instanceof FunctionCall functionCall) {
			var txt = new String();
			txt += expression(functionCall.getExp());
			return txt.trim();
	}
		throw new RuntimeException("Not supported");
	}

	private static String indentActionList(ActionList actionList, Function<String, String> variablePrefix, String indent) {
		var txt = new String();
		var indent_level = indent + "	";
		if (actionList == null || actionList.getActions().isEmpty()) {
			txt += indent_level + "pass\n";
		} else {
			for(var a : actionList.getActions()) {
				txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level));
			}
		}
		return txt;
	}
}
