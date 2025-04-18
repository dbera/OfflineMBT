package nl.esi.comma.testspecification.abstspec.generator;

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
import nl.esi.comma.assertthat.assertThat.AssertValidation;
import nl.esi.comma.assertthat.assertThat.AssertXMLValidations;
import nl.esi.comma.assertthat.assertThat.AssertXPathValidations;
import nl.esi.comma.assertthat.assertThat.ComparisonsForMultiReference;
import nl.esi.comma.assertthat.assertThat.ComparisonsForSingleReference;
import nl.esi.comma.assertthat.assertThat.DataAssertionItem;
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock;
import nl.esi.comma.assertthat.assertThat.MARGIN_TYPE;
import nl.esi.comma.assertthat.assertThat.MargingItem;
import nl.esi.comma.assertthat.assertThat.ScriptParametersCustom;
import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionBracket;
import nl.esi.comma.expressions.expression.ExpressionBulkData;
import nl.esi.comma.expressions.expression.ExpressionConstantBool;
import nl.esi.comma.expressions.expression.ExpressionConstantInt;
import nl.esi.comma.expressions.expression.ExpressionConstantReal;
import nl.esi.comma.expressions.expression.ExpressionConstantString;
import nl.esi.comma.expressions.expression.ExpressionMapRW;
import nl.esi.comma.expressions.expression.ExpressionMinus;
import nl.esi.comma.expressions.expression.ExpressionPlus;
import nl.esi.comma.expressions.expression.ExpressionRecord;
import nl.esi.comma.expressions.expression.ExpressionRecordAccess;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.expressions.expression.ExpressionVector;

/**
 *
 */
public class AssertionsHelper {

	/**
	 * Filters all AssertThatBlock items from an EList of DataAssertionItem
	 * @param assertionItemsList
	 * @return List of AssertThatBlock objects
	 */
	public static List<AssertThatBlock> getAssertions(EList<DataAssertionItem> assertionItemsList) {
		List<AssertThatBlock> list = new ArrayList<>();
		for (DataAssertionItem item : assertionItemsList) {
			if (item instanceof AssertThatBlock) {
				list.add((AssertThatBlock) item);
			}
		}
		return list;
	}

	/**
	 * Filters all GenericScriptBlock items from an EList of DataAssertionItem
	 * @param assertionItemsList
	 * @return List of GenericScriptBlock objects
	 */
	public static List<GenericScriptBlock> getScriptCalls(EList<DataAssertionItem> assertionItemsList) {
		List<GenericScriptBlock> list = new ArrayList<>();
		for (DataAssertionItem item : assertionItemsList) {
			if (item instanceof GenericScriptBlock) {
				list.add((GenericScriptBlock) item);
			}
		}
		return list;
	}

	/**
	 * Parses a list of GenericScriptBlock objects into string format.
	 * @param assertList
	 * @return String representation of a list of assertions.
	 */
	public static String printScriptCall(List<GenericScriptBlock> scriptcallList) {
		String ASSERTS_TEMPLATE = "asserts=[\r\n\t%s\r\n]";

		List<String> assertionList = new ArrayList<>();
		for (GenericScriptBlock scriptBlock : scriptcallList) {
			assertionList.add(parseScriptCall(scriptBlock));
		}
		return String.format(ASSERTS_TEMPLATE, String.join(",", assertionList));
	}

	/**
	 * Parses a list of AssertThatBlock objects into string format.
	 * @param assertList
	 * @return String representation of a list of assertions.
	 */
	public static String printAssertions(List<AssertThatBlock> assertList) {
		String ASSERTS_TEMPLATE = "asserts=[\r\n\t%s\r\n]";

		List<String> assertionList = new ArrayList<>();
		for (AssertThatBlock assertThatBlock : assertList) {
			assertionList.add(parseAssertThat(assertThatBlock));
		}
		return String.format(ASSERTS_TEMPLATE, String.join(",", assertionList));
	}

