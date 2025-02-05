package nl.asml.matala.bpmn4s.bpmn4s;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractList;
import java.util.AbstractMap;
import java.util.AbstractSet;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.stream.Collectors;
import nl.asml.matala.bpmn4s.Logging;


/**
 * Compiles a bpmn4s model into a pspec (CPN).
 * @author
 * @version
 * @since
 */
public class Bpmn4sCompiler{
	
	protected final String UNIT_TYPE = "UNIT";
	private final String UNITINIT = "UNIT{ unit=0 }";

	// The model being compiled to pspec
	protected Bpmn4s model = null;
	
	// The output files names and content
	String psFileName = "default.ps";
	String typesFileName = "default.types";
	StringBuilder ps = new StringBuilder();
	StringBuilder types = new StringBuilder();

	// To avoid double initialization of top level defined data stores.
	HashSet<String> initialized = new HashSet<String>();
	
	/* Connected XOR gates are collapsed to avoid spurious non-det due to immediately enabled 
	 * transitions between them. Here we keep a map from the individual names to the
	 * collapsed name in the target CPN.
	 */
	AbstractMap<String, String> compiledGateName = new HashMap<String, String>();

	/**
	 * Throw when a non valid bpmn4s model is detected.
	 */
	public class InvalidModel extends Exception {

		private static final long serialVersionUID = 1L;

		public InvalidModel (String mssg) {
			super(mssg);
		}
	}
	
	
	/**
	 * Takes a Bpmn4s <model>, flattens its activities, and compiles it into a 
	 * CPN in the language of pspec and accompanying types. The 
	 * resulting CPN and types can be later fetched from variables 
	 * <this.ps> and <this.types>. The resulting PN is meant for test generation.
	 * @throws InvalidModel 
	 */
	public void compile (Bpmn4s model) throws InvalidModel {
		this.model = model;
		String modelname = sanitize(model.getName());
		this.psFileName = modelname + ".ps";
		this.typesFileName = modelname + ".types";

		flattenActivities();
		ps.append(generatePspec());
		types.append(generateTypes());
	}

	/**
	 * Activities and their related Start End events are removed.
	 * Related edges are updated to point to proper elements 
	 * remaining in the model.
	 */
	private void flattenActivities () {
		
		// Update edges
		List<Edge> removeEdges = new ArrayList<Edge>();
		for (Edge e: model.edges) {
			updateEdge(e);
			String srcId = e.getSrc();
			String tarId = e.getTar();
			Element src = model.getElementById(srcId);
			String parentId = src.getParent();
			Element parent = model.getElementById(parentId);
			if(model.isActivity(parentId) && 
					(model.isStartEvent(srcId) || (model.isEndEvent(tarId) && parent.getOutputs().isEmpty()))) {
				removeEdges.add(e);
			}
		}
		for(Edge e: removeEdges) {
			model.edges.remove(e);
		}
		/* Remove start and end events of activities. 
		 * Remove also their related edges and update the ends.
		 */
		List<String> removeElements = new ArrayList<String>();
		for (Element el: model.elements.values()) {
			String elId = el.getId();
			String parentId = el.getParent();
			Element parent = model.getElementById(parentId);
			if (model.isActivity(parentId) && model.isStartEvent(elId)) {
				removeElements.add(elId);
				Edge outFlow = el.getOutputs().get(0);
				model.edges.remove(outFlow);
				Element tar = model.getElementById(outFlow.getTar());
				tar.getInputs().remove(0); // FIXME should remove outFlow here but not working, changed for index 0.
			}
			/*
			 * Only remove end events if the activity has outgoing flow.
			 */
			if(model.isActivity(parentId) &&
					(model.isEndEvent(elId) && !parent.getOutputs().isEmpty())) {
				removeElements.add(elId);
				Edge inFlow = el.getInputs().get(0);
				model.edges.remove(inFlow);
				Element src = model.getElementById(inFlow.getSrc());
				src.getOutputs().remove(0); // FIXME should remove inFlow here but not working, changed for index 0.
			}
		}
		for(String el: removeElements) {
			model.elements.remove(el);
		}
		// remove activities TODO: update Elements parents.
		model.elements.entrySet().removeIf(e -> model.isActivity(e.getKey()));
	}
	
