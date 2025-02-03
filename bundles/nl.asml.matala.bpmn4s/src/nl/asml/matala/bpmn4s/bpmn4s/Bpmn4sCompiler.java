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
import java.util.Map.Entry;
import java.util.stream.Collectors;

import nl.asml.matala.bpmn4s.Logging;

/*
 * Class to compile a bpmn4s into a pspec (CPN) model.
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
	
	HashSet<String> initialized = new HashSet<String>();
	// Connected XOR gates are collapsed to avoid spurious non-det due to immediately enabled 
	// transitions between them. Here we keep a map from the individual names to the
	// collapsed name in the target CPN.
	AbstractMap<String, String> compiledGateName = new HashMap<String, String>();
			
	public void compile (Bpmn4s model) {
		
		this.model = model;
		String modelname = sanitize(model.getName());
		this.psFileName = modelname + ".ps";
		this.typesFileName = modelname + ".types";
		
		// pspec model
		ps.append("import \"" + this.typesFileName + "\"\r\n"
				+ "specification " + modelname + "\r\n"
				+ "{\r\n");
		
		flattenActivities();
		
		for (Element c: model.elements.values()) {
			if (model.isComponent(c)) {
				if (hasChildComponents(c)){ continue; } // skip top level components
				String component = "";
				String cname = compileComponentName(c) + repr(c);
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
				ps.append(indent(component));	
			}
		}
		
		ps.append(String.format("\tSUT-blocks %s\n", String.join(" ", listSUTcomponents()))); 
		ps.append("\tdepth-limits 300\n}\r\n");
		
		// types
		types.append(generateFabSpecTypes());
	}

	private void flattenActivities() {
		
		// Update edges
		List<Edge> removeEdges = new ArrayList<Edge>();
		for (Edge e: model.edges) {
			while(updateEdge(e)) {}
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
		
		// Remove start and end events of activities. Remove also their related edges and update the ends.
		List<String> removeElements = new ArrayList<String>();
		for (Element el: model.elements.values()) {
			String elId = el.getId();
			String parentId = el.getParent();
			Element parent = model.getElementById(parentId);
			if (model.isActivity(parentId) && model.isStartEvent(elId)) {
				// remove this start event
				removeElements.add(elId);
				// remove its outgoing edge
				Edge outFlow = el.getOutputs().get(0);
				model.edges.remove(outFlow);
				// update the target of the outgoing edge
				Element tar = model.getElementById(outFlow.getTar());
				tar.getInputs().remove(0); // FIXME should remove outFlow here but not working, changed for index 0.
			}
			if(model.isActivity(parentId) &&
					(model.isEndEvent(elId) && !parent.getOutputs().isEmpty())) {
				// remove this end event
				removeElements.add(elId);
				// remove its incoming edge
				Edge inFlow = el.getInputs().get(0);
				model.edges.remove(inFlow);
				// update the source of the removed incoming edge
				Element src = model.getElementById(inFlow.getSrc());
				src.getOutputs().remove(0); // FIXME should remove inFlow here but not working, changed for index 0.
			}
		}
		for(String el: removeElements) {
			model.elements.remove(el);
		}

		// remove activities TODO: update Elements parents.
		model.elements.entrySet().removeIf(e -> model.isActivity(e.getKey()));

//		Logging.logWarning("Elements");
//		for (Element el: model.elements.values()) {
//			Logging.logDebug(repr(el));
//			Logging.logDebug(el.getInputs().toString());
//			Logging.logDebug(el.getOutputs().toString());
//		}
//		Logging.logWarning("Edges");
//		for (Edge e: model.edges) {
//			Logging.logDebug(String.format("Edge %s with src %s and tar %s", e.getId(), e.src, e.tar));
//		}
		
	}
	
	private boolean updateEdge(Edge e) {
		boolean updated = false;
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
		return updated;
	}
	
	
	/* 
	 * Nested components are compiled with their fully qualified name.
	 */
	private String compileComponentName (Element c) {
		return String.join("", c.getComponent().stream()
				.map(e -> repr(e))
				.collect(Collectors.toList()));
	}
	
	/*
	 * Get a list with the names of components that have a RUN task in them.
	 */
	private ArrayList<String> listSUTcomponents () {
		ArrayList<String> result = new ArrayList<String>();
		for (Element elem: model.elements.values()) {
			if (model.isRunTask(elem.getId())) {
				result.add(compileComponentName(elem));
			}
		}
		return result;
	}
	
	// TODO make clear that you need to call repr with a string param to get it actually compiled
	private String fabSpecInputOutput(Element c) {
		String inStr = "inputs\n";
		String outStr = "outputs\n";
		
		for (Edge e: c.getInputs()) {
			Element node = model.elements.get(e.getSrc());
			inStr += node.getDataType() + "\t" + repr(node.getId()) + "\n";
		}
		for (Edge e: c.getOutputs()) {
			Element node = model.elements.get(e.getTar());
			outStr += node.getDataType() + "\t\t" + repr(node.getId()) + "\n";
		}
		if (c.getInputs().isEmpty()) { inStr = "//" + inStr; }
		if (c.getOutputs().isEmpty()) { outStr = "//" + outStr; }
		return inStr + "\n" + outStr;
	}
	

	protected List<String> localsFromStartEvents (Element c) {
		/* 
		 * START_EVENTs introduce a place if followed by a transition in the PN. 
		 * Otherwise we ignore them for optimization for test generation
		 */
		List<String> result = new ArrayList<String>();
		for (Element se: model.elements.values()) {
			if (se.getType().equals(ElementType.START_EVENT) && isParent( c, se)) { 
				Edge edge = se.getOutputs().get(0);
				String tarId = getEdgeTargetId(edge);
				Element tar = model.getElementById(tarId);
				if(tar.getType() == ElementType.TASK || tar.getType() == ElementType.AND_GATE) { 
					String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
					result.add(tabulate(datatype, sanitize(repr(se))));
				}
			}
		}
		return result;
	}
	
	
	protected List<String> localsFromEndEvents (Element c) {
		/* 
		 * END_EVENTs introduce a place if preceded by a transition in the PN. 
		 * Otherwise we ignore them for optimization for test generation
		 */
		List<String> result = new ArrayList<String>();
		for (Element se: model.elements.values()) {
			String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
			if (se.getType().equals(ElementType.END_EVENT) && isParent( c, se)) {
				Edge edge = se.getInputs().get(0);
				Element src = model.getElementById(edge.getSrc());
				if(src.getType() == ElementType.TASK || src.getType() == ElementType.AND_GATE) { 
					result.add(tabulate(datatype, sanitize(repr(se))));
				}
			}
		}
		return result;
	}
	
	private String fabSpecLocal(Element c) {
		String locals = "";
		// All data nodes are places (except for input/outputs)
		for (Element data: model.elements.values()) {
			if (isParent( c, data) 
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
			if (model.isXor(xor.getId()) && isParent( c, xor)) {
				String cGateName = getCompiledGateName(xor.getId()); 
				String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
				if (!visited.contains(cGateName)) {
					visited.add(cGateName);
					locals += tabulate(datatype, sanitize(cGateName)) + "\n";
				}
			}
		}

		// Start Events
		locals += String.join("\n", localsFromStartEvents(c));
		locals += "\n";


		// End Events
		locals += String.join("\n", localsFromEndEvents(c));
		locals += "\n";

		
		/* 
		 * Edges between transitions (tasks and parallel gates) introduce places. 
		 */
		for (Edge e: model.edges) {
			String srcId = e.getSrc();
			String tarId = getEdgeTargetId(e);
			Element src = model.getElementById(srcId);
			Element tar = model.getElementById(tarId);
			if (isParent( c, src)
					&& (model.isAnd(srcId) || model.isTask(srcId))
					&& (model.isAnd(tarId) || model.isTask(tarId))){
				assert isParent( c, tar);
				String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
				String edgeId = getNextValidFlow(e);
				locals += tabulate(datatype, sanitize(namePlaceBetweenTransitions(edgeId, repr(src), repr(tar)))) + "\n";
			}
		}
		if (!locals.isBlank()) {
			locals = "local\n" + locals;
		}
		return locals;
	}	

	/*
	 * Activities are flattened in the compilation to pspec. To avoid spurious non-determinism due to 
	 * immediately enabled transitions, we cleverly choose the initial place for compiled flattened activity.
	 */
	protected String getActivityInitialPlace(String actId) {
		Element activity = model.getElementById(actId);
		Element se = model.getStartEvent(activity);
		Element fe = getNextFlowElement(se);
		String feId = fe.getId();
		if (model.isAnd(feId) || model.isTask(feId)) {
			return repr(se);
		} else if (model.isActivity(feId)) {
			return getActivityInitialPlace(feId);
		} else if (model.isXor(feId)) {
			return repr(fe);
		} else {
			Logging.logError(String.format("Unknown type %s for element %s", fe.getType(), feId));
			return "";
		}
	}
	
	
	protected String getActivityFinalPlace(String actId) {
		Element activity = model.getElementById(actId);
		Element ee = model.getEndEvent(activity);
		Element fe = getPrevFlowElement(ee);
		String feId = fe.getId();
		if (model.isAnd(feId) || model.isTask(feId)) {
			return repr(ee);
		} else if (model.isActivity(feId)) {
			return getActivityFinalPlace(feId);
		} else if (model.isXor(feId)) {
			return repr(fe);
		} else {
			Logging.logError(String.format("Unknown type %s for element %s", fe.getType(), feId));
			return "";
		}
	}
	
	
	private String fabSpecInit(String component) {
		String init = "";
		Element c = model.getElementById(component);
		String ctxName = c.getContextName();
		String ctxDataType = c.getContextDataType();
		String ctxInit = c.getContextInit();
		AbstractList<String> initPlaces = getInitialPlaces(c);
		for (String place: initPlaces) {
			if (ctxDataType == "") {
				init += String.format("%s := %s \n", sanitize(place), UNITINIT);
			}else {
				if (ctxInit == "") {
					Logging.logError(String.format("Missing context initialization for component %s", component));
					// FIXME fail!
				} else {
					init += replace(ctxInit, ctxName, sanitize(place)) + "\n";
				}				
			}
		}
		
		for (Element ds: model.elements.values()) {
			/* Data stores of bottom level components are initialized in such components. 
			 * Other datastores are initialized in components for which they are an input/output.
			 */
			if(ds.getType() == ElementType.DATASTORE  
					&& !initialized.contains(ds.getId())
					&& !ds.isReferenceData()
					&& ((isImmediateParentComponent(component, ds)) || 				
							(c.hasSource(ds.getId()) || c.hasTarget(ds.getId())))) {   
				
				if (ds.getInit() != null && ds.getInit() != "") {
					init += replace(ds.getInit(), ds.getName(), repr(ds.getId())) + "\n";
					initialized.add(ds.getId());
				}
			}
		}
		return init == "" ? "// init\n" : "init\n" + init;
	}
	
	protected AbstractList<String> getInitialPlaces (Element component) {
		/*
		 * Return the places (Element repr) in the target PN that need to be initialized.
		 */
		ArrayList<String> result = new ArrayList<String>();
		Element startEvent = model.getStartEvent(component);
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
					result.add(getCompiledName(e));
				} 
			}else if (next.getType() == ElementType.AND_GATE) {
				for (Edge edge: next.getOutputs()) {
					if (model.isXor(edge.getTar())) {
						result.add(getCompiledName(edge.getTar()));
					} else if (model.isAnd(edge.getTar())) {
						queue.add(model.getElementById(edge.getTar()));
					} else if (model.isTask(edge.getTar())) {
						String tarId = edge.getTar();
						Element tar = model.getElementById(tarId);
						result.add(namePlaceBetweenTransitions(edge.getId(), repr(next), repr(tar)));
					}
				}
			} else {
				Logging.logError("Only AND_GATE and START_EVENT types are meant to be possible here.");
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
	
	private String fabSpecDescription(String component) {
		ArrayList<String> desc = new ArrayList<String>();
		for (Element node: model.elements.values()) {
			if (isParent(component, node)) { 
				ElementType nodeType = node.getType();
				// Tasks and Parallel gates are transitions in the CPN
				if( nodeType == ElementType.TASK  || nodeType == ElementType.AND_GATE ) {			
					String task = "";
					// Name of context as defined by user at front end:
					String compCtxName = model.getElementById(component).getContextName();  
					task += "action\t\t\t" + sanitize(repr(node)) + "\n";
					// STEP TYPE
					String stepConf = "";
					if (model.isComposeTask(node.getId())) {
						stepConf = String.format(" step-type \"%s\" action-type COMPOSE", node.getStepType());
					} else if(model.isRunTask(node.getId())) {
						stepConf = String.format(" step-type \"%s\" action-type RUN", node.getStepType());
					}
					task += "case\t\t\t" + "default" + stepConf + "\n";

					/* Updates and guards from the bpmn4s model come as a string. In these strings, names are used 
					 * as defined by the user in the model. Since for simulation we change this names for ids, we also 
					 * need to do this in the updates strings. Unfortunately, interpreting the update to make a proper
					 * renaming is too much work, so for now we hack it around by doing string replace and hopping
					 * there is no unfortunate name collision.
					 */
					ArrayList<String> replaceIds = getInputOutputIds(node);
					ArrayList<String> replaceFrom = new ArrayList<String>();
					ArrayList<String> replaceTo = new ArrayList<String>();
					// FIXME: We are not considering AND join gates properly. 
					// They have several inputs. How do we check for compatible 
					// context from different inputs to the gate?
					Edge inFlow = node.inputs.get(0);	
					// Name of place that holds source context value for this transition:
					String preCtxName  = sanitize(getPNSourcePlaceName(inFlow));
					replaceFrom.add(0,compCtxName);
					replaceTo.add(preCtxName);
					for(String id: replaceIds) {
						replaceFrom.add(model.getElementById(id).getName());
						replaceTo.add(repr(id));
						Logging.logDebug(replaceFrom.toString());
						Logging.logDebug(replaceTo.toString());
					}
					
					// INPUTS
					ArrayList<String> inputs = new ArrayList<String>();
					for(Edge e: node.getInputs()) {
						inputs.add(sanitize(getPNSourcePlaceName(e)));
					}
					task += "with-inputs\t\t" + String.join(", ", inputs) + "\n";
					// GUARD
					String guard = node.getGuard();
					if (guard != null) {
						task += "with-guard\t\t" + replaceAll(guard, replaceFrom, replaceTo) + "\n";
					}
					for(Edge e: node.getOutputs()) {
						// Name of place that holds target context value for this transition:
						String postCtxName = sanitize(getPNTargetPlaceName(e));
						if (model.isData(e.getTar())) {
							task += "produces-outputs\t" + sanitize(repr(e.getTar()));
							if (isLinked(node.getId(), e.getTar())) {
								task += " assert\n";
							} else if (e.isSuppressed()) {
								task += " suppress\n";
							} else {
								task += "\n";
							}
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replaceAll(e.getRefUpdate(), replaceFrom, replaceTo)) + "\n}\n" ;
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replaceAll(e.getSymUpdate(), replaceFrom, replaceTo)) + "\n}\n";
							}
							if (e.isPersistent()) {
								task += String.format("updates: %s := %s\n",  repr(e.getTar()), repr(e.getTar())) ;
							}
							if (e.getUpdate() != null && e.getUpdate() != "" ) {
								task += "updates:" + indent(replaceAll(e.getUpdate(), replaceFrom, replaceTo)) + "\n";
							}
						} else { // then its context
							task += "produces-outputs\t" + postCtxName + (e.isSuppressed() ? " suppress\n" : "\n");
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replaceAll(e.getRefUpdate(), replaceFrom, replaceTo)) + "\n}\n" ;
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replaceAll(e.getSymUpdate(), replaceFrom, replaceTo)) + "\n}\n";
							}
							// move the context between places in the PN
							task += "updates:" + indent(postCtxName + " := " + preCtxName) + "\n";
							String update = e.getUpdate();
							if(update != null && update != "") {
								// Add users updates
								String[] assignment = update.split(":=");
								update = replace(assignment[0] + ":=" + assignment[1], compCtxName, postCtxName);
								task += indent(replaceAll(update, replaceFrom, replaceTo)) + "\n";
							}
						}
					}
					desc.add(task);
				} 
			}
		}
		
		desc.addAll(getFlowActions(component));
		
		return "desc \"" + repr(component) + "_Model\"\n\n" + String.join("\n", desc);
	}
	
	protected List<String> getFlowActions(String component) {
		/*
		 * In simulation mode, some flows between bpmn4s elements introduce transitions in the CPN. 
		 * Imagine a flow between to XOR gates for instance. In general, if two elements are connected with a flow
		 * and their CPN semantics is a place, then a transition needs to be added. For test generation, we optimize
		 * the model such that this flows do not exist anymore, so that we reduce spurious non-determinism.
		 */
		return new ArrayList<String>();
	}
	
	private ArrayList<String> getInputOutputIds(Element elem) {
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
	
	private String replaceAll(String text, ArrayList<String> from, ArrayList<String> to) {
		for (int idx = 0; idx < from.size(); idx++) {
			// Only replace if match is preceded by a space or new line and its followed by a delimiter.
			text = text.replaceAll(String.format("\\b%s\\b", from.get(idx)), to.get(idx));
		}		
		return text;
	}
	
	private boolean isLinked(String source, String data) {
		/*
		 * Linked data are outputs of RUN tasks which are referenced 
		 * by a COMPOSE task.
		 * Checking if it is referenced is not easy: it requires 
		 * interpreting the expressions inside the references update.
		 * Thus, I will consider them linked if they are, at the same time,
		 * output of a RUN task and input of COMPOSE tasks.
		 */
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
	
	private String getPNSourcePlaceName(Edge e) {
		/*
		 * Assuming the target of e is a Task or an AND gate (which are compiled to transition in the PN)
		 * return the name of the source place in the PN.
		 */
		String srcId = getEdgeSourceId(e);
		if (model.isXor(srcId)) {
			return getCompiledGateName(srcId);
		} else if (model.isTask(srcId) || model.isAnd(srcId)) {
			return namePlaceBetweenTransitions(e.getId(), repr(srcId), repr(e.getTar()));
		} else if (model.isReferenceData(srcId)) {
			Element src = model.getElementById(srcId);
			return repr(src.getOriginDataNodeId());
		} else {
			return repr(srcId);
		}
	}
	
	
	private String getPNTargetPlaceName(Edge e) {
		/*
		 * Assuming the source of e is a Task or an AND gate (which are compiled to transition in the PN)
		 * return the name of the target place in the PN.
		 */
		String tarId = getEdgeTargetId(e);
		if (model.isXor(tarId)) {
			return getCompiledGateName(tarId);
		} else if (model.isTask(tarId) || model.isAnd(tarId)) {
			return namePlaceBetweenTransitions(e.getId(), repr(e.getSrc()), repr(tarId));
		} else if (model.isReferenceData(tarId)) {
			Element tar = model.getElementById(tarId);
			return repr(tar.getOriginDataNodeId());
		} else {
			return repr(tarId);
		}
	}

	public String generateFabSpecTypes() {
		String types = new String("");
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
//				       They are nevertheless kept to be used as fields of 
//					   records in generateRecordField().
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
	
	protected String mapType(String name) {
		/*
		 * Basic types in BPMN4S editor start with upper case, 
		 * while in pspec they are lower cased.
		 */
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
	
	//
	// Helper functions to interpret edges under activity flattening.
	//
	
	protected String getEdgeSourceId(Edge edge) {
		/*
		 * Edges may refer to an activity as their source. Since we flatten activities, 
		 * we return the id of their final flow element fe for which [[fe]] is a place.
		 * They may also refer to an initial event of an activity as their source. In
		 * that case we return the source of the incoming edge to the parent activity. 
		 * Notice that we assume activities belong to a flow that starts at an initial 
		 * event of a component and eventually reaches the activity.
		 */
		String sourceId = edge.getSrc();
		Element source = model.getElementById(sourceId);
		if (model.isActivity(sourceId)) {
			sourceId = getActivityFinalFlowElementId(sourceId);
		} else if (model.isEvent(sourceId) && model.isActivity(source.getParent())) {
			Element parentActivity = model.getElementById(source.getParent()); 
			Edge e = parentActivity.getInputs().get(0);
			return getEdgeSourceId(e);
		}
		return sourceId;
	}
	
	protected String getEdgeTargetId(Edge edge) {
		/*
		 * Edges may refer to an activity as their target. Since we flatten activities, 
		 * we return the id of their first flow element fe for which [[fe]] is a place.
		 * They may also refer to a final event of an activity as their target. In
		 * that case we return the target of the outgoing edge of the parent activity, 
		 * if it exists or the end event of the activity if the activity is the final 
		 * element in the flow.  
		 */
		String targetId = edge.getTar();
		Element target = model.getElementById(targetId);
		if (model.isActivity(targetId)) {
			targetId = getActivityFirstFlowElementId(targetId);
		} else if (model.isEvent(targetId) && model.isActivity(target.getParent())) {
			Element parentActivity = model.getElementById(target.getParent());
			if (!parentActivity.getOutputs().isEmpty()) {
				Edge e = parentActivity.getOutputs().get(0);
				return getEdgeTargetId(e);
			} // else return targetId
		}
		return targetId;
	}
	
	
	private String getActivityFirstFlowElementId(String actId) {
		/*
		 * Since activities are flattened, the initial even is ignored, 
		 * and we pick the next element in the flow.
		 * 
		 * We assume this activity is well formed:
		 * 	- has an initial event
		 *  - has at least one task or sub-activity
		 */
		Element activity = model.getElementById(actId);
		Element se = model.getStartEvent(activity);
		Edge e = se.getOutputs().get(0);
		return getEdgeTargetId(e);
	}
	
	
	private String getActivityFinalFlowElementId(String actId) {
		/*
		 * Since activities are flattened, the final event is ignored, 
		 * and we pick the previous element in its flow. If there is no end event,
		 * we consider there is no final element in the flow and return null.
		 */
		Element activity = model.getElementById(actId);
		Element ee = model.getEndEvent(activity);
		if (ee != null) {
			Edge e = ee.getInputs().get(0);
			return getEdgeSourceId(e);
		}
		return null;
	}

	//
	// END  Helper functions to interpret edges under activity flattening.
	//
	
	protected Boolean isParent(Element parent, Element child) {
		return isParent(parent.getId(), child);
	}
	
	Boolean isParent(String parentId, Element child) {
		return child.getComponent().contains(parentId);
	}
	
	Boolean isImmediateParentComponent(Element parent, Element child) {
		return isImmediateParentComponent(parent.getId(), child);
	}
	
	Boolean isImmediateParentComponent(String parentId, Element child) {
		ArrayList<String> parents = child.getComponent();
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
	
	public void writeToFile (String folder) {
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
	
	protected String sanitize(String str) {
		/*
		 * The BPMN4S editor allows spaces and colons in names, 
		 * but PSpec is more restrictive so we replace them.
		 */
		String result = str.replaceAll("\\p{Zs}+", "").replace(".", "");
		return result;
	}
		

	private String indent(String str) {
		return str.replaceAll("(?m)^", "    ");
	}

	protected String tabulate (String... strings) {
		return String.join("\t", strings);
	}

	private Element getNextFlowElement(Element elem) {
		/* 
		 * For instance to get the first element after a start event
		 */
		String name = elem.outputs.get(0).getTar();
		Element result = model.getElementById(name);
		return result;
	}
	
	private Element getPrevFlowElement(Element elem) {
		/* 
		 * For instance to get the last element before an end event
		 */
		String name = elem.inputs.get(0).getSrc();
		Element result = model.getElementById(name);
		return result;
	}
	
	private String getNextValidFlow(Edge e) {
		/*
		 * When an outgoing edge ends at an activity end event that is not compiled, 
		 * I want to ignore it and get the activity outgoing flow arrow instead.
		 */
		String tarId = e.getTar();
		Element target = model.getElementById(tarId); 
		if (model.isEvent(tarId) && model.isActivity(target.getParent())) {
			Element parent = model.getElementById(target.getParent());
			if (!parent.getOutputs().isEmpty()) {
				return parent.getOutputs().get(0).getId();
			}
		}
		return e.getId();
	}
	

	private String getCompiledName(String elemId) {
		if (model.isXor(elemId)) {
			return getCompiledGateName(elemId);
		} else {
			return repr(elemId); // FIXME check if there are no other cases 
		}
	}
	
	private String getCompiledName(Element elem) {
		return getCompiledName(elem.getId());
	}

	private String repr(String elId) {
		if (model.isReferenceData(elId)) {
			return repr(getOriginDataNode(elId));
		} else if (model.isXor(elId)) {
			return getCompiledGateName(elId);
		}
		return repr(model.getElementById(elId));
	}
	
	protected String repr(Element el) {
		/* 
		 * The name of the element for test generation. 
		 * The id of the element for simulation.
		 */
		return el.getName();
	}
	
	private String getOriginDataNode(String id) {
		Logging.logError(id);
		Element el = model.getElementById(id);
		while(model.isReferenceData(id)) {
			id = el.getOriginDataNodeId();
			el = model.getElementById(id);
		}
		Logging.logError(id);
		return id;
	}
	

	
	
	//
	// XOR gate optimization for Test generation.
	//
	
	/*
	 * Networks of connected XOR gates are merged into single
	 * places in the target PN. This method returns the name
	 * of the target place.
	 */	
	protected String getCompiledGateName(String xorId) {
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
