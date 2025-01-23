package nl.asml.matala.bpmn4s.bpmn4s;

public class SetType extends Bpmn4sDataType{
//	FIXME
//	Bpmn4sDataType valueType;
	String valueType;
//	ListType (Bpmn4sDataType vtype) {
	public SetType (String _name, String vtype) {
		super(_name, LIST_TYPE);
		valueType = vtype;
	}
}