	/**
	 * Edges flowing out or into activities need to be 
	 * redirected to proper elements (since activities are flattened)
	 * @note Activities may have nested activities, thus the while loop.
	 * @param e is the edge to be possibly updated.
	 * @return nothing
	 */
	private void updateEdge (Edge e) {
		boolean updated = true;
		while(updated) {
			updated = false;
			String tarId = e.getTar();
			if(model.isActivity(tarId)) {
				Element target = model.getElementById(tarId);
				Element startEv = model.getStartEvent(target); 
				e.tar = getNextFlowElement(startEv).getId();
				Element newTar = model.getElementById(e.tar);
				newTar.addInput(e);
				updated = true;
			}
			String srcId = e.getSrc();
			if(model.isActivity(srcId)) {
				Element source = model.getElementById(srcId);
				Element endEv = model.getEndEvent(source);
				e.src = getPrevFlowElement(endEv).getId();
				Element newSrc = model.getElementById(e.src);
				newSrc.addOutput(e);
				updated = true;
			}
		}
	}
	
	private String generatePspec() throws InvalidModel {
		StringBuilder result = new StringBuilder();
		result.append("import \"" + this.typesFileName + "\"\n"
				+ "specification " + sanitize(model.getName()) + "\n"
				+ "{\n");
		for (Element c: model.elements.values()) {
			if (model.isComponent(c)) {
				if (hasChildComponents(c)){ continue; } // skip top level components
				String component = "";
				String cname = compile(c.getId());
				component += "system " + sanitize(cname) + "\r\n{\r\n";
				String inOut = fabSpecInputOutput(c);
				String local = fabSpecLocal(c);
				String init = fabSpecInit(c.getId());
				String desc = fabSpecDescription(c.getId()); 
				component += indent(inOut);
				component += "\n";
				component += indent(local);
				component += "\n";
				component += indent(init);
				component += "\n";
				component += indent(desc);
				component += "}\n\n";
				result.append(indent(component));	
			}
		}
		result.append(String.format("\tSUT-blocks %s\n", String.join(" ", listSUTcomponents()))); 
		result.append(String.format("\tdepth-limits %s\n}\r\n", model.getDepthLimit()));
		return result.toString();
	}

	/**
	 * For a system in the pspec, build its input/output section.
	 * @param c is the component that corresponds one to one with a pspec system.
	 * @return a String with the input/output section.
	 */
	private String fabSpecInputOutput(Element c) {
		String inStr = "inputs\n";
		String outStr = "outputs\n";
		
		for (Edge e: c.getInputs()) {
			Element node = model.elements.get(e.getSrc());
			inStr += node.getDataType() + "\t" + compile(node.getId()) + "\n";
		}
		for (Edge e: c.getOutputs()) {
			Element node = model.elements.get(e.getTar());
			outStr += node.getDataType() + "\t\t" + compile(node.getId()) + "\n";
		}
		if (c.getInputs().isEmpty()) { inStr = "//" + inStr; }
		if (c.getOutputs().isEmpty()) { outStr = "//" + outStr; }
		return inStr + "\n" + outStr;
	}

