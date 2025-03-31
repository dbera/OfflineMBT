package nl.esi.comma.assertthat.generator;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.EList;

import nl.esi.comma.assertthat.assertThat.AssertGlobalMargin;
import nl.esi.comma.assertthat.assertThat.AssertGlobalRegex;
import nl.esi.comma.assertthat.assertThat.AssertNamespace;
import nl.esi.comma.assertthat.assertThat.AssertThatBlock;
import nl.esi.comma.assertthat.assertThat.AssertThatValue;
import nl.esi.comma.assertthat.assertThat.AssertThatValueClose;
import nl.esi.comma.assertthat.assertThat.AssertThatValueEq;
import nl.esi.comma.assertthat.assertThat.AssertThatValueIdentical;
import nl.esi.comma.assertthat.assertThat.AssertThatValueMatch;
import nl.esi.comma.assertthat.assertThat.AssertThatValueSimilar;
import nl.esi.comma.assertthat.assertThat.AssertThatValueSize;
import nl.esi.comma.assertthat.assertThat.AssertThatXMLFile;
import nl.esi.comma.assertthat.assertThat.AssertThatXPaths;
import nl.esi.comma.assertthat.assertThat.AssertXMLValidations;
import nl.esi.comma.assertthat.assertThat.AssertXPathValidations;
import nl.esi.comma.assertthat.assertThat.ComparisonsForMultiReference;
import nl.esi.comma.assertthat.assertThat.ComparisonsForSingleReference;
import nl.esi.comma.assertthat.assertThat.DataAssertionItem;
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock;
import nl.esi.comma.assertthat.assertThat.MARGIN_TYPE;
import nl.esi.comma.assertthat.assertThat.MargingItem;
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

public class AssertionsHelper {

	static List<AssertThatBlock> getAssertions(EList<DataAssertionItem> assertionItemsList) {
		List<AssertThatBlock> list = new ArrayList<>();
		for (DataAssertionItem item : assertionItemsList)
			if (item instanceof AssertThatBlock)
				list.add((AssertThatBlock) item);
		return list;
	}

	static List<GenericScriptBlock> getScriptCalls(EList<DataAssertionItem> assertionItemsList) {
		List<GenericScriptBlock> list = new ArrayList<>();
		for (DataAssertionItem item : assertionItemsList)
			if (item instanceof GenericScriptBlock)
				list.add((GenericScriptBlock) item);
		return list;
	}

	static String printAssertions(List<AssertThatBlock> assertList) {
		String ASSERTS_TEMPLATE = "asserts=[\r\n\t%s\r\n]";

		List<String> assertionList = new ArrayList<>();
		for (AssertThatBlock assertThatBlock : assertList) {
			assertionList.add(parseAssertThat(assertThatBlock));
		}
		return String.format(ASSERTS_TEMPLATE, String.join(",", assertionList));
	}

	private static String parseAssertThat(AssertThatBlock asrt) {
		String type = "xxxx";
		List<String> comparisons = new ArrayList<>();
		String SINGLE_ASSERTION_TEMPLATE = """
				{
				\t"id":"%s", "type":"%s",
				\t"input":{
				\t\t%s
				\t}
				}
				""";
		comparisons.add(String.format("\"output\":\"%s\"", expression(asrt.getOutput(), t -> t)));
		if (asrt.getVal() instanceof AssertThatValue) {
			type = "Value";
			parseComparison(((AssertThatValue) asrt.getVal()), comparisons);
		} else if (asrt.getVal() instanceof AssertThatXPaths) {
			type = "XPaths";
			parseComparison(((AssertThatXPaths) asrt.getVal()), comparisons);
		} else if (asrt.getVal() instanceof AssertThatXMLFile) {
			type = "XMLFile";
			parseComparison(((AssertThatXMLFile) asrt.getVal()), comparisons);
		}
		String assertionFormatted = SINGLE_ASSERTION_TEMPLATE.formatted(
				asrt.getIdentifier(), 
				type, 
				String.join(",\r\n\t\t", comparisons)
				);
		System.out.println(assertionFormatted);
		return assertionFormatted;
	}