	/**
	 * Parses an assertion block into a string, as in the reference.kvp format.
	 * The string representation includes an assertion identifier, its type, and input parameters.
	 * Input parameters include the output value to be verified and the parameters accepted by its
	 * respective type (i.e., Value, XPaths, XMLFile).
	 * @param asrt Assertion block to be parsed into string
	 * @return string representation of an assertion block
	 */
	public static String parseAssertThat(AssertThatBlock asrt) {
		String type = "xxxx";
		List<String> comparisons = new ArrayList<>();
		// the assertion template with ID, type, and input parameters
		String SINGLE_ASSERTION_TEMPLATE = """
				{
				\t"id":"%s", "type":"%s",
				\t"input":{
				\t\t%s
				\t}
				}
				""";
		comparisons.add(String.format("\"output\":\"%s\"", expression(asrt.getOutput(), t -> t)));
		AssertValidation val_asrt = asrt.getVal();
		if (val_asrt instanceof AssertThatValue pasrt) {
			// assertion of type Value
			type = "Value";
			extractComparison(pasrt, comparisons);
		} else if (val_asrt instanceof AssertThatXPaths pasrt) {
			// assertion of type XPaths
			type = "XPaths";
			extractComparison(pasrt, comparisons);
		} else if (val_asrt instanceof AssertThatXMLFile pasrt) {
			// assertion of type XMLFile
			type = "XMLFile";
			extractComparison(pasrt, comparisons);
		}
		// fills in the gaps in the assertion template
		String assertionFormatted = SINGLE_ASSERTION_TEMPLATE.formatted(
				asrt.getIdentifier(),
				type,
				String.join(",\r\n\t\t", comparisons)
				);
		return assertionFormatted;
	}

	/**
	 * Parses a script call block into a string, as in the reference.kvp format.
	 * This string representation includes a script call identifier, the path to the script,
	 * and a list of input parameters.
	 * Input parameters are formed by a type,
	 * and assigned value which may be a list, dictionary or key-value pair.
	 * @param asrt Script call block to be parsed into string
	 * @return string representation of a script call block
	 */
	public static String parseScriptCall(GenericScriptBlock scrptcall) {
		List<String> scrptparams = new ArrayList<>();
		// the assertion template with ID, type, and input parameters
		String SINGLE_ASSERTION_TEMPLATE = """
				{
				\t"id":"%s",
				\t"script_path":"%s",
				\t"parameters":{
				\t\t%s
				\t}
				}
				""";
		extractScriptParameters(scrptcall.getParams(), scrptparams);
		// fills in the gaps in the assertion template
		String assertionFormatted = SINGLE_ASSERTION_TEMPLATE.formatted(
				scrptcall.getAssignment().getName(),
				scrptcall.getParams().getScriptApi(),
				String.join(",\r\n\t\t", scrptparams)
				);
		return assertionFormatted;
	}

	/**
	 * Parses input parameters of a script-call, which include.
	 * - the script ID, derived from the variable to which the script result will be assigned
	 * - the path to the script to be executed
	 * - the list of input parameters,
	 * - its length, given the observed output is a string/array/map (has-size).
	 *
	 * @param params
	 * @param scrptparams
	 */
	private static void extractScriptParameters(ScriptParametersCustom params, List<String> scrptparams) {
		extractScriptParameters_OUTPUT(params.getScriptOut(), scrptparams);
		int nargs = params.getScriptArgs().size();
		for (int i = 0; i < nargs; i++) {
			List<String> argInfo = new ArrayList<>();
			String arg_str = String.join(",\r\n\t\t\t", argInfo);
			scrptparams.add("{%s}".formatted(arg_str));
		}
	}

	private static void extractScriptParameters_OUTPUT(String param, List<String> scrptparams) {
		List<String> argInfo = new ArrayList<>();
		argInfo.add("\"type\":\"%s\"".formatted("OUTPUT"));
		argInfo.add("\"value\":\"%s\"".formatted(param));
		String arg_str = String.join(",\r\n\t\t\t", argInfo);
		scrptparams.add("{%s}".formatted(arg_str));
	}

	private static void extractScriptParameters_OTHERS(Expression param, List<String> scrptparams) {
		List<String> argInfo = new ArrayList<>();
		String arg_str = String.join(",\r\n\t\t\t", argInfo);
		scrptparams.add("{%s}".formatted(arg_str));

		if(param instanceof ExpressionConstantString pparam) {
			scrptparams.add("\"value\":\"%s\"".formatted(pparam.getValue()));
		}else if(param instanceof ExpressionConstantInt pparam) {
			scrptparams.add("\"value\":\"%s\"".formatted(pparam.getValue()));
		}else if(param instanceof ExpressionConstantBool pparam) {
			scrptparams.add("\"value\":\"%s\"".formatted(pparam.isValue()));
		}else if(param instanceof ExpressionConstantReal pparam) {
			scrptparams.add("\"value\":\"%s\"".formatted(pparam.getValue()));
		}else if (param instanceof ExpressionRecordAccess pparam) {
			scrptparams.add("\"value\":%s".formatted(expression(pparam, (String t) -> "")));
		}else {
			throw new RuntimeException("Not supported");
		}
	}

