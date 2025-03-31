package nl.esi.comma.assertthat.generator;

import java.util.ArrayList;
import java.util.List;

public class AssertionsUtils { }

class ScriptCallItem {
	public String id = null;
	public String script_path = null;
	public List<ScriptCallParameter> paramsPositional = new ArrayList<>();
	public List<ScriptCallParameter> paramsNamed = new ArrayList<>();
}

class ScriptCallParameter {
	public String type = "FILE_REF";
	public String name = null;
	public String value = null;
}

abstract class AssertionAbstract {
	public String id = null;
	public String type = null;
	public String output = null;

}

class WithinMargin {
	public String type = null;
	public Double value = null;
}

class AssertThatValueEqualTo extends AssertionAbstract {
	public String referenceValue = null;
	public WithinMargin margin = null;
	public Boolean asRegex = null;
}

//class AssertThatValueCloseTo extends AssertionAbstract {
//	public JsonObject referenceApprox = null;
//	public WithinMargin margin = null;
//}
//
//class AssertThatValueMatchRegex extends AssertionAbstract {
//	public JsonArray referenceRegex = null;
//}

class AssertThatValueHasSize extends AssertionAbstract {
	public Integer referenceSize = null;
}

class AssertThatXPath extends AssertionAbstract {
}

class AssertThatXMLFile extends AssertionAbstract {
}
