package nl.asml.matala.bpmn4s.bpmn4s;

import java.util.LinkedHashMap;
import java.util.Map;

public class EnumerationType extends Bpmn4sDataType {

	public Map<String, String> literals = new LinkedHashMap<String, String>();
	
	public EnumerationType (String name) {
		super(name, ENUM_TYPE);
	}
	
	public void addLiteral(String name, String value) {
		literals.put(name, value);
	}
}