	/**
	 * Build the locals declaration section for a pspec system. FIXME!
	 * @param c is the component that corresponds one to one with a pspec system.
	 * @return the locals section for the system corresponding to c.
	 */
	private String fabSpecLocal(Element c) {
		String locals = "";
		// All data nodes are places (except for input/outputs)
		for (Element data: model.elements.values()) {
			if (isParentComponent(c, data) 
					&& model.isData(data.getId()) 
					&& !data.isReferenceData())
			{
				String t = mapType(data.getDataType());
				locals += tabulate(t, repr(data)) + "\n";
			}
		}
		// XOR gates introduce a place (Maximal Connected Components of XOR gates for optimization)
		AbstractSet<String> visited = new HashSet<String>();
		for (Element xor: model.elements.values()) {
			if (model.isXor(xor.getId()) && isParentComponent( c, xor)) {
				String cGateName = getCompiledXorName(xor.getId()); 
				String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
				if (!visited.contains(cGateName)) {
					visited.add(cGateName);
					locals += tabulate(datatype, sanitize(cGateName)) + "\n";
				}
			}
		}
		// Start Events
		locals += String.join("\n", localsFromStartEvents(c)) + "\n";
		// End Events
		locals += String.join("\n", localsFromEndEvents(c)) + "\n";
		// Edges between transitions (tasks and parallel gates) introduce places. 
		for (Edge e: model.edges) {
			String srcId = e.getSrc();
			String tarId = e.getTar();
			Element src = model.getElementById(srcId);
			Element tar = model.getElementById(tarId);
			if (isParentComponent( c, src)
					&& (model.isAnd(srcId) || model.isTask(srcId))
					&& (model.isAnd(tarId) || model.isTask(tarId))){
				assert isParentComponent( c, tar);
				String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
				locals += tabulate(datatype, sanitize(namePlaceBetweenTransitions(e.getId(), repr(src), repr(tar)))) + "\n";
			}
		}
		if (!locals.isBlank()) {
			locals = "local\n" + locals;
		}
		return locals;
	}
	
	
	/**
	 * START_EVENTs introduce a place if followed by a transition in the target PN. 
	 * Otherwise we ignore them for optimization for test generation.
	 * @param c
	 * @return
	 */
	protected List<String> localsFromStartEvents (Element c) {
		List<String> result = new ArrayList<String>();
		for (Element se: model.elements.values()) {
			if (se.getType().equals(ElementType.START_EVENT) && isParentComponent( c, se)) { 
				Edge edge = se.getOutputs().get(0);
				String tarId = edge.getTar();
				Element tar = model.getElementById(tarId);
				if(tar.getType() == ElementType.TASK || tar.getType() == ElementType.AND_GATE) { 
					String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
					result.add(tabulate(datatype, sanitize(repr(se))));
				}
			}
		}
		return result;
	}
	
	/**
	 * END_EVENTs introduce a place if preceded by a transition in the PN. 
	 * Otherwise we ignore them for optimization of test generation.
	 * @param c
	 * @return
	 */	
	protected List<String> localsFromEndEvents (Element c) {
		List<String> result = new ArrayList<String>();
		for (Element se: model.elements.values()) {
			String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
			if (se.getType().equals(ElementType.END_EVENT) && isParentComponent( c, se)) {
				Edge edge = se.getInputs().get(0);
				Element src = model.getElementById(edge.getSrc());
				if(src.getType() == ElementType.TASK || src.getType() == ElementType.AND_GATE) { 
					result.add(tabulate(datatype, sanitize(repr(se))));
				}
			}
		}
		return result;
	}


	/**
	 * Build the initialization section for the system corresponding to component cId.
	 * @param cId
	 * @return a String with the section
	 * @throws InvalidModel 
	 */
	private String fabSpecInit(String cId) throws InvalidModel {
		String init = "";
		Element c = model.getElementById(cId);
		String ctxName = c.getContextName();
		String ctxDataType = c.getContextDataType();
		String ctxInit = c.getContextInit();
		AbstractList<String> initPlaces = getInitialPlaces(cId);
		for (String place: initPlaces) {
			if (ctxDataType == "") {
				init += String.format("%s := %s \n", sanitize(place), UNITINIT);
			}else {
				if (ctxInit == "") {
					String mssg = String.format("Missing context initialization for component %s", compile(cId));
					throw new InvalidModel(mssg);
				} else {
					init += replace(ctxInit, ctxName, sanitize(place)) + "\n";
				}
			}
		}
		for (Element ds: model.elements.values()) {
			/* Data stores of bottom level components are initialized in such components. 
			 * Other data stores are initialized in components for which they are an input/output.
			 * In the later case, the instance attribute this.initialized is used to avoid 
			 * double initialization. */
			if(ds.getType() == ElementType.DATASTORE  
					&& !initialized.contains(ds.getId())
					&& !ds.isReferenceData()
					&& ((isImmediateParentComponent(cId, ds)) ||
							(c.hasSource(ds.getId()) || c.hasTarget(ds.getId())))) {   
				
				if (ds.getInit() != null && ds.getInit() != "") {
					init += ds.getInit().replace(ds.getName(), compile(ds.getId())) + "\n";
					initialized.add(ds.getId());
				}
			}
		}
		return init == "" ? "// init\n" : "init\n" + init;
	}
	
