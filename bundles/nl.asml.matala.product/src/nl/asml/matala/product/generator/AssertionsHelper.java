package nl.asml.matala.product.generator;

import nl.esi.comma.assertthat.assertThat.DataCheckItems;
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

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringReader;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import com.github.mustachejava.MustacheFactory;

public class AssertionsHelper {

	static List<AssertThatBlock> getAssertions(List<DataCheckItems> assertionItemsList) {
		List<AssertThatBlock> list = new ArrayList<>();
		for (DataCheckItems item : assertionItemsList) 
			if(item instanceof AssertThatBlock) list.add((AssertThatBlock)item);
		return list;
	}
	
	static List<GenericScriptBlock> getScriptCalls(List<DataCheckItems> assertionItemsList) {
		List<GenericScriptBlock> list = new ArrayList<>();
		for (DataCheckItems item : assertionItemsList) 
			if(item instanceof GenericScriptBlock) list.add((GenericScriptBlock)item);
		return list;
	}


	static String printAssertions(List<AssertThatBlock> assertList) {
		String mustacheTemplate = """
				asserts=[
				{{#assertionsList}}
				{
					"id":"{{id}}", "type":"{{type}}",
				}
				{{/assertList.get}}
				]
				""";
		MustacheFactory mf = new DefaultMustacheFactory();
	    Mustache mustache = mf.compile(new StringReader(mustacheTemplate),"template");
	    StringWriter sWriter = new StringWriter();
	    try {
			mustache.execute(sWriter, assertList).flush();
		} catch (IOException e) {
			e.printStackTrace();
		}
		System.out.println(sWriter.toString());
		return sWriter.toString();
	}
	
}
