package nl.asml.matala.bpmn4s.bpmn4s;

//import java.util.AbstractMap;
import java.util.ArrayList;
//import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import nl.asml.matala.bpmn4s.Logging;


public class Element {

	class Context {
		String name;
		String dataType;
		String init;
		
		Context(String name, String dataType, String init){
			this.name = name;
			this.dataType = dataType;
			this.init = init;
		}
	}
	
	// Tasks may update context
	String context_update = null;
	
	public void setContextUpdate(String update) {
		context_update = update;
	}
	
	public String getContextUpdate() {
		return context_update;
	}

	// For ASSERT tasks:
	String assertions = null;
	
	public void setAssertions(String assertions) {
		this.assertions = assertions;
	}
	
	public String getAssertions() {
		return this.assertions;
	}
	
	final ElementType type;
	final ElementType subtype;
	
	String name = "";
	String id = "";
	List<Edge> dataInputs = new ArrayList<Edge>();
	List<Edge> dataOutputs = new ArrayList<Edge>();
	List<Edge> flowInputs = new ArrayList<Edge>();
	List<Edge> flowOutputs = new ArrayList<Edge>();	
	String parent = "";
	ArrayList<String> components = new ArrayList<String>();
	String init = "";
	String stepType;
	
	// Component elements have context
	Context context = new Context("", "null", "");
	// Data elements have datatype
	String dataType = null;
	// Task elements have guards
	String guard = null;
	
	/* Id of the original data node this Element refers to. In BPMN4S
	 *  shadow data nodes are created inside subprocess or by using 
	 *  this clone data option. If this is such a shadow node, then 
	 *  originDataNodeId should keep track of the shadowed node id. 
	 *  If the originDataNodeId field is equal to the id field then 
	 *  we consider this node an origin node.
	 */
	String originDataNodeId = null;
	
	public Element(ElementType type) {
		this.type = type;
		this.subtype = ElementType.NONE;
	}
	
	public Element(ElementType type, String name) {
		this.type = type;
		this.subtype = ElementType.NONE;
		this.name = name;
	}
	
	public Element(ElementType type, String name, String id) {
		this.type = type;
		this.subtype = ElementType.NONE;
		this.name = name;
		this.id = id;
	}

	public Element(ElementType type, ElementType subType) {
		this.type = type;
		this.subtype = subType;
	}
	
	public Element(ElementType type, ElementType subType, String name) {
		this.type = type;
		this.subtype = subType;
		this.name = name;
	}
		
	public Element setName(String s) {
		name = s;
		return this;
	}
	
	public String getName() {
		return name;
	}

	public Element setId(String id) {
		this.id = id;
		return this;
	}
	
	public String getOriginDataNodeId() {
		if (this.isReferenceData()) {
			return this.originDataNodeId;
		} else {
			return this.id;
		}
	}
	
	public Element setOriginDataNodeId(String id) {
		this.originDataNodeId = id;
		return this;
	}
	
	public String getId() {
		return this.id;
	}
	
	
	public Element setStepType(String st) {
		stepType = st;
		return this;
	}

	public String getStepType() {
		return stepType;
	}
	
	public ElementType getType() {
		return type;
	}
	
	ElementType getSubType() {
		return subtype;
	}
	
	
	public void setParent (String id) {
		parent = id;
	}
	
	public String getParent () {
		return parent;
	}
	
	public void setComponent (ArrayList<String> cname) {
		components = cname;
	}
	
	public ArrayList<String> getParentComponents () {
		return components;
	}
	
	public void setContext(String name, String dataType, String init) {
		this.context = new Context(name, dataType, init);
	}
	
	public String getContextName() {
		return this.context != null ? this.context.name : null;
	}
	
	public String getContextDataType() {
		return this.context != null ? this.context.dataType : null;
	}
	
	public String getContextInit() {
		return this.context != null ? this.context.init : null;
	}
	
	public Boolean hasFlowSource(String id) {
		for (Edge e: flowInputs) {
			if (e.src.equals(id)) {return true;}
		}
		return false;
	}
	
	public Boolean hasFlowTarget(String id) {
		for (Edge e: flowOutputs) {
			if (e.tar.equals(id)) {return true;}
		}
		return false;
	}
	
	public Boolean hasDataSource(String id) {
		for (Edge e: dataInputs) {
			if (e.src.equals(id)) {return true;}
		}
		return false;
	}
	
	public Boolean hasDataTarget(String id) {
		for (Edge e: dataOutputs) {
			if (e.tar.equals(id)) {return true;}
		}
		return false;
	}
	
	// For data nodes
	
	public void setDataType(String dt) {
		this.dataType = dt;
	}

	public String getDataType() {
		return this.dataType;
	}

	public void addFlowInput (Edge e) {
		this.flowInputs.add(e);
	}
	
	public void addFlowOutput (Edge e) {
		this.flowOutputs.add(e);
	}
	
	public void addDataInput (Edge e) {
		this.dataInputs.add(e);
	}
	
	public void addDataOutput (Edge e) {
		this.dataOutputs.add(e);
	}
	
	
	public void setInit(String init) {
		this.init = init;
	}
	
	public String getInit() {
		return init;
	}
	
	// For action nodes
	
	public int numberOfFlowOutputs() {
		return this.flowOutputs.size();
	}

	public List<Edge> getFlowInputs() {
		return flowInputs;
	}

	public List<Edge> getFlowOutputs() {
		return flowOutputs;
	}

	
	public List<Edge> getDataInputs() {
		return dataInputs;
	}

	public List<Edge> getDataOutputs() {
		return dataOutputs;
	}
	
	public void setGuard(String value) {
		guard = value;
	}
	
	public String getGuard() {
		return this.guard;
	}

	public boolean isReferenceData() {
		return originDataNodeId != id;
	}
	
	@Override
	public String toString() {
		return String.format("Element named %s with id %s and type %s", this.name, this.id, this.type);
	}
	
	
	private static <T> List<T> listConcat(List<T> list1, List<T> list2) {
		return Stream.concat(list1.stream(), list2.stream()).collect(Collectors.toList());
	}
	
	public List<Edge> getAllInputs() {
		return listConcat(flowInputs, dataInputs);
	}
	
	public List<Edge> getAllOutputs() {
		return listConcat(flowOutputs, dataOutputs);
	}
	
}