	private static void parseComparison(AssertThatValue assertion, List<String> comparisons) {
		ComparisonsForSingleReference comparisonType = assertion.getComparisonType();
		extractSingleComparison(comparisonType, comparisons);
	}

	private static void extractSingleComparison(ComparisonsForSingleReference comparisonType,
			List<String> comparisons) {
		if (comparisonType instanceof AssertThatValueEq)
			extractComparisons(((AssertThatValueEq) comparisonType), comparisons);
		else if (comparisonType instanceof AssertThatValueClose)
			extractComparisons(((AssertThatValueClose) comparisonType), comparisons);
		else if (comparisonType instanceof AssertThatValueMatch)
			extractComparisons(((AssertThatValueMatch) comparisonType), comparisons);
		else if (comparisonType instanceof AssertThatValueSize)
			extractComparisons(((AssertThatValueSize) comparisonType), comparisons);
		else
			throw new RuntimeException("Not supported");
	}

	private static void extractMultiComparison(ComparisonsForMultiReference comparisonType, List<String> comparisons) {
		if (comparisonType instanceof AssertThatValueIdentical)
			extractComparisons(((AssertThatValueIdentical) comparisonType), comparisons);
		else if (comparisonType instanceof AssertThatValueSimilar)
			extractComparisons(((AssertThatValueSimilar) comparisonType), comparisons);
		else
			throw new RuntimeException("Not supported");
	}

	private static void extractComparisons(AssertThatValueIdentical parsed, List<String> comparisons) {
		// Do nothing!
	}

	private static void extractComparisons(AssertThatValueSimilar parsed, List<String> comparisons) {
		extractComparisons(parsed.getMargin(), comparisons);
	}