	/**
	 * Collect the places in the target PN that need to be initialized 
	 * for the system corresponding to component cId. FIXME
	 * @param cId is the id of the component
	 * @return
	 */
	protected AbstractList<String> getInitialPlaces (String cId) {
		Element c = model.getElementById(cId);
		ArrayList<String> result = new ArrayList<String>();
		Element startEvent = model.getStartEvent(c);
		LinkedList<Element> queue = new LinkedList<Element>();
		if (startEvent != null) 
			queue.add(startEvent);
		
		while(!queue.isEmpty()) {
			Element next = queue.pop();
			if (next.getType() == ElementType.START_EVENT) {
				Element e = getNextFlowElement(next);
				if (e.getType() == ElementType.AND_GATE) {
					queue.add(e);
				} else if (e.getType() == ElementType.TASK) {
					result.add(repr(next)); // FIXME need to add start event as a place (what does this mean??? make better comments)
				} else if (e.getType() == ElementType.XOR_GATE) {
					result.add(getCompiledXorName(e.getId()));
				} 
			}else if (next.getType() == ElementType.AND_GATE) {
				for (Edge edge: next.getOutputs()) {
					if (model.isXor(edge.getTar())) {
						result.add(getCompiledXorName(edge.getTar()));
					} else if (model.isAnd(edge.getTar())) {
						queue.add(model.getElementById(edge.getTar()));
					} else if (model.isTask(edge.getTar())) {
						String tarId = edge.getTar();
						Element tar = model.getElementById(tarId);
						result.add(namePlaceBetweenTransitions(edge.getId(), repr(next), repr(tar)));
					}
				}
			} else {
				throw new InternalError(String.format("Got unexpected element type: %s.", next.getType()));
			}
		}
		return result;
	}
	
	private String replace(String text, String from, String to) {
		if (!from.isBlank()) {
			return text.replace(from, to);
		}else {
			return text;
		}
	}
	
