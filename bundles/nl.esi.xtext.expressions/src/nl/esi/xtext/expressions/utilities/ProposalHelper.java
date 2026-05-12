/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.utilities;

import static nl.esi.xtext.types.utilities.TypeUtilities.getAllFields;

import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.util.EcoreUtil;

import nl.esi.xtext.expressions.expression.Expression;
import nl.esi.xtext.expressions.expression.ExpressionAddition;
import nl.esi.xtext.expressions.expression.ExpressionAnd;
import nl.esi.xtext.expressions.expression.ExpressionAny;
import nl.esi.xtext.expressions.expression.ExpressionBracket;
import nl.esi.xtext.expressions.expression.ExpressionConstantBool;
import nl.esi.xtext.expressions.expression.ExpressionConstantInt;
import nl.esi.xtext.expressions.expression.ExpressionConstantReal;
import nl.esi.xtext.expressions.expression.ExpressionConstantString;
import nl.esi.xtext.expressions.expression.ExpressionDivision;
import nl.esi.xtext.expressions.expression.ExpressionEnumLiteral;
import nl.esi.xtext.expressions.expression.ExpressionEqual;
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
import nl.esi.xtext.expressions.expression.ExpressionNullLiteral;
import nl.esi.xtext.expressions.expression.ExpressionOr;
import nl.esi.xtext.expressions.expression.ExpressionPlus;
import nl.esi.xtext.expressions.expression.ExpressionPower;
import nl.esi.xtext.expressions.expression.ExpressionRecord;
import nl.esi.xtext.expressions.expression.ExpressionRecordAccess;
import nl.esi.xtext.expressions.expression.ExpressionSubtraction;
import nl.esi.xtext.expressions.expression.ExpressionVariable;
import nl.esi.xtext.expressions.expression.ExpressionVector;
import nl.esi.xtext.expressions.expression.TypeAnnotation;
import nl.esi.xtext.types.types.EnumTypeDecl;
import nl.esi.xtext.types.types.MapTypeConstructor;
import nl.esi.xtext.types.types.MapTypeDecl;
import nl.esi.xtext.types.types.RecordField;
import nl.esi.xtext.types.types.RecordFieldKind;
import nl.esi.xtext.types.types.RecordTypeDecl;
import nl.esi.xtext.types.types.SimpleTypeDecl;
import nl.esi.xtext.types.types.Type;
import nl.esi.xtext.types.types.TypeDecl;
import nl.esi.xtext.types.types.TypeReference;
import nl.esi.xtext.types.types.VectorTypeConstructor;
import nl.esi.xtext.types.types.VectorTypeDecl;
import nl.esi.xtext.types.utilities.TypeUtilities;

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
			return "<" + getTypeName(type) + ">[]";
		} else if (type instanceof MapTypeConstructor) {
			return "<" + getTypeName(type) + ">{}";
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
			else if (simpleType.getName().equals("string")) return "\"\"";
			else return "\"\""; // Custom types without base (e.g. type DateTime)
		} else if (type instanceof VectorTypeDecl) {
			return "[]";
		} else if (type instanceof EnumTypeDecl enumType) {
			return String.format("%s::%s", enumType.getName(), enumType.getLiterals().get(0).getName());
		} else if (type instanceof MapTypeDecl) {
			return "{}";
		} else if (type instanceof RecordTypeDecl recType) {
			List<RecordField> recFields = getAllFields(recType).stream().filter(f -> !RecordFieldKind.SYMBOLIC.equals(f.getKind())).toList();
			if (recFields.size() > 1) {
				String fieldIndent = indent + "\t";
				String value = recFields.stream()
					.map(f -> String.format("%s%s = %s", fieldIndent, f.getName(), createDefaultValue(f.getType(), f.getName(), fieldIndent)))
					.collect(Collectors.joining(",\n"));
				return String.format("%s {\n%s\n%s}", type.getName(), value, indent);
			} else {
				String value = recFields.stream()
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
		} else if (expression instanceof ExpressionNullLiteral) {
			return "null";
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
		}
		
		throw new RuntimeException("Not supported");
	}
}
