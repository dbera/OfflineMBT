package nl.asml.matala.bpmn4s.bpmn4s;

public class Edge extends Element {
	
	String update;
	String src;
	String tar;	
	String ref_update;
	String sym_update;
	boolean suppress;
	boolean persistent;

	
	public Edge(String _src, String _expr, String refup, String symup, String _tar) {
		super(ElementType.EDGE);
		this.src = _src;
		this.tar = _tar;
		this.update = _expr;
		this.ref_update = refup;
		this.sym_update = symup;
		this.suppress = false;
		this.persistent = false;
	}
	
	
	@Override
	public String toString() {
		return String.format("An Edge with source %s, expression %s and target %s.", src, update, tar);
	}
	
	public String getSrc() {
		return src;
	}
	
	public String getTar() {
		return tar;
	}
	
	public void setUpdate(String text) {
		update = text;
	}
	
	public String getUpdate() {
		return update;
	}

	public String getRefUpdate() {
		return ref_update;
	}

	public String getSymUpdate() {
		return sym_update;
	}

	public Edge makePersistent() {
		this.persistent = true;
		return this;
	}
	
	public boolean isPersistent() {
		return this.persistent;
	}
	
	public Edge makeSupressed() {
		this.suppress = true;
		return this;
	}
	
	public boolean isSuppressed() {
		return suppress;
	}
	
}