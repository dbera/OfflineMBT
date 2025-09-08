package nl.asml.matala.bpmn4s.bpmn4s;

public class RecordField {
	private final String name;
	private final String type;
	private final RecordFieldKind kind;
	private final boolean suppressed;

	public RecordField(String name, String type, RecordFieldKind kind, boolean suppressed) {
		this.name = name;
		this.type = type;
		this.kind = kind;
		this.suppressed = suppressed;
	}

	public String getName() {
		return name;
	}

	public String getType() {
		return type;
	}

	public RecordFieldKind getKind() {
		return kind;
	}

	public boolean isSuppressed() {
		return suppressed;
	}
}
