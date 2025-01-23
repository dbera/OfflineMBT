package nl.asml.matala.bpmn4s.bpmn4s;

import java.util.LinkedHashMap;
import java.util.Map;

public class RecordType extends Bpmn4sDataType {

	public Map<String, String> fields = new LinkedHashMap<String, String>();
	public RecordType (String _name) {
		super(_name, RECORD_TYPE);
	}
	
	public void addField(String _key, String _type) {
		fields.put(_key, _type);
	}
	
}
