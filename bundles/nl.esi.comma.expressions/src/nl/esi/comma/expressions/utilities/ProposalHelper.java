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
package nl.esi.comma.expressions.utilities;

import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.util.EcoreUtil;

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
import nl.esi.comma.expressions.expression.TypeAnnotation;
import nl.esi.comma.expressions.validation.ExpressionFunction;
import nl.esi.comma.types.types.EnumTypeDecl;
import nl.esi.comma.types.types.MapTypeConstructor;
import nl.esi.comma.types.types.MapTypeDecl;
import nl.esi.comma.types.types.RecordTypeDecl;
import nl.esi.comma.types.types.SimpleTypeDecl;
import nl.esi.comma.types.types.Type;
import nl.esi.comma.types.types.TypeDecl;
import nl.esi.comma.types.types.TypeReference;
import nl.esi.comma.types.types.VectorTypeConstructor;
import nl.esi.comma.types.types.VectorTypeDecl;
import nl.esi.comma.types.utilities.TypeUtilities;

public class ProposalHelper {
	public static String getTypeName(Type type) {
		return TypeUtilities.getTypeName(type);
	}
	
	public static String getTypeName(TypeAnnotation typeAnn) {
		final Type type = typeAnn.getType();
		if (type instanceof TypeReference) {
			return TypeUtilities.getTypeName(type.getType());
		} else if (type instanceof VectorTypeConstructor vecType) {
			return TypeUtilities.getTypeName(TypeUtilities.getElementType(vecType));
		} else if (type instanceof MapTypeConstructor) {
			return TypeUtilities.getTypeName(type).replaceFirst("^map<", "map.entry<");
		}
		return null;
	}

	public static String defaultValue(TypeAnnotation typeAnn, String targetName) throws UnsupportedTypeException {
		return createDefaultValueEntry(typeAnn.getType(), targetName, "");
	}

	public static String defaultValue(Type type, String targetName) throws UnsupportedTypeException {
		return createDefaultValue(type, targetName, "");
	}

	private static String createDefaultValue(Type type, String targetName, String indent) throws UnsupportedTypeException {
		if (type instanceof TypeReference) {
			return createDefaultValueEntry(type, targetName, indent);
		} else if (type instanceof VectorTypeConstructor) {
			return "<" + getTypeName(type) + ">[ " + createDefaultValueEntry(type, null, indent) + " ]";
		} else if (type instanceof MapTypeConstructor) {
			return "<" + getTypeName(type) + ">{ " + createDefaultValueEntry(type, null, indent) + " }";
		}
		throw new UnsupportedTypeException(type);
	}

	private static String createDefaultValueEntry(Type type, String targetName, String indent) throws UnsupportedTypeException {
		if (type instanceof TypeReference) {
			return createDefaultValue(type.getType(), targetName, indent);
		} else if (type instanceof VectorTypeConstructor vecType) {
			if (vecType.getDimensions().size() > 1) {
				return createDefaultValue(getOuterDimension(vecType), null, indent);
			}
			return createDefaultValue(type.getType(), targetName, indent);
		} else if (type instanceof MapTypeConstructor mapType) {
			String key = createDefaultValue(type.getType(), null, indent);
			String value = createDefaultValue(mapType.getValueType(), null, indent);
			return key + " -> " + value;
		}
		throw new UnsupportedTypeException(type);
	}
	
	private static Type getOuterDimension(VectorTypeConstructor vectorType) {
		VectorTypeConstructor outerDimension = EcoreUtil.copy(vectorType);
		outerDimension.getDimensions().removeLast();
		return outerDimension;
	}

	private static String createDefaultValue(TypeDecl type, String targetName, String indent) throws UnsupportedTypeException {
		if (type instanceof SimpleTypeDecl simpleType) {
			if (simpleType.getBase() != null) return createDefaultValue(simpleType.getBase(), targetName, indent);
			else if (simpleType.getName().equals("int")) return "0";
			else if (simpleType.getName().equals("real")) return "0.0";
			else if (simpleType.getName().equals("bool")) return "true";
			else if (simpleType.getName().equals("string")) return "__uuid__".equals(targetName) ? ExpressionFunction.uuid + "()" : "\"\"";
			else return "\"\""; // Custom types without base (e.g. type DateTime)
		} else if (type instanceof VectorTypeDecl) {
			return "[]";
		} else if (type instanceof EnumTypeDecl enumType) {
			return String.format("%s::%s", enumType.getName(), enumType.getLiterals().get(0).getName());
		} else if (type instanceof MapTypeDecl) {
			return "{}";
		} else if (type instanceof RecordTypeDecl recType) {
			if ( recType.getFields().size() > 1) {
				String fieldIndent = indent + "\t";
				String value = recType.getFields().stream()
					.map(f -> String.format("%s%s = %s", fieldIndent, f.getName(), createDefaultValue(f.getType(), f.getName(), fieldIndent)))
					.collect(Collectors.joining(",\n"));
				return String.format("%s {\n%s\n%s}", type.getName(), value, indent);
			} else {
				String value = recType.getFields().stream()
					.map(f -> String.format("%s = %s", f.getName(), createDefaultValue(f.getType(), f.getName(), indent)))
					.collect(Collectors.joining(",\n"));
				return String.format("%s { %s }", type.getName(), value);
			}
		} 
		
		throw new UnsupportedTypeException(type);
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
			return expression(e.getSub(), variablePrefix);
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
}