	/*
	 * Return a name in the PN for the place that results from 
	 * two subsequent tasks in the original BPMN4S model.
	 */
	protected String namePlaceBetweenTransitions(String  flowId, String src, String dst) {
		return String.format("between_%s_and_%s", src, dst);
	}
	
	
	private String fabSpecDescription(String cId) {
		ArrayList<String> desc = new ArrayList<String>();
		for (Element node: model.elements.values()) {
			if (isParentComponent(cId, node)) { 
				ElementType nodeType = node.getType();
				// Tasks and Parallel gates are transitions in the CPN
				if( nodeType == ElementType.TASK  || nodeType == ElementType.AND_GATE ) {			
					String task = "";
					// Name of context as defined by user at front end:
					String compCtxName = model.getElementById(cId).getContextName();  
					task += "action\t\t\t" + sanitize(repr(node)) + "\n";
					// STEP TYPE
					String stepConf = "";
					if (model.isComposeTask(node.getId())) {
						stepConf = String.format(" step-type \"%s\" action-type COMPOSE", node.getStepType());
					} else if(model.isRunTask(node.getId())) {
						stepConf = String.format(" step-type \"%s\" action-type RUN", node.getStepType());
					}
					task += "case\t\t\t" + "default" + stepConf + "\n";

					/*
					 * Updates, guards and initializations from the bpmn4s model reach us as Strings. 
					 * In these strings, names are used as defined by the user in the model. 
					 * Since for simulation we change this names for ids, we also 
					 * need to do this in the updates strings. Also, both for simulation and test generation, updates 
					 * and guards related to context variables need to be renamed since we hold the context in 
					 * different places through the PN. Unfortunately, interpreting the update to make a proper
					 * renaming is too much work, so for now we hack it around by doing string replace and hopping
					 * there is no unfortunate name collision.
					 */
					Map<String, String> replaceMap = buildReplaceMap(node);
					/* FIXME: We are not considering AND join gates properly. 
					 * They have several inputs. How do we check for compatible 
					 * context from different inputs to the gate?
					 */
					Edge inFlow = node.inputs.get(0);
					// Name of place that holds source context value for this transition:
					String preCtxName = sanitize(getPNSourcePlaceName(inFlow));
					replaceMap.put(compCtxName, preCtxName);
					
					// INPUTS
					ArrayList<String> inputs = new ArrayList<String>();
					for(Edge e: node.getInputs()) {
						inputs.add(sanitize(getPNSourcePlaceName(e)));
					}
					task += "with-inputs\t\t" + String.join(", ", inputs) + "\n";
					// GUARD
					String guard = node.getGuard();
					if (guard != null) {
						task += "with-guard\t\t" + replaceAll(guard, replaceMap) + "\n";
					}
					for(Edge e: node.getOutputs()) {
						// Name of place that holds target context value for this transition:
						String postCtxName = sanitize(getPNTargetPlaceName(e));
						if (model.isData(e.getTar())) {
							task += "produces-outputs\t" + sanitize(compile(e.getTar()));
							if (isLinked(node.getId(), e.getTar())) {
								task += " assert\n";
							} else if (e.isSuppressed()) {
								task += " suppress\n";
							} else {
								task += "\n";
							}
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replaceAll(e.getRefUpdate(), replaceMap)) + "\n}\n" ;
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replaceAll(e.getSymUpdate(), replaceMap)) + "\n}\n";
							}
							if (e.isPersistent()) {
								task += String.format("updates: %s := %s\n",  compile(e.getTar()), compile(e.getTar())) ;
							}
							if (e.getUpdate() != null && e.getUpdate() != "" ) {
								task += "updates:" + indent(replaceAll(e.getUpdate(), replaceMap)) + "\n";
							}
						} else { // then its context
							task += "produces-outputs\t" + postCtxName + (e.isSuppressed() ? " suppress\n" : "\n");
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replaceAll(e.getRefUpdate(), replaceMap)) + "\n}\n" ;
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replaceAll(e.getSymUpdate(), replaceMap)) + "\n}\n";
							}
							// move the context between places in the PN.
							task += "updates:" + indent(postCtxName + " := " + preCtxName) + "\n";
							String update = e.getUpdate();
							if(update != null && update != "") {
								// Add users updates. Notice that postCtxName holds the value of preCtxName here.
								update = update.replaceAll(String.format("\\b%s\\b", compCtxName), postCtxName);
								task += indent(replaceAll(update, replaceMap)) + "\n";
							}
						}
					}
					desc.add(task);
				} 
			}
		}
		
		desc.addAll(getFlowActions(cId));
		
		return "desc \"" + compile(cId) + "_Model\"\n\n" + String.join("\n", desc);
	}

	/**
	 * Collect the compiled name for each input/output node corresponding to a 
	 * transition (TASK or AND gate in the Bpmn4s).
	 * @param transition
	 * @return a Map from the nodes name to their compiled name.
	 */
	protected Map<String, String> buildReplaceMap (Element transition) {
		Map<String, String> replaceMap = new HashMap<String, String>();
		return replaceMap;
	}
	
	/**
	 * In simulation mode, some flows between bpmn4s elements introduce transitions in the CPN. 
	 * Imagine a flow between to XOR gates for instance. In general, if two elements are connected with a flow
	 * and their CPN semantics is a place, then a transition needs to be added. For test generation, we optimize
	 * the model such that this flows do not exist anymore, so that we reduce spurious non-determinism.
	 */
	protected List<String> getFlowActions(String component) {
		return new ArrayList<String>();
	}
	
	protected ArrayList<String> getInputOutputIds(Element elem) {
		ArrayList<String> result = new ArrayList<String>();
		for (Edge e: elem.getInputs()) {
			if(isAPlace(e.getSrc())) {
				result.add(e.getSrc());
			}
		}
		for (Edge e: elem.getOutputs()) {
			if(isAPlace(e.getTar())) {
				result.add(e.getTar());
			}
		}
		return result;
	}
	
	
	/**
	 * Fetch the names of components that poses a RUN task.
	 * @return List with components names
	 */
	private ArrayList<String> listSUTcomponents () {
		ArrayList<String> result = new ArrayList<String>();
		for (Element elem: model.elements.values()) {
			if (model.isRunTask(elem.getId())) {
				result.add(compile(elem.getParentComponents().getLast()));
			}
		}
		return result;
	}
	
	/**
	 * 
	 * @param text
	 * @param replace
	 * @return
	 */
	private String replaceAll(String text, Map<String,String> replace) {
		for (String k: replace.keySet()) {
			// Only replace if match is surrounded by delimiters.
			text = text.replaceAll(String.format("\\b%s\\b", k), replace.get(k));
		}		
		return text;
	}
	
	/**
	 * Linked data are outputs of RUN tasks which are referenced 
	 * by a COMPOSE task.
	 * Checking if it is referenced is not easy: it requires 
	 * interpreting the expressions inside the references update.
	 * Thus, I will consider them linked if they are, at the same time,
	 * output of a RUN task and input of COMPOSE tasks.
	 */
	private boolean isLinked(String source, String data) {

		Element d = model.getElementById(data);
		String originDataId = d.getOriginDataNodeId(); 
		if(model.isRunTask(source)) {
			for(Element elem: model.elements.values()) {
				if (model.isComposeTask(elem.getId())) {
					for (Edge e: elem.getInputs()) {
						Element src = model.getElementById(e.getSrc());
						if (originDataId.equals(src.getOriginDataNodeId())) {
							return true;
						}
					}
				}
			}
		}
		return false;
	}
	
	/**
	 * Assuming the target of e is a Task or an AND gate (which are compiled to transition in the PN)
	 * return the name of the source place in the PN.
	 */
	private String getPNSourcePlaceName(Edge e) {
		String srcId = e.getSrc();
		if (model.isXor(srcId)) {
			return getCompiledXorName(srcId);
		} else if (model.isTask(srcId) || model.isAnd(srcId)) {
			return namePlaceBetweenTransitions(e.getId(), compile(srcId), compile(e.getTar()));
		} else if (model.isReferenceData(srcId)) {
			Element src = model.getElementById(srcId);
			return compile(src.getOriginDataNodeId());
		} else {
			return compile(srcId);
		}
	}
	
	/**
	 * Assuming the source of e is a Task or an AND gate (which are compiled to transition in the PN)
	 * return the name of the target place in the PN.
	 */
	private String getPNTargetPlaceName(Edge e) {
		String tarId = e.getTar();
		if (model.isXor(tarId)) {
			return getCompiledXorName(tarId);
		} else if (model.isTask(tarId) || model.isAnd(tarId)) {
			return namePlaceBetweenTransitions(e.getId(), compile(e.getSrc()), compile(tarId));
		} else if (model.isReferenceData(tarId)) {
			Element tar = model.getElementById(tarId);
			return compile(tar.getOriginDataNodeId());
		} else {
			return compile(tarId);
		}
	}

	public String generateTypes() {
		String types = new String("");
		// UNIT_TYPE is the type for undefined contexts.
		types += String.format("record %s {\n\tint\tunit\n}\n\n", UNIT_TYPE);
		for (Bpmn4sDataType d: model.dataSchema.values()) {
			if(d instanceof RecordType) {
				RecordType rec = RecordType.class.cast(d);
				String type = "record " + rec.getName() + " {\n";
				String parameters = "";
				for (Entry<String, String> e: rec.fields.entrySet()) {
					parameters += generateRecordField(e);
				}
				type += indent(parameters) + "}\n";
				types += type + "\n";
			} else if(d instanceof EnumerationType) {
				EnumerationType enumeration = EnumerationType.class.cast(d);
				String literals = "";
				for (String lit :enumeration.literals.keySet()) {
					literals += " " + lit;
				}
				String type = String.format("enum %s {%s }\n", enumeration.name, literals);
				types += type + "\n";
			} else {
//				NOTE:  I am not compiling data types that are not records or enumerations.
//				       Other types are used for fields of records in generateRecordField().
			}
		}
		return types;
	}
	
	private String generateRecordField(Entry<String, String> e) {
		String field = "";
		String fieldName = e.getKey();
		String fieldTypeName = e.getValue();
		Bpmn4sDataType dataType = model.dataSchema.get(fieldTypeName); 
		if (dataType instanceof ListType) {
			ListType lst = ListType.class.cast(dataType);
			field = String.format("%s[]\t%s\n" , mapType(lst.valueType), fieldName); 
		} else if (dataType instanceof MapType) {
			MapType mp = MapType.class.cast(dataType);
			field = String.format("map<%s,%s>\t%s\n" , mapType(mp.keyType), mapType(mp.valueType), fieldName);
		} else if (dataType instanceof SetType) {
			SetType st = SetType.class.cast(dataType);
			field = String.format("set<%s>\t%s\n" , mapType(st.valueType), fieldName);
		} else {
			// record, enumerations and basic types go here
			field = String.format("%s\t%s\n" , mapType(fieldTypeName), fieldName); 
		}
		return field;
	}

	/**
	 * Basic types in BPMN4S editor start with upper case, 
	 * while in pspec they are lower cased.
	 */
	protected String mapType(String name) {
		String result = name;
		if (name.equals("Int") || name.equals("String")) {
			result = name.toLowerCase();
		} else if (name.equals("Boolean")) {
			result = "bool";
		}
		return result;
		
	}

	//
	// Helper functions
	//
	
	protected Boolean isAPlace (String id) {
		Element elem = model.getElementById(id);
		if (elem != null) {
			ElementType t = elem.getType();
			return t == ElementType.DATASTORE 
					|| t == ElementType.MSGQUEUE 
					|| t == ElementType.XOR_GATE 
					|| t == ElementType.START_EVENT 
					|| t == ElementType.END_EVENT;
		} else {
			Logging.logWarning("No element with id " + id);
			return false;
		}
	}
	
	protected Boolean isParentComponent(Element parent, Element child) {
		return isParentComponent(parent.getId(), child);
	}
	
	Boolean isParentComponent(String parentId, Element child) {
		return child.getParentComponents().contains(parentId);
	}
	
	Boolean isImmediateParentComponent(Element parent, Element child) {
		return isImmediateParentComponent(parent.getId(), child);
	}
	
	Boolean isImmediateParentComponent(String parentId, Element child) {
		ArrayList<String> parents = child.getParentComponents();
		return !parents.isEmpty() && parents.get(parents.size()-1).equals(parentId);
	}
	
	Boolean hasChildComponents(Element c) {
		for (Element node: model.elements.values()) {
			if (node.getType() == ElementType.COMPONENT && 
					node.parent != null &&
					node.parent.equals(c.getId())) 
			{
				return true;
			}
		}
		return false;
	}
	
	public void writeModelToFiles (String folder) {
		this.writeToFile(Paths.get(folder, psFileName), ps.toString());
		this.writeToFile(Paths.get(folder, typesFileName), types.toString());
	}
	
	void writeToFile (Path filename, String text) {
		File file = filename.toFile();
	    FileWriter writer = null;
	    try {
	        writer = new FileWriter(file);
	        writer.write(text);
	    } catch (IOException e) {
	        e.printStackTrace();
	    } finally {
	        if (writer != null) try { writer.close(); } catch (IOException ignore) {}
	    }
	    Logging.logInfo(String.format("File %s generated at %s", filename, file.getAbsolutePath()));
	}

	/**
	 * The BPMN4S editor allows spaces and colons in names, 
	 * but PSpec is more restrictive so we replace them.
	 */
	protected String sanitize(String str) {
		String result = str.replaceAll("\\p{Zs}+", "").replace(".", "");
		return result;
	}

	private String indent(String str) {
		return str.replaceAll("(?m)^", "    ");
	}

	protected String tabulate (String... strings) {
		return String.join("\t", strings);
	}

	/**
	 * 
	 * @param elem
	 * @return
	 */
	private Element getNextFlowElement(Element elem) {
		String name = elem.outputs.get(0).getTar();
		Element result = model.getElementById(name);
		return result;
	}
	
	/**
	 * 
	 * @param elem
	 * @return
	 */
	private Element getPrevFlowElement(Element elem) {
		String name = elem.inputs.get(0).getSrc();
		Element result = model.getElementById(name);
		return result;
	}

	/**
 	 * Get the compiled name for Element <el>.
	 */
	protected String compile(String elId) {
		Element el = model.getElementById(elId);
		if (model.isReferenceData(elId)) {
			return compile(getOriginDataNode(elId));
		} else if (model.isXor(elId)) {
			return getCompiledXorName(elId);
		} else if (model.isComponent(elId)) { 
			/* Nested components are compiled with their fully qualified name. */
			return String.join("", el.getParentComponents().stream()
					.map(e -> repr(model.getElementById(e)))
					.collect(Collectors.toList())) + repr(el);
		}
		return repr(model.getElementById(elId));
	}
	
	/**
	 * Get the identifier of a bpmn4s Element <el>
	 * While the compiler for test generation (this) returns the name of the element,
	 * the compiler for simulation will return the element's id.
	 */
	protected String repr(Element el) {
		return el.getName();
	}
	
	private String getOriginDataNode(String id) {
		Element el = model.getElementById(id);
		while(model.isReferenceData(id)) {
			id = el.getOriginDataNodeId();
			el = model.getElementById(id);
		}
		return id;
	}
	
	//
	// XOR gate optimization for Test generation.
	//
	
	/*
	 * For test generation, networks of connected XOR gates are merged 
	 * into single places in the target PN. This method returns the name
	 * of the target place.
	 */	
	protected String getCompiledXorName(String xorId) {
		Element xor = model.getElementById(xorId);
		String result = compiledGateName.get(xor.getId());
		if(result == null) {
			AbstractSet<String> net = new HashSet<String>();
			buildXorNet(xor, net);
			if (net.size() > 1) {
				result = "merged";
				for(String name: net) {
					result += "_" + name;
				}	
			}else {
				result = xor.getName();
			}
			for(String name: net) {
				compiledGateName.put(name, result);
			}
		}
		return result;
	}
	
	/*
	 * Build the Maximal Connected Component of xor gates that contains <xor> and 
	 * add its elements to <net>. Notice that <net> is used as an accumulator for
	 * the recursive algorithm.
	 */
	private void buildXorNet(Element xor, AbstractSet<String> net) {
		net.add(repr(xor));
		for(Edge input: xor.getInputs()) {
			String srcId = input.getSrc();
			if(model.isXor(srcId)) {
				if(!net.contains(repr(model.getElementById(srcId)))) {
					buildXorNet(model.getElementById(srcId), net);
				}
			}
		}
		for(Edge output: xor.getOutputs()) {
			String tarId = output.getTar();
			if(model.isXor(tarId)) {
				if(!net.contains(repr(model.getElementById(tarId)))) {
					buildXorNet(model.getElementById(tarId), net);
				}
			}
		}
	}
	
	//
	// END XOR gate optimization for Test generation.
	//
}
