package nl.asml.matala.product.generator;

import nl.esi.comma.assertthat.assertThat.DataAssertionItem;
import nl.esi.comma.assertthat.assertThat.AssertClose;
import nl.esi.comma.assertthat.assertThat.AssertEq;
import nl.esi.comma.assertthat.assertThat.AssertIdentical;
import nl.esi.comma.assertthat.assertThat.AssertMatch;
import nl.esi.comma.assertthat.assertThat.AssertSimilar;
import nl.esi.comma.assertthat.assertThat.AssertSize;
import nl.esi.comma.assertthat.assertThat.AssertThatBlock;
import nl.esi.comma.assertthat.assertThat.AssertThatValue;
import nl.esi.comma.assertthat.assertThat.AssertThatXMLFile;
import nl.esi.comma.assertthat.assertThat.AssertThatXPath;
import nl.esi.comma.assertthat.assertThat.AssertXPathValidations;
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock;
import nl.esi.comma.assertthat.assertThat.JsonMember;
import nl.esi.comma.assertthat.assertThat.JsonValue;
import nl.esi.comma.assertthat.assertThat.MARGIN_TYPE;
import nl.esi.comma.assertthat.assertThat.MargingItem;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import com.google.gson.Gson;
import com.google.gson.JsonPrimitive;

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


	static String printAssertion(AssertThatBlock assertThat) {
		String assertionTemplate = ""
								//+  "asserts=[\r\n"  
								+  "\t{\r\n"
								+  "\t\t\"id\":\"%s\", \"type\":\"%s\",\r\n"
								+  "\t\t\"input\":{\r\n"
								+  "\t\t\t\"output\":{%s\r\n"
								+  "%s"
								+  "\t}"
								//+  "]"
							  ;
		String assertionId = assertThat.getIdentifier();
		String assertionType = null;
		String assertionOutput = SnakesHelper.expression(assertThat.getOutput().getSub(), t->"[\"%s\"]".formatted(t));
		String assertionComparison = null;
		
		if (assertThat.getAssertType() instanceof AssertThatValue) {
			assertionType = "Value";
			assertionComparison = assertionComparison((AssertThatValue) assertThat.getAssertType());
		}else if (assertThat.getAssertType() instanceof AssertThatXPath) {
			assertionType = "XPaths";
			assertionComparison = assertionComparison((AssertThatXPath) assertThat.getAssertType());
		}else if (assertThat.getAssertType() instanceof AssertThatXMLFile) {
			assertionType = "XMLFile";
			assertionComparison = assertionComparison((AssertThatXMLFile) assertThat.getAssertType());
		} else {
			throw new RuntimeException("Not supported");
		}
		String assertionStr = String.format(assertionTemplate, assertionId, assertionType, assertionOutput, assertionComparison);
		System.out.println(assertionStr);
		return assertionStr;
	}
	
	private static String assertionComparison(AssertThatValue assertType) {
		String assertionStr = assertionType(assertType.getComparisonType());
		return assertionStr;
	}
	
	private static String assertionComparison(AssertThatXPath assertType) {
		String assertionStr = "\t\"xpaths\":[";
		List<String> xpathValsList = new ArrayList<>();
		for (AssertXPathValidations xpathval : assertType.getAssertRef()) {
//			xpathValsList
			String _xpathVal = assertionType(xpathval.getComparisonType());
			xpathValsList.add(_xpathVal);
		}
		assertionStr+= String.join(",", xpathValsList);
		assertionStr += "]";
		return assertionStr;
	}

	private static String assertionComparison(AssertThatXMLFile assertType) {
//		assertionObj.put("type", "XMLFile");
		String assertionStr = "asserts=[\r\n"  + "    {\r\n";
		return assertionStr;
	}
	
	static String assertionType(EObject assertThat) {
		String pref = "\t\t\t\t";
		String assertionStr = "{";
		if (assertThat instanceof AssertEq) {
			AssertEq asrt = ((AssertEq) assertThat);
			assertionStr += String.format(pref+"\"output\":%s,\r\n", JsonHelper.jsonValue(asrt.getReference()));
			if (asrt.getOutMrg() != null) {
				MargingItem mrg = asrt.getOutMrg();
				assertionStr += pref+"\"margin\":";
				if (mrg.getType().equals(MARGIN_TYPE.NONE)) assertionStr += "None";
				else assertionStr += String.format("{\"type\":\"%s\", \"value\":%f}", mrg.getType(),mrg.getMarginVal());
				assertionStr += "\r\n";
			}
			if (asrt.isAsRegex()) {
				assertionStr += pref+"\"regex\":True\r\n";
			}
		}else if (assertThat instanceof AssertClose) {
			//return ""; 
		}else if (assertThat instanceof AssertMatch) {
			//return ""; 
		}else if (assertThat instanceof AssertSize) {
			//return ""; 
		}else if (assertThat instanceof AssertIdentical) {
			//return ""; 
		}else if (assertThat instanceof AssertSimilar) {
			//return ""; 
		} else throw new RuntimeException("Not supported comparison type");
		assertionStr += "}";
		return assertionStr;
	}

	public static String printAssertion(DataAssertionItem ref) {
		if (ref instanceof AssertThatBlock) {
			return printAssertion((AssertThatBlock) ref);
		}
		return printAssertion((GenericScriptBlock) ref);
	}

	public static String printAssertion(GenericScriptBlock ref) {
		Map<String, Object> gsonMap = new HashMap<>();
		gsonMap.put("id", ref.getAssignment().getName());
		gsonMap.put("script_path", ref.getParams().getScriptPath());

		List<Map<String, String>> parameters = new ArrayList<>();
		gsonMap.put("parameters", parameters);

		for (JsonValue param : ref.getParams().getParamsPositional().getValues()) {
			if (!(param.getExpr() instanceof Expression))
				continue;
			Expression expr = (Expression) param.getExpr();
			System.out.println(SnakesHelper.expression(expr, t -> t));
			Map<String, String> paramMap = new HashMap<>() {
				{
					put("type", "OUTPUT");
//    			put("value", SnakesHelper.expression(expr));
				}
			};
			parameters.add(paramMap);
		}
		return "";
	}

