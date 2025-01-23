package nl.asml.matala.bpmn4s.bpmn4s;

public class ListType extends Bpmn4sDataType{
	
	String valueType;

	public ListType (String _name, String vtype) {
		super(_name, LIST_TYPE);
		valueType = vtype;
	}
}