	private static void extractComparisons(AssertThatValueEq parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(JsonHelper.jsonElement(parsed.getReference())));
		extractComparisons(parsed.getMargin(), comparisons);
		if (parsed.isAsRegex())
			comparisons.add("\"regex\":True");
	}

	private static void extractComparisons(AssertThatValueClose parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(JsonHelper.jsonElement(parsed.getReference())));
		extractComparisons(parsed.getMargin(), comparisons);
	}

	private static void extractComparisons(AssertThatValueMatch parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(JsonHelper.jsonElement(parsed.getReference())));
		comparisons.add("\"regex\":True");
	}

	private static void extractComparisons(AssertThatValueSize parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(parsed.getReference()));
		comparisons.add("\"size_compare\":True");
	}

	private static void extractComparisons(MargingItem mrg, List<String> comparisons) {
		if (mrg instanceof MargingItem) {
			String marginTypeStr = MARGIN_TYPE.NONE.getLiteral();
			if (mrg.getType().equals(MARGIN_TYPE.NONE)) {
				marginTypeStr = MARGIN_TYPE.NONE.getLiteral();
			} else if (mrg.getType().equals(MARGIN_TYPE.ABSOLUTE) || mrg.getType().equals(MARGIN_TYPE.RELATIVE)) {
				marginTypeStr = String.format("{\"type\":\"%s\", \"value\":%f}", mrg.getType().getLiteral(),
						mrg.getMarginVal());
			} else
				throw new RuntimeException("Not supported");
			comparisons.add("\"margin\":%s".formatted(marginTypeStr));
		}
	}

	private static void parseComparison(AssertThatXPaths assertion, List<String> comparisons) {
		extractXPathComparisons(assertion.getAssertRef(), comparisons);

		if (assertion.getNamespace() instanceof AssertNamespace)
			extractComparisons(assertion.getNamespace(), comparisons);
		if (assertion.getGlobalMargin() instanceof AssertGlobalMargin)
			extractComparisons(assertion.getGlobalMargin(), comparisons);
		if (assertion.getGlobalRegex() instanceof AssertGlobalRegex)
			extractComparisons(assertion.getGlobalRegex(), comparisons);
	}

	private static void extractXPathComparisons(EList<AssertXPathValidations> assertRef, List<String> comparisons) {
		List<String> xpathList = new ArrayList<String>();
		for (AssertXPathValidations anAssert : assertRef) {
			List<String> xpathItem = new ArrayList<String>();
			extractComparisons(anAssert, xpathItem);
			String xpathItemStr = String.join(",\r\n\t\t\t", xpathItem);
			xpathList.add("{%s}".formatted(xpathItemStr));
		}
		String xpaths = String.join(",\r\n\t\t", xpathList);
		comparisons.add("\"xpaths\":[%s]".formatted(xpaths));
	}

	private static void extractComparisons(AssertXPathValidations item, List<String> comparisons) {
		if (item.getLoggingId() != null)
			comparisons.add("\"id\":%s".formatted(item.getLoggingId()));
		comparisons.add("\"xpath\":%s".formatted(item.getXpath()));
		extractSingleComparison(item.getComparisonType(), comparisons);
	}

	private static void extractComparisons(AssertNamespace item, List<String> comparisons) {
		if (item != null)
			comparisons.add("\"namespaces\":%s".formatted(JsonHelper.jsonElement(item.getNamespaceMap())));
	}

	private static void extractComparisons(AssertGlobalMargin item, List<String> comparisons) {
		extractComparisons(item.getMargin(), comparisons);
	}

	private static void extractComparisons(AssertGlobalRegex item, List<String> comparisons) {
		if (item != null)
			comparisons.add("\"regex\":True");
	}

	private static void parseComparison(AssertThatXMLFile assertion, List<String> comparisons) {
		extractXMLComparisons(assertion.getAssertRef(), comparisons);

		if (assertion.getNamespace() instanceof AssertNamespace)
			extractComparisons(assertion.getNamespace(), comparisons);
		if (assertion.getGlobalMargin() instanceof AssertGlobalMargin)
			extractComparisons(assertion.getGlobalMargin(), comparisons);
	}

	private static void extractXMLComparisons(EList<AssertXMLValidations> assertRef, List<String> comparisons) {
		List<String> xpathList = new ArrayList<String>();
		for (AssertXMLValidations anAssert : assertRef) {
			List<String> xpathItem = new ArrayList<String>();
			extractComparisons(anAssert, xpathItem);
			String xpathItemStr = String.join(",\r\n\t\t\t", xpathItem);
			xpathList.add("{%s}".formatted(xpathItemStr));
		}
		String xpaths = String.join(",\r\n\t\t", xpathList);
		comparisons.add("\"xpaths\":[%s]".formatted(xpaths));
	}

	private static void extractComparisons(AssertXMLValidations item, List<String> comparisons) {
		if (item.getLoggingId() != null)
			comparisons.add("\"id\":%s".formatted(item.getLoggingId()));
		comparisons.add("\"xpath\":%s".formatted(item.getXpath()));
		extractMultiComparison(item.getComparisonType(), comparisons);
	}

	//TODO Adapt expression helper to FAST format 
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
			} else if (e.getFunctionName().equals("at")) {
				String lst = expression(e.getArgs().get(0), variablePrefix);
				String idx = expression(e.getArgs().get(1), variablePrefix);
				String val = expression(e.getArgs().get(2), variablePrefix);
				return String.format("%s; %s[%s] = %s", lst, lst, idx, val);
			} else if (e.getFunctionName().equals("deleteKey")) {
				String map = expression(e.getArgs().get(0), variablePrefix);
				String key = expression(e.getArgs().get(1), variablePrefix);
				return String.format("{_k: _v for _k, _v in %s.items() if _k != %s}", map, key);
			} else if (e.getFunctionName().equals("uuid")) {
				return String.format("uuid.uuid4().hex");
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