	/**
	 * Parses input parameters of an assertion of Value type
	 * into string format. Strings for each parameters are added in the comparisons list.
	 * @param assertion Assertion of type value to be parsed into string
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractComparison(AssertThatValue assertion, List<String> comparisons) {
		ComparisonsForSingleReference comparisonType = assertion.getComparisonType();
		extractSingleComparison(comparisonType, comparisons);
	}


	/**
	 * Parses input parameters of an assertion of Value or XPaths type
	 * for comparing observed output against a single reference value (in an xpath, for XPaths) w.r.t.
	 * - their precise difference (equal-to),
	 * - their absolute or relative difference (close-to),
	 * - a regular expression (match-regex),
	 * - its length, given the observed output is a string/array/map (has-size).
	 * If this object is not a known subclass of ComparisonsForSingleReference, an exception will be thrown
	 * @param comparisonType Reference value used for verifying whether the observed output is the same (equal-to), approximately equal (close-to), matches with a regular expression (match-regex), or has a given length (has-size)
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractSingleComparison(ComparisonsForSingleReference comparisonType,
			List<String> comparisons) {
		if (comparisonType instanceof AssertThatValueEq pparam) {
			extractComparisons(pparam, comparisons);
		} else if (comparisonType instanceof AssertThatValueClose pparam) {
			extractComparisons(pparam, comparisons);
		} else if (comparisonType instanceof AssertThatValueMatch pparam) {
			extractComparisons(pparam, comparisons);
		} else if (comparisonType instanceof AssertThatValueSize pparam) {
			extractComparisons(pparam, comparisons);
		} else {
			throw new RuntimeException("Not supported");
		}
	}

	/**
	 * Parses input parameters of an assertion of XMLFile type
	 * for comparing outputs observed in a list of XPaths of two XML files w.r.t.
	 * - their precise difference (are-identical),
	 * - their absolute or relative difference (are-similar),
	 * If this object is not a known subclass of ComparisonsForMultiReference, an exception will be thrown
	 * @param comparisonType Reference value used for verifying whether the observed output is the same (are-similar), or approximately equal (are-similar).
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractMultiComparison(ComparisonsForMultiReference comparisonType, List<String> comparisons) {
		if (comparisonType instanceof AssertThatValueIdentical pparam) {
			extractComparisons(pparam, comparisons);
		} else if (comparisonType instanceof AssertThatValueSimilar pparam) {
			extractComparisons(pparam, comparisons);
		} else {
			throw new RuntimeException("Not supported");
		}
	}

	/**
	 * Parses input parameters of an assertion of XMLFile type for checking their equality.
	 * No string will be added to @comparisons, as no additional parameter is needed for checking equality.
	 * @param parsed input parameter for checking equality
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractComparisons(AssertThatValueIdentical parsed, List<String> comparisons) {
		// Do nothing!
	}

	/**
	 * Parses input parameters of an assertion of XMLFile type for checking their delta.
	 * A string representation to its margin/delta may be added to @comparisons.
	 * @param parsed input parameter for checking the closeness of a number given a certain margin.
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractComparisons(AssertThatValueSimilar parsed, List<String> comparisons) {
		extractComparisons(parsed.getMargin(), comparisons);
	}

	/**
	 * Adds input parameters for an assertion of that checks equality.
	 * It can also add parameters for using reference value as REGEX.
	 * @param parsed input parameter for checking the equality, which may optionally be a REGEX.
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractComparisons(AssertThatValueEq parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(JsonHelper.jsonElement(parsed.getReference())));
		extractComparisons(parsed.getMargin(), comparisons);
		if (parsed.isAsRegex()) {
			comparisons.add("\"regex\":True");
		}
	}

	/**
	 * Adds input parameters for an assertion that checks how close a reference value is to an observed output.
	 * A margin delta value can also be added to the comparison.
	 * @param parsed input parameter for checking the similarity margin between two values.
	 * @param comparisons List of string representation of each input parameter.
	 */
	private static void extractComparisons(AssertThatValueClose parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(JsonHelper.jsonElement(parsed.getReference())));
		extractComparisons(parsed.getMargin(), comparisons);
	}

	/**
	 * Checks if a reference REGEX matches with an observed string (output)
	 * @param parsed assertion parameter
	 * @param comparisons regex used as reference and parameter setting assertion as a REGEX checking
	 */
	private static void extractComparisons(AssertThatValueMatch parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(JsonHelper.jsonElement(parsed.getReference())));
		comparisons.add("\"regex\":True");
	}

	/**
	 * Checks if an observed array/list/map (output) has size given as reference
	 * @param parsed assertion parameter
	 * @param comparisons expected size for an array/list/map
	 */
	private static void extractComparisons(AssertThatValueSize parsed, List<String> comparisons) {
		comparisons.add("\"reference\":%s".formatted(parsed.getReference()));
		comparisons.add("\"size_compare\":True");
	}

	/**
	 * Adds margin (delta) for a close-to and are-similar assertion input parameter
	 * @param mrg margin considered
	 * @param comparisons list of input parameters for an assertion
	 */
	private static void extractComparisons(MargingItem mrg, List<String> comparisons) {
		if (mrg instanceof MargingItem) {
			String marginTypeStr = MARGIN_TYPE.NONE.getLiteral();
			if (mrg.getType().equals(MARGIN_TYPE.NONE)) {
				marginTypeStr = MARGIN_TYPE.NONE.getLiteral();
			} else if (mrg.getType().equals(MARGIN_TYPE.ABSOLUTE) || mrg.getType().equals(MARGIN_TYPE.RELATIVE)) {
				marginTypeStr = String.format("{\"type\":\"%s\", \"value\":%f}", mrg.getType().getLiteral(),
						mrg.getMarginVal());
			} else {
				throw new RuntimeException("Not supported");
			}
			comparisons.add("\"margin\":%s".formatted(marginTypeStr));
		}
	}

	/**
	 * Checks values in a series of XPaths of an XML file.
	 * Assertion may also include a namespace, a global margin and a global flag for using strings as Regex
	 * @param assertion assertion for checking values in a series of XPaths.
	 * @param comparisons
	 */
	private static void extractComparison(AssertThatXPaths assertion, List<String> comparisons) {
		extractXPathComparisons(assertion.getAssertRef(), comparisons);

		if (assertion.getNamespace() instanceof AssertNamespace) {
			extractComparisons(assertion.getNamespace(), comparisons);
		}
		if (assertion.getGlobalMargin() instanceof AssertGlobalMargin) {
			extractComparisons(assertion.getGlobalMargin(), comparisons);
		}
		if (assertion.getGlobalRegex() instanceof AssertGlobalRegex) {
			extractComparisons(assertion.getGlobalRegex(), comparisons);
		}
	}

	/**
	 * Indication of XPaths to have their values checked
	 * @param assertRef
	 * @param comparisons
	 */
	private static void extractXPathComparisons(EList<AssertXPathValidations> assertRef, List<String> comparisons) {
		List<String> xpathList = new ArrayList<>();
		for (AssertXPathValidations anAssert : assertRef) {
			List<String> xpathItem = new ArrayList<>();
			extractComparisons(anAssert, xpathItem);
			String xpathItemStr = String.join(",\r\n\t\t\t", xpathItem);
			xpathList.add("{%s}".formatted(xpathItemStr));
		}
		String xpaths = String.join(",\r\n\t\t", xpathList);
		comparisons.add("\"xpaths\":[%s]".formatted(xpaths));
	}


	/** Validation for an Xpath
	 * @param item
	 * @param comparisons
	 */
	private static void extractComparisons(AssertXPathValidations item, List<String> comparisons) {
		if (item.getLoggingId() != null) {
			comparisons.add("\"id\":\"%s\"".formatted(item.getLoggingId()));
		}
		comparisons.add("\"xpath\":%s".formatted(item.getXpath()));
		extractSingleComparison(item.getComparisonType(), comparisons);
	}

	/**
	 * Adds namespace for an XPath/XMLFile validation for
	 * @param item
	 * @param comparisons
	 */
	private static void extractComparisons(AssertNamespace item, List<String> comparisons) {
		if (item != null) {
			comparisons.add("\"namespaces\":%s".formatted(JsonHelper.jsonElement(item.getNamespaceMap())));
		}
	}

	/**
	 * Adds global margin for an XPath assertion.
	 * @param item
	 * @param comparisons
	 */
	private static void extractComparisons(AssertGlobalMargin item, List<String> comparisons) {
		extractComparisons(item.getMargin(), comparisons);
	}

	/**
	 * Adds global flag to use strings as Regex in an XPath/XMLFile assertion.
	 * @param item
	 * @param comparisons
	 */
	private static void extractComparisons(AssertGlobalRegex item, List<String> comparisons) {
		if (item != null) {
			comparisons.add("\"regex\":True");
		}
	}

	/**
	 * Assertion for an XML file
	 * Assertion may also include a namespace and a global margin.
	 * @param assertion
	 * @param comparisons
	 */
	private static void extractComparison(AssertThatXMLFile assertion, List<String> comparisons) {
		extractXMLComparisons(assertion.getAssertRef(), comparisons);

		if (assertion.getNamespace() instanceof AssertNamespace) {
			extractComparisons(assertion.getNamespace(), comparisons);
		}
		if (assertion.getGlobalMargin() instanceof AssertGlobalMargin) {
			extractComparisons(assertion.getGlobalMargin(), comparisons);
		}
	}

	/**
	 * Extracts series of assertion input parameters for checking two xml files
	 * @param assertRef
	 * @param comparisons
	 */
	private static void extractXMLComparisons(EList<AssertXMLValidations> assertRef, List<String> comparisons) {
		List<String> xpathList = new ArrayList<>();
		for (AssertXMLValidations anAssert : assertRef) {
			List<String> xpathItem = new ArrayList<>();
			extractComparisons(anAssert, xpathItem);
			String xpathItemStr = String.join(",\r\n\t\t\t", xpathItem);
			xpathList.add("{%s}".formatted(xpathItemStr));
		}
		String xpaths = String.join(",\r\n\t\t", xpathList);
		comparisons.add("\"xpaths\":[%s]".formatted(xpaths));
	}

	/**
	 * Validates xpath in
	 * @param item
	 * @param comparisons
	 */
	private static void extractComparisons(AssertXMLValidations item, List<String> comparisons) {
		if (item.getLoggingId() != null) {
			comparisons.add("\"id\":\"%s\"".formatted(item.getLoggingId()));
		}
		comparisons.add("\"xpath\":%s".formatted(item.getXpath()));
		extractMultiComparison(item.getComparisonType(), comparisons);
	}

	static String expression(Expression expression) {
		return expression(expression, (String t) -> "xxx");
	}
	/**
	 * Parses an expression into the kvp format
	 * *TODO* Adapt expression helper to FAST format
	 * @param expression expression to be parsed
	 * @param variablePrefix function to help in parsing expression
	 * @return
	 */
	static String expression(Expression expression, Function<String, String> variablePrefix) {
		if (expression instanceof ExpressionBracket e) {
			return String.format("['step_output']%s", expression(e.getSub(),variablePrefix));
		} else if (expression instanceof ExpressionConstantInt e) {
			return Long.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantString pexpr) {
			return String.format("'%s'", pexpr.getValue());
		} else if (expression instanceof ExpressionConstantReal e) {
			return Double.toString(e.getValue());
		} else if (expression instanceof ExpressionConstantBool e) {
			return e.isValue() ? "True" : "False";
		} else if (expression instanceof ExpressionMinus e) {
			return String.format("-%s", expression(e.getSub(), variablePrefix));
		} else if (expression instanceof ExpressionPlus e) {
			return expression(e.getSub(), variablePrefix);
		} else if (expression instanceof ExpressionRecordAccess e) {
			String map = expression(e.getRecord(), variablePrefix);
			return String.format("['%s']['%s']", map, e.getField().getName());
		} else if (expression instanceof ExpressionVariable v) {
			return String.format("%s", variablePrefix.apply(v.getVariable().getName()));
		} else if (expression instanceof ExpressionVector e) {
			return String.format("['%s'] ExpressionVector", e.getElements().stream().map(ee -> expression (ee, variablePrefix)).collect(Collectors.joining(", ")));
		} else if (expression instanceof ExpressionMapRW) {
			ExpressionMapRW e = (ExpressionMapRW) expression;
			String map = expression(e.getMap(), variablePrefix);
			String key = expression(e.getKey(), variablePrefix);
			if (e.getValue() == null) {
				return String.format("%s[%s]", map, key);
			}
		}

		throw new RuntimeException("Not supported");
	}

}