//	static String printAssertion(AssertThatBlock ref) {
//		if (ref.getVal() != null) {
//			AssertThatValueEqualTo obj = new AssertThatValueEqualTo();
//			obj.id = ref.getIdentifier();
//			AssertThatValue atval = (AssertThatValue) ref.getVal();
//			if (atval.getAssertEq() != null) {
//				AssertEq val = atval.getAssertEq();
//				obj.output = val.getOutRef().toString();
//				if (val.isAsRegex()) {
//					obj.asRegex = val.isAsRegex();
//				}
//				if (val.getOutMrg() != null) {
//					obj.margin = new WithinMargin();
//					obj.margin.type = val.getOutMrg().getType().getLiteral();
//					obj.margin.value = val.getOutMrg().getMarginVal();
//				}
//				System.out.println(obj);
//			} else if (atval.getAssertCl() != null) {
//				AssertClose val = atval.getAssertCl();
//				// ...
//			} else if (atval.getAssertMt() != null) {
//				AssertMatch val = atval.getAssertMt();
//				// ...
//			} else if (atval.getAssertSz() != null) {
//				AssertSize val = atval.getAssertSz();
//				// ...
//			}
////		} else if (ref.getReference() instanceof AssertThatXPath) {
////			AssertThatXPath atxpa = (AssertThatXPath) ref.getReference();
////		} else if (ref.getReference() instanceof AssertThatXMLFile) {
////			AssertThatXMLFile atxml = (AssertThatXMLFile) ref.getReference();
//		}
//		return "";
//	}
////
////    dispatch def String printAssertion(AssertThatValue ref) {
////        var output = '''
////            {
////                "id":"«printAssertion(ref.type)»", "type":"xxxx", "input":{
////                }
////            }
////        '''
////        return output
////    }
////
////    dispatch def String printAssertion(AssertEq ref) {
////        var output = '''
////            {
////                "regex":"«ref.asRegex»"
////            }
////        '''
////        return output
//    }
}
