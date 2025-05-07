package nl.asml.matala.bpmn4s.bpmn4s;

import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class RecordType extends Bpmn4sDataType {

	public Map<String, String> fields = new LinkedHashMap<String, String>();
	private Set<String> suppressedFields = new HashSet<String>();

	public RecordType (String _name) {
		super(_name, RECORD_TYPE);
	}

	public void addField(String _key, String _type, boolean _suppress) {
		fields.put(_key, _type);
		if (_suppress) {
			suppressedFields.add(_key);
		}
	}

	public boolean isSuppressed(String _field) {
		return suppressedFields.contains(_field);
	}
}