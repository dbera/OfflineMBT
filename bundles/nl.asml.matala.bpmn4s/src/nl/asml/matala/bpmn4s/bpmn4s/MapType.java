package nl.asml.matala.bpmn4s.bpmn4s;

public class MapType extends Bpmn4sDataType{
	String name;
	String keyType;
	String valueType;
	public MapType (String _name, String ktype, String vtype) {
		super(_name, MAP_TYPE);
		name = _name;
		keyType = ktype;
		valueType = vtype;
	}
}
