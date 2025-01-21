package nl.asml.matala.bpmn4s.bpmn4s;

public class MapType extends Bpmn4sDataType{
// 	FIXME
//	Bpmn4sDataType keyType;
//	Bpmn4sDataType valueType;
	String name;
	String keyType;
	String valueType;
//	MapType (Bpmn4sDataType ktype, Bpmn4sDataType vtype) {
	public MapType (String _name, String ktype, String vtype) {
		super(_name, MAP_TYPE);
		name = _name;
		keyType = ktype;
		valueType = vtype;
	}
}
