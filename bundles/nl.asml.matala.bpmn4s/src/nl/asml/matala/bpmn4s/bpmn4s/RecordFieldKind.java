package nl.asml.matala.bpmn4s.bpmn4s;

public enum RecordFieldKind {
	Concrete, Mixed, Symbolic;
	
	public static RecordFieldKind parse(String attribute) {
		return attribute == null ? RecordFieldKind.Concrete : RecordFieldKind.valueOf(attribute);
	}
}
