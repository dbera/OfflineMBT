package nl.asml.matala.product.mcrl2;

import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import nl.esi.comma.actions.actions.Action;
import nl.esi.comma.actions.actions.AssignmentAction;
import nl.esi.comma.actions.actions.CommandReply;
import nl.esi.comma.actions.actions.EventCall;
import nl.esi.comma.actions.actions.ForAction;
import nl.esi.comma.actions.actions.IfAction;
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction;
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
import nl.esi.comma.signature.interfaceSignature.DIRECTION;
import nl.esi.comma.types.types.EnumTypeDecl;
import nl.esi.comma.types.types.MapTypeDecl;
import nl.esi.comma.types.types.RecordTypeDecl;
import nl.esi.comma.types.types.SimpleTypeDecl;
import nl.esi.comma.types.types.TypeDecl;
import nl.esi.comma.types.types.VectorTypeDecl;

class mCRL2Helper {
	static String defaultValue(TypeDecl type) {
		if (type instanceof SimpleTypeDecl) {
			SimpleTypeDecl t = (SimpleTypeDecl) type;
			if (t.getBase() != null) return defaultValue(t.getBase());
			else if (t.getName().equals("int")) return "0";
			else if (t.getName().equals("real")) return "0.0";
			else if (t.getName().equals("bool")) return "true";
			else if (t.getName().equals("string")) return "unit";
			else return "\"\""; // Custom types without base (e.g. type DateTime)
		} else if (type instanceof VectorTypeDecl) {
			return "[]";
		} else if (type instanceof EnumTypeDecl) {
			EnumTypeDecl t = (EnumTypeDecl) type;
			return String.format(t.getLiterals().get(0).getName());
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
			return String.format("unit", ((ExpressionConstantString) expression).getValue());
		} else if (expression instanceof ExpressionNot) {
			return String.format("!(%s)", expression(((ExpressionNot) expression).getSub(), variablePrefix));
		} else if (expression instanceof ExpressionConstantReal) {
			return Double.toString(((ExpressionConstantReal) expression).getValue());
		} else if (expression instanceof ExpressionConstantBool) {
			return ((ExpressionConstantBool) expression).isValue() ? "true" : "false";
		} else if (expression instanceof ExpressionAny) {
			return "\"*\"";
		} else if (expression instanceof ExpressionAddition) {
			ExpressionAddition e = (ExpressionAddition) expression;
			return String.format("(%s + %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionSubtraction) {
			ExpressionSubtraction e = (ExpressionSubtraction) expression;
			return String.format("(%s - %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMultiply) {
			ExpressionMultiply e = (ExpressionMultiply) expression;
			return String.format("(%s * %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionDivision) {
			ExpressionDivision e = (ExpressionDivision) expression;
			return String.format("(%s / %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionModulo) {
			ExpressionModulo e = (ExpressionModulo) expression;
			return String.format("(%s mod %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
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
			return String.format("(%s > %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLess) {
			ExpressionLess e = (ExpressionLess) expression;
			return String.format("(%s < %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLeq) {
			ExpressionLeq e = (ExpressionLeq) expression;
			return String.format("(%s <= %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionGeq) {
			ExpressionGeq e = (ExpressionGeq) expression;
			return String.format("(%s >= %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEqual) {
			ExpressionEqual e = (ExpressionEqual) expression;
			return String.format("(%s == %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionNEqual) {
			ExpressionNEqual e = (ExpressionNEqual) expression;
			return String.format("(%s != %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionAnd) {
			ExpressionAnd e = (ExpressionAnd) expression;
			return String.format("(%s && %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionOr) {
			ExpressionOr e = (ExpressionOr) expression;
			return String.format("(%s || %s)", expression(e.getLeft(), variablePrefix), expression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEnumLiteral) {
			ExpressionEnumLiteral e = (ExpressionEnumLiteral) expression;
			return e.getLiteral().getName();
		} else if (expression instanceof ExpressionVector) {
			ExpressionVector e = (ExpressionVector) expression;
			return String.format("[%s]", e.getElements().stream().map(ee -> {
				if (ee instanceof ExpressionRecord 
						|| ee instanceof ExpressionMap 
						|| ee instanceof ExpressionMapRW
						|| ee instanceof ExpressionVector
				) {
					return String.format("%s", expression(ee, variablePrefix));
				} else {
					return String.format("\"%s\"", expression(ee, variablePrefix));
				}
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMinus) {
			ExpressionMinus e = (ExpressionMinus) expression;
			return String.format("(%s * -1)", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionPlus) {
			ExpressionPlus e = (ExpressionPlus) expression;
			return expression(e.getSub(), variablePrefix);
		} else if (expression instanceof ExpressionBracket) {
			ExpressionBracket e = (ExpressionBracket) expression;
			//return expression(e.getSub(), variablePrefix);
			return String.format("(%s)", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionFunctionCall) {
			ExpressionFunctionCall e = (ExpressionFunctionCall) expression;
			if (e.getFunctionName().equals("add")) {
				return String.format("%s + [%s]", expression(e.getArgs().get(0), variablePrefix), expression(e.getArgs().get(1), variablePrefix));
			} else if (e.getFunctionName().equals("size")) {
				return String.format("#(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("isEmpty")) {
				return String.format("(#(%s) == 0)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("contains")) {
				return String.format("(%s in %s)", expression(e.getArgs().get(1), variablePrefix), expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("abs")) {
				return String.format("abs(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("asReal")) {
				return String.format("Int2Real(%s)", expression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("hasKey")) {
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("(%s in %s)", key, map);
			} else if (e.getFunctionName().equals("deleteKey")) {
//				TODO: make deleteKey function in mcrl2
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("deleteKey(%s, %s)", map, key);
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
				return String.format("\"%s\": %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW) {
			ExpressionMapRW e = (ExpressionMapRW) expression;
			String map = expression(e.getMap(), variablePrefix);
			String key = expression(e.getKey(), variablePrefix);
			if (e.getValue() == null) {
				return String.format("get(%s, %s)", map, key);
			} else {
				String value = expression(e.getValue(), variablePrefix);
				return String.format("{**%s, **{%s: %s}}", map, key, value);
			}
		} else if (expression instanceof ExpressionRecord) {
			ExpressionRecord e = (ExpressionRecord) expression;
			return String.format("{%s}", e.getFields().stream().map(p -> {
				String key = p.getRecordField().getName();
				String value = expression(p.getExp(), variablePrefix);
				if (p.getExp() instanceof ExpressionRecord 
						|| p.getExp() instanceof ExpressionMap 
						|| p.getExp() instanceof ExpressionMapRW
						|| p.getExp() instanceof ExpressionVector
				) {
					return String.format("\"%s\": %s", key, value);
				} else {
					return String.format("\"%s\": \"%s\"", key, value);
				}
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionRecordAccess) {
			ExpressionRecordAccess e = (ExpressionRecordAccess) expression;
			String map = expression(e.getRecord(), variablePrefix);
			return String.format("%s(%s)", e.getField().getName(), map);
		} else if (expression instanceof ExpressionBulkData) {
			return "[]";
		} 
		
		throw new RuntimeException("Not supported");
		}
	
	static String initExpression(Expression expression, Function<String, String> variablePrefix) {
		if (expression instanceof ExpressionConstantInt) {
			return Long.toString(((ExpressionConstantInt) expression).getValue());
		} else if (expression instanceof ExpressionConstantString) {
			return String.format("\"unit\"", ((ExpressionConstantString) expression).getValue());
		} else if (expression instanceof ExpressionNot) {
			return String.format("!(%s)", initExpression(((ExpressionNot) expression).getSub(), variablePrefix));
		} else if (expression instanceof ExpressionConstantReal) {
			return Double.toString(((ExpressionConstantReal) expression).getValue());
		} else if (expression instanceof ExpressionConstantBool) {
			return ((ExpressionConstantBool) expression).isValue() ? "true" : "false";
		} else if (expression instanceof ExpressionAny) {
			return "\"*\"";
		} else if (expression instanceof ExpressionAddition) {
			ExpressionAddition e = (ExpressionAddition) expression;
			return String.format("(%s + %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionSubtraction) {
			ExpressionSubtraction e = (ExpressionSubtraction) expression;
			return String.format("(%s - %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMultiply) {
			ExpressionMultiply e = (ExpressionMultiply) expression;
			return String.format("(%s * %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionDivision) {
			ExpressionDivision e = (ExpressionDivision) expression;
			return String.format("(%s / %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionModulo) {
			ExpressionModulo e = (ExpressionModulo) expression;
			return String.format("(%s mod %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMinimum) {
			ExpressionMinimum e = (ExpressionMinimum) expression;
			return String.format("min(%s, %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionMaximum) {
			ExpressionMaximum e = (ExpressionMaximum) expression;
			return String.format("max(%s, %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionPower) {
			ExpressionPower e = (ExpressionPower) expression;
			return String.format("pow(%s, %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionVariable) {
			ExpressionVariable v = (ExpressionVariable) expression;
			// return String.format("%s%s", variablePrefix.apply(v.getVariable().getName()), v.getVariable().getName());
			return String.format("%s", variablePrefix.apply(v.getVariable().getName()));
		} else if (expression instanceof ExpressionGreater) {
			ExpressionGreater e = (ExpressionGreater) expression;
			return String.format("(%s > %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLess) {
			ExpressionLess e = (ExpressionLess) expression;
			return String.format("(%s < %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionLeq) {
			ExpressionLeq e = (ExpressionLeq) expression;
			return String.format("(%s <= %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionGeq) {
			ExpressionGeq e = (ExpressionGeq) expression;
			return String.format("(%s >= %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEqual) {
			ExpressionEqual e = (ExpressionEqual) expression;
			return String.format("(%s == %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionNEqual) {
			ExpressionNEqual e = (ExpressionNEqual) expression;
			return String.format("(%s != %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionAnd) {
			ExpressionAnd e = (ExpressionAnd) expression;
			return String.format("(%s && %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionOr) {
			ExpressionOr e = (ExpressionOr) expression;
			return String.format("(%s || %s)", initExpression(e.getLeft(), variablePrefix), initExpression(e.getRight(), variablePrefix));
		} else if (expression instanceof ExpressionEnumLiteral) {
			ExpressionEnumLiteral e = (ExpressionEnumLiteral) expression;
			return e.getLiteral().getName();
		} else if (expression instanceof ExpressionVector) {
			ExpressionVector e = (ExpressionVector) expression;
			return String.format("[%s]", e.getElements().stream().map(ee -> expression (ee, variablePrefix)).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMinus) {
			ExpressionMinus e = (ExpressionMinus) expression;
			return String.format("(%s * -1)", initExpression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionPlus) {
			ExpressionPlus e = (ExpressionPlus) expression;
			return initExpression(e.getSub(), variablePrefix);
		} else if (expression instanceof ExpressionBracket) {
			ExpressionBracket e = (ExpressionBracket) expression;
			//return initExpression(e.getSub(), variablePrefix);
			return String.format("(%s)", initExpression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionFunctionCall) {
			ExpressionFunctionCall e = (ExpressionFunctionCall) expression;
			if (e.getFunctionName().equals("add")) {
				return String.format("%s + [%s]", initExpression(e.getArgs().get(0), variablePrefix), initExpression(e.getArgs().get(1), variablePrefix));
			} else if (e.getFunctionName().equals("size")) {
				return String.format("#(%s)", initExpression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("isEmpty")) {
				return String.format("(#(%s) == 0)", initExpression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("contains")) {
				return String.format("(%s in %s)", initExpression(e.getArgs().get(1), variablePrefix), initExpression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("abs")) {
				return String.format("abs(%s)", initExpression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("asReal")) {
				return String.format("Int2Real(%s)", initExpression(e.getArgs().get(0), variablePrefix));
			} else if (e.getFunctionName().equals("hasKey")) {
				String map = initExpression(e.getArgs().get(0), variablePrefix);
				String key = initExpression(e.getArgs().get(1), variablePrefix);
				return String.format("(%s in %s)", key, map);
			} else if (e.getFunctionName().equals("deleteKey")) {
				String map = initExpression(e.getArgs().get(0), variablePrefix);
				String key = initExpression(e.getArgs().get(1), variablePrefix);
				return String.format("{_k: _v for _k, _v in %s.items() if _k != %s}", map, key);
			}
		} else if (expression instanceof ExpressionQuantifier) {
			ExpressionQuantifier e = (ExpressionQuantifier) expression;
			String collection = initExpression(e.getCollection(), variablePrefix);
			String it = e.getIterator().getName();
			String condition = initExpression(e.getCondition(), (String variable) -> "");
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
				String key = initExpression(p.getKey(), variablePrefix);
				String value = initExpression(p.getValue(), variablePrefix);
				return String.format("\"%s\": %s", key, value);
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW) {
			ExpressionMapRW e = (ExpressionMapRW) expression;
			String map = initExpression(e.getMap(), variablePrefix);
			String key = initExpression(e.getKey(), variablePrefix);
			if (e.getValue() == null) {
				return String.format("%s[%s]", map, key);
			} else {
				String value = initExpression(e.getValue(), variablePrefix);
				return String.format("{**%s, **{%s: %s}}", map, key, value);
			}
		} else if (expression instanceof ExpressionRecord) {
			ExpressionRecord e = (ExpressionRecord) expression;
			return String.format("{%s}", e.getFields().stream().map(p -> {
				String key = p.getRecordField().getName();
				String value = initExpression(p.getExp(), variablePrefix);
				if (p.getExp() instanceof ExpressionRecord || p.getExp() instanceof ExpressionMap || p.getExp() instanceof ExpressionMapRW) {
					return String.format("\"%s\": %s", key, value);
				} else {
					return String.format("\"%s\": \"%s\"", key, value);
				}
			}).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionRecordAccess) {
			ExpressionRecordAccess e = (ExpressionRecordAccess) expression;
			String map = initExpression(e.getRecord(), variablePrefix);
			return String.format("%s(%s)", e.getField().getName(), map);
		} else if (expression instanceof ExpressionBulkData) {
			return "[]";
		} 
		
		throw new RuntimeException("Not supported");
		}
	
	static List<String> parameters(Object event, Function<String, String> variablePrefix) {
		if (event instanceof CommandReply) {
			CommandReply r = (CommandReply) event;
			return r.getParameters().stream().map(p -> expression(p, variablePrefix)).collect(Collectors.toList());
		} else if (event instanceof EventCall) {
			EventCall e = (EventCall) event;
			return e.getParameters().stream().map(p -> expression(p, variablePrefix)).collect(Collectors.toList());
		}
		 
		throw new RuntimeException("Not supported");
	}

	static String action(Action action, Function<String, String> variablePrefix, String indent) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
			// String variable = String.format("%s%s", variablePrefix.apply(a.getAssignment().getName()), a.getAssignment().getName());
			String variable = String.format("%s", a.getAssignment().getName());
			String expr = expression(a.getExp(), variablePrefix);
			if (a.getExp() instanceof ExpressionRecord) {
				expr = String.format("%s", expr);
			} else {
				expr = String.format("\"%s\"", expr);
			}
			return String.format("%s", expr);
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String record = expression(access.getRecord(), variablePrefix);
			String field = access.getField().getName();
			String value = expression(a.getExp(), variablePrefix);
			return String.format("%s(%s) = %s", field, record, value);
		} else if(action instanceof IfAction) {
			var txt = new String();
			var indent_level = indent + "	";
			var act = (IfAction) action;
			txt += String.format("if(%s,\n",expression(act.getGuard(), variablePrefix));
			for(var a : act.getThenList().getActions()) {
				txt += indent_level + String.format("%s,\n", action(a,variablePrefix, indent_level)); 
			}
			if(act.getElseList()!= null) {
				for(var a : act.getElseList().getActions()) {
					txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level)); 
				}
				txt += ")";
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
	
	static String initAction(Action action, Function<String, String> variablePrefix, String indent) {
		if (action instanceof AssignmentAction) {
			AssignmentAction a = (AssignmentAction) action;
			// String variable = String.format("%s%s", variablePrefix.apply(a.getAssignment().getName()), a.getAssignment().getName());
			String variable = String.format("%s", a.getAssignment().getName());
			Expression expr = a.getExp();
			return String.format("%s = %s", variable, initExpression(expr, variablePrefix));
		} else if (action instanceof RecordFieldAssignmentAction) {
			RecordFieldAssignmentAction a = (RecordFieldAssignmentAction) action;
			ExpressionRecordAccess access = (ExpressionRecordAccess) a.getFieldAccess();
			String record = expression(access.getRecord(), variablePrefix);
			String field = access.getField().getName();
			String value = expression(a.getExp(), variablePrefix);
			return String.format("%s(%s) = %s", field, record, value);
		} else if(action instanceof IfAction) {
			var txt = new String();
			var indent_level = indent + "	";
			var act = (IfAction) action;
			txt += String.format("if(%s,\n",expression(act.getGuard(), variablePrefix));
			for(var a : act.getThenList().getActions()) {
				txt += indent_level + String.format("%s,\n", action(a,variablePrefix, indent_level)); 
			}
			if(act.getElseList()!= null) {
				for(var a : act.getElseList().getActions()) {
					txt += indent_level + String.format("%s\n", action(a,variablePrefix, indent_level)); 
				}
				txt += ")";
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
