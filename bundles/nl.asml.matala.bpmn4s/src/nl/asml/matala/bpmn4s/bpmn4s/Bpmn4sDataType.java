package nl.asml.matala.bpmn4s.bpmn4s;

public class Bpmn4sDataType {
	
	static final String RECORD_TYPE = "record";
	static final String MAP_TYPE = "map";
	static final String LIST_TYPE = "list";
	static final String ENUM_TYPE = "enum";
	static final String BOOL_TYPE = "boolean";
	static final String INT_TYPE = "int";
	static final String STRING_TYPE = "string";
	static final String FLOAT_TYPE = "float";
	static final String NO_TYPE = "notype";
	
	String name = new String();
	String type = new String();
	
	public Bpmn4sDataType(String _name, String _type) {
		name = _name;
		type = _type;
	}
	
	public Bpmn4sDataType(String _type) {
		type = _type;
	}
	
	public Bpmn4sDataType() {
		type = NO_TYPE;
	}
	
	public void setName(String _name) {
		name = _name;
	}
	
	public String getName() {
		return name;
	}
	
	public void setType(String t) {
		type = t;
	}
	
	public String getType() {
		return type;
	}

}
