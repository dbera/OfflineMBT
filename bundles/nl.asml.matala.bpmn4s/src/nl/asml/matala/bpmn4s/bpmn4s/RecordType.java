package nl.asml.matala.bpmn4s.bpmn4s;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;

public class RecordType extends Bpmn4sDataType {

	public Map<String, Bpmn4sDataType> fields = new LinkedHashMap<String, Bpmn4sDataType>();
	public RecordType (String _name) {
		super(_name, RECORD_TYPE);
	}
	
	public void addField(String _key, Bpmn4sDataType _type) {
		fields.put(_key, _type);
	}
	
	@Override
	public String getDefaultInit() {
		Entry<String, Bpmn4sDataType> entry = fields.entrySet().iterator().next();
		return this.getName() + " {" + entry.getKey() + " = " + entry.getValue().getDefaultInit() + "}";
	}
}
