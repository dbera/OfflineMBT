package nl.asml.matala.product.generator;

import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.List;

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
		comparisons.add(String.format("\"output\":\"%s\"", SnakesHelper.expression(asrt.getOutput(), t -> t)));
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
//		{
//	        "id":"assert_number", "type":"Value",
//	        "input":{
//	            "output":"['step_output']['my_step_id']['path_to_some_number']",
//	            "reference":1.234,
//	            "margin":{"type":"Absolute", "value":0.02}
//	            "regex":True
//	            "size_compare":True
//	        }
//	    },
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
//	    {
//	        "id":"assert_xpaths", "type":"XPaths",
//	        "input":{
//	            "output":"['step_output']['my_step_id']['path_to_some_xml_file']",
//	            "xpaths":[
//	                {
//	                    "id":"compare_one_occurence_value",
//	                    "xpath":"//My/XPath/To/Some/Value/With/One/Occurence/text()",
//	                    "reference":1.234,
//	                    "margin":{"type":"Relative", "value":0.1}
//	                },
//	                    "reference":[0.123, 0.234, 0.345],
//	                    // Optionally set the xpath-specific margin to 'None', to get exact value compare for this xpath
//	                    "margin":None,
//	                    "regex":False
//	                },
//	            ],
//	            "margin":{"type":"Absolute", "value":0.02},
//	            "regex":True
//	        }
//	    },
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
//        "id":"compare_xpaths_to_reference_files", "type":"XMLFile",
//        "input":{
//            "output":"['step_output']['my_step_id']['path_to_some_xml_file']",
//            "reference":"./vfab2_scenario/FAST/testcases/MyTestCase/datachecks/reference/MyReferenceFile.xml",
//            "xpaths":[
//                {
//                    "id":"compare_one_occurence_value",
//                    "xpath":"//My/XPath/To/Some/Value/With/One/Occurence/text()",
//                    "margin":{"type":"Relative", "value":0.1}
//                },
//                {
//                    "xpath":"//My/XPath/To/Some/StringValue/With/Multiple/Occurences/text()"
//                }
//            ],
//        "margin":{"type":"Absolute", "value":0.02},
//        "namespaces":{"sig":"http://www.w3.org/2000/09/xmldsig#"}
//        }
//    }
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
}
