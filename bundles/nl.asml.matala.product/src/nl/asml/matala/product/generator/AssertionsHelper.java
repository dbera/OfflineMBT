package nl.asml.matala.product.generator;

import nl.esi.comma.assertthat.assertThat.DataAssertionItem;
import nl.esi.comma.assertthat.assertThat.AssertClose;
import nl.esi.comma.assertthat.assertThat.AssertEq;
import nl.esi.comma.assertthat.assertThat.AssertMatch;
import nl.esi.comma.assertthat.assertThat.AssertSize;
import nl.esi.comma.assertthat.assertThat.AssertThatBlock;
import nl.esi.comma.assertthat.assertThat.AssertThatValue;
import nl.esi.comma.assertthat.assertThat.AssertThatXMLFile;
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock;
import nl.esi.comma.assertthat.assertThat.JsonMember;
import nl.esi.comma.assertthat.assertThat.JsonValue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import com.google.gson.Gson;
import com.google.gson.JsonPrimitive;

import nl.esi.comma.expressions.expression.Expression;
import nl.esi.comma.expressions.expression.ExpressionRecord;

public class AssertionsHelper {

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

	static String printAssertion(AssertThatBlock ref) {
		if (ref.getVal() != null) {
			AssertThatValueEqualTo obj = new AssertThatValueEqualTo();
			obj.id = ref.getIdentifier();
			AssertThatValue atval = (AssertThatValue) ref.getVal();
			if (atval.getAssertEq() != null) {
				AssertEq val = atval.getAssertEq();
				obj.output = val.getOutRef().toString();
				if (val.isAsRegex()) {
					obj.asRegex = val.isAsRegex();
				}
				if (val.getOutMrg() != null) {
					obj.margin = new WithinMargin();
					obj.margin.type = val.getOutMrg().getType().getLiteral();
					obj.margin.value = val.getOutMrg().getMarginVal();
				}
				System.out.println(obj);
			} else if (atval.getAssertCl() != null) {
				AssertClose val = atval.getAssertCl();
				// ...
			} else if (atval.getAssertMt() != null) {
				AssertMatch val = atval.getAssertMt();
				// ...
			} else if (atval.getAssertSz() != null) {
				AssertSize val = atval.getAssertSz();
				// ...
			}
//		} else if (ref.getReference() instanceof AssertThatXPath) {
//			AssertThatXPath atxpa = (AssertThatXPath) ref.getReference();
//		} else if (ref.getReference() instanceof AssertThatXMLFile) {
//			AssertThatXMLFile atxml = (AssertThatXMLFile) ref.getReference();
		}
		return "";
	}
//
//    dispatch def String printAssertion(AssertThatValue ref) {
//        var output = '''
//            {
//                "id":"«printAssertion(ref.type)»", "type":"xxxx", "input":{
//                }
//            }
//        '''
//        return output
//    }
//
//    dispatch def String printAssertion(AssertEq ref) {
//        var output = '''
//            {
//                "regex":"«ref.asRegex»"
//            }
//        '''
//        return output
//    }
}
