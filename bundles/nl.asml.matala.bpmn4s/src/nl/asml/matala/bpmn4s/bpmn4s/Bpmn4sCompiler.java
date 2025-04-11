package nl.asml.matala.bpmn4s.bpmn4s;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractMap;
import java.util.AbstractSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
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
	private final String UNIT_INIT = "UNIT { __uuid__ = uuid(), unit = 0 }";

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
	 * transitions between them. Here we keep a map from the individual ids to the
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
	 * Activities and their related Start/End events are removed.
	 * Related edges are updated to point to proper elements 
	 * remaining in the model.
	 */
	private void flattenActivities () throws InvalidModel {
		
		/*
		 * Every flow edge in the model that points to or comes from 
		 * an activity should be re-routed to a proper element. Data edges
		 * to and from activities should be removed.
		 */
		List<Edge> removeDataEdges = new ArrayList<Edge>(); 
		for (Edge e: model.edges) {
			if(e.isFlowEdge()) {
				updateEdge(e);
			}
			if(e.isDataEdge()) {
				String srcId = e.getSrc();
				String tarId = e.getTar();
				Element src = model.getElementById(srcId);
				Element tar = model.getElementById(tarId);
				if(model.isActivity(srcId) || model.isActivity(tarId)) {
				src.dataOutputs.remove(e);
				tar.dataInputs.remove(e);
				removeDataEdges.add(e);
				}
			}
		}
		for(Edge e : removeDataEdges) {
			model.edges.remove(e);
		}
		/* Remove activities. Also remove their start and end events 
		 * along with their related edges.
		 */
		List<String> removeElements = new ArrayList<String>();
		for (Element el: model.elements.values()) {
			String elId = el.getId();
			String parentId = el.getParent();
			Element parent = model.getElementById(parentId);
			if (model.isActivity(parentId) && model.isStartEvent(elId)) {
				removeElements.add(elId);
				Edge outFlow = el.getFlowOutputs().get(0);
				model.edges.remove(outFlow);
				Element tar = model.getElementById(outFlow.getTar());
				tar.getFlowInputs().remove(outFlow);
			}
			/*
			 * Only remove end events if the activity has outgoing flow.
			 */
			if(model.isActivity(parentId) &&
					(model.isEndEvent(elId) && !parent.getFlowOutputs().isEmpty())) {
				removeElements.add(elId);
				Edge inFlow = el.getFlowInputs().get(0);
				model.edges.remove(inFlow);
				Element src = model.getElementById(inFlow.getSrc());
				src.getFlowOutputs().remove(inFlow);
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
	 * @throws InvalidModel 
	 * @assumes activities have a start and an end event.
	 */
	private void updateEdge (Edge e) throws InvalidModel {
		boolean updated = true;
		while(updated) {
			updated = false;
			String tarId = e.getTar();
			if(model.isActivity(tarId)) {
				Element target = model.getElementById(tarId);
				Element startEv = model.getStartEvent(target);
				if(startEv == null) {
					throw new InvalidModel("Missing start event for activity " + model.getElementById(tarId).getName());
				}
				// update the target of the edge
				e.tar = getNextFlowElement(startEv).getId();
				Element newTar = model.getElementById(e.tar);
				// add the edge as an input of the new target 
				newTar.addFlowInput(e);
				updated = true;
			}
			String srcId = e.getSrc();
			if(model.isActivity(srcId)) {
				Element source = model.getElementById(srcId);
				Element endEv = model.getEndEvent(source);
				if(endEv == null) {
					throw new InvalidModel("Missing end event for activity " + model.getElementById(srcId).getName());
				}
				e.src = getPrevFlowElement(endEv).getId();
				Element newSrc = model.getElementById(e.src);
				newSrc.addFlowOutput(e);
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
				List<String> sutConfVars = fabSpecSutConfs(c.getId());
				String sutConfs = sutConfVars.isEmpty() ? "" : "sut-var: " + String.join(" ", sutConfVars) + "\n"; 
				String desc = fabSpecDescription(c.getId()); 
				component += indent(inOut);
				component += "\n";
				component += indent(local);
				component += "\n";
				component += indent(init);
				component += "\n";
				component += indent(sutConfs);
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
	
	private List<String> fabSpecSutConfs(String cid) {
		List<String> result = new ArrayList<String>();
		for(Edge e: model.edges) {
			Element src = model.getElementById(e.getSrc());
			Element tar = model.getElementById(e.getTar());
			if((tar.subtype == ElementType.RUN_TASK || 
				tar.subtype == ElementType.COMPOSE_TASK) && 
					tar.getParentComponents().contains(cid)) {
				if(src.isSutConfigurations()) {
					result.add(repr(src));
				}
			}
		}
		return result;
	}

	/**
	 * For a system in the pspec, build its input/output section.
	 * @param c is the component that corresponds one to one with a pspec system.
	 * @return a String with the input/output section.
	 */
	private String fabSpecInputOutput(Element c) {
		String inStr = "inputs\n";
		String outStr = "outputs\n";
		
		for (Edge e: c.getDataInputs()) {
			Element node = model.elements.get(e.getSrc());
			inStr += node.getDataType() + "\t" + compile(node.getId()) + "\n";
		}
		for (Edge e: c.getDataOutputs()) {
			Element node = model.elements.get(e.getTar());
			outStr += node.getDataType() + "\t\t" + compile(node.getId()) + "\n";
		}
		if (c.getDataInputs().isEmpty()) { inStr = "//" + inStr; }
		if (c.getDataOutputs().isEmpty()) { outStr = "//" + outStr; }
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
	 * Otherwise we ignore them as optimization.
	 * @param c
	 * @return
	 */
	protected List<String> localsFromStartEvents (Element c) {
		List<String> result = new ArrayList<String>();
		for (Element se: model.elements.values()) {
			if (se.getType().equals(ElementType.START_EVENT) && isParentComponent( c, se)) { 
				Edge edge = se.getFlowOutputs().get(0);
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
	 * Otherwise we ignore them as optimization.
	 * @param c
	 * @return
	 */	
	protected List<String> localsFromEndEvents (Element c) {
		List<String> result = new ArrayList<String>();
		for (Element ee: model.elements.values()) {
			String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
			if (ee.getType().equals(ElementType.END_EVENT) && isParentComponent( c, ee)) {
				Edge edge = getOrDefault(ee.getFlowInputs(), 0, null);
				if (edge != null) {
					Element src = model.getElementById(edge.getSrc());
					if(src.getType() == ElementType.TASK || src.getType() == ElementType.AND_GATE) { 
						result.add(tabulate(datatype, sanitize(repr(ee))));
					}
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
	private String fabSpecInit(String cId) {
		String init = "";
		Element c = model.getElementById(cId);
		
		// Initialize context for this component
		String ctxName = c.getContextName();
		String ctxDataType = c.getContextDataType();
		String ctxInit = c.getContextInit();
		String initPlace = getInitialPlace(cId);

		if (initPlace != null) {
			if (ctxDataType == "") {
				init += String.format("%s := %s \n", sanitize(initPlace), UNIT_INIT);
			} else {
				if (ctxInit != "") {
					init += replaceWord(ctxInit, ctxName, sanitize(initPlace)) + "\n";
				}
			}
		}
		
		// Add data store inputs that have not been initialized somewhere else
		for (Edge e: c.getDataInputs()) {
			Element node = model.elements.get(e.getSrc());
			
			if (node.getType() == ElementType.DATASTORE  && !initialized.contains(node.getOriginDataNodeId())) {
				initialized.add(node.getOriginDataNodeId());
				String s = node.getInit();
				if (node.isReferenceData()) {
					s = model.getElementById(node.getOriginDataNodeId()).getInit();
				}
				if (s != null && s != "") {
					init += s.replace(node.getName(), compile(node.getId())) + "\n";
				}
			}
		}
				
		// add locally declared data stores initializations
		for (Element ds: model.elements.values()) {
			if(ds.getType() == ElementType.DATASTORE  
				&& !ds.isReferenceData()
				&& isImmediateParentComponent(cId, ds)) {
				if (ds.getInit() != null && ds.getInit() != "") {
					init += ds.getInit().replace(ds.getName(), compile(ds.getId())) + "\n";
				}
			}
		}
		
		return init == "" ? "// init\n" : "init\n" + init;
	}
	
	/**
	 * To avoid spurious non-determinism from immediately enabled transitions between start events and XOR gates,
	 * we initialize the XOR gate place and not the start event place.
	 * @param cId is the id of the component.
	 * @return null if cId has no initial place. Otherwise, the compiled name of the initial event of cId if 
	 * it is not followed by an XOR gate. Otherwise, the compiled name of the following XOR gate.
	 */
	protected String getInitialPlace (String cId) {
		Element c = model.getElementById(cId);
		String result = null;
		Element startEvent = model.getStartEvent(c);
		if (startEvent != null) {
			Element e = getNextFlowElement(startEvent);
			if (model.isXor(e.getId())) {
				result = compile(e.getId());
			} else {
				result = repr(startEvent);
			}
		}
		return result;
	}
		
	
	/**
	 * Replace whole word only (only match <from> if surrounded by delimiters)
	 * @param text
	 * @param from
	 * @param to
	 * @return
	 */
	private String replaceWord (String text, String from, String to) {
		return text.replaceAll(String.format("\\b%s\\b", from), to);
	}
	
	/**
	 * Return a name in the PN for the place that results from 
	 * two subsequent tasks in the original BPMN4S model.
	 */
	protected String namePlaceBetweenTransitions(String  flowId, String src, String dst) {
		return String.format("between_%s_and_%s", src, dst);
	}
	
	public static <E> E getOrDefault(List<E> list, int index, E defaultValue) {
	      if (index < 0) {
	          throw new IllegalArgumentException("index is less than 0: " + index);
	      }
	      return index <= list.size() - 1 ? list.get(index) : defaultValue;
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
					 * Updates, guards, and initializations from the bpmn4s are parsed into Strings. 
					 * In these strings, data stores, queues, and context are identified by their user-defined names.
					 * Since for simulation we change this names for ids, we also need to do this in the updates 
					 * strings. Also, both for simulation and test generation, updates and guards related to context 
					 * variables need to be renamed since we hold the context in different places through the PN. 
					 * FIXME: Unfortunately, interpreting the update to make a proper renaming is too much work, so for now 
					 * we hack it around by doing string replace and hopping there is no unfortunate name collision.
					 */
					Map<String, String> replaceMap = buildReplaceMap(node);
					Edge inFlow = getOrDefault(node.getFlowInputs(), 0, null);
					// Name of place that holds source context value for this transition. Some 
					// tasks may not have in-flow, such as in headless components. For parallel
					// join gates, any input context should be the same (condition to join).
					String preCtxName = null;
					if(inFlow != null) {
						preCtxName = sanitize(getPNSourcePlaceName(inFlow));
						if (compCtxName != null) {
							replaceMap.put(compCtxName, preCtxName);
						}
					}
					// INPUTS
					ArrayList<String> inputs = new ArrayList<String>();
					for(Edge e: node.getAllInputs()) {
						inputs.add(sanitize(getPNSourcePlaceName(e)));
					}
					task += "with-inputs\t\t" + String.join(", ", inputs) + "\n";
					// GUARD
					String guard = node.getGuard();
					String parJoinGuard = makeParJoinGuard(node);
					String compiledGuard = ""; 
					if (guard != null) {
						compiledGuard += replaceAll(guard, replaceMap) + "\n";
					}
					if(parJoinGuard != null) {
						compiledGuard += parJoinGuard + "\n";
					}
					if (compiledGuard != "") {
						task += "with-guard\t\t" + compiledGuard;
					}
					for(Edge e: node.getAllOutputs()) {
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
								task += String.format("updates: %s := %s\n",  compile(e.getTar()), compile(e.getTar()));
							}
							if (e.getUpdate() != null && e.getUpdate() != "" ) {
								task += "updates:" + indent(replaceAll(e.getUpdate(), replaceMap)) + "\n";
							}
						} else { // then its context
							task += "produces-outputs\t" + postCtxName + (e.isSuppressed() ? " suppress\n" : "\n");
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replaceAll(e.getRefUpdate(), replaceMap)) + "\n}\n";
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replaceAll(e.getSymUpdate(), replaceMap)) + "\n}\n";
							}
							String updates = "";
							if (preCtxName != null) {
								// if there is in-flow, move the context between places in the PN.(**1)
								updates += indent(postCtxName + " := " + preCtxName) + "\n";
							}
							String update = node.getContextUpdate();
							if(update != null && update != "") {
								update = replaceWord(update, compCtxName, postCtxName); // (**1) postCtxName == preCtxName
								updates += indent(replaceAll(update, replaceMap)) + "\n";
							}
							if (updates != "") {
								task +=  "updates:\n" + updates;
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
	 * Construct a guard that checks for compatibility of input tokens to a parallel join gate.
	 * @param node is possibly an AND join gate element.
	 * @return a string with the guard if this is a node of AND gate type with at least 2 inputs.
	 * null otherwise.
	 */
	private String makeParJoinGuard (Element node) {
		if (model.isAnd(node.getId())) { // is AND ?
			List<Edge> inputs = node.getFlowInputs();
			if (inputs.size() > 1) { // is join ?
				ArrayList<String> inputNames = new ArrayList<String>();
				for(Edge e: inputs) {
					inputNames.add(sanitize(getPNSourcePlaceName(e)));
				}
				// check all inputs equal first input
				return String.join(" && ",
						inputNames.stream().skip(1).map(e -> e + " == " + inputNames.get(0) ).toList());
			}
		}
		return null;
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
	 * Flows from a fork xor gate to a merge xor gate introduce transitions in the CPN. Notice
	 * that other flows between xor gates are optimized away when merging xor gates connected components. 
	 */
	private List<String> getFlowActions(String component) {
		List<String> result = new ArrayList<String>();
		for (Edge e: model.edges) {
			String src = e.getSrc();
			String tar = e.getTar();
			if(model.isXor(src) && model.isForkGate(src) &&
					model.isXor(tar) && model.isMergeGate(tar)) {
				String task = "action\t\t\t" + repr(e) + "\n";
				task += "case\t\tdefault\n";
				task += "with-inputs\t\t" + compile(src) + "\n";
				task += "produces-outputs\t" + compile(tar) + "\n";
				task += "updates\t\t" + compile(tar) + " := " + compile(src) + "\n";
				result.add(task);
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
				result.add(sanitize(compile(elem.getParentComponents().getLast())));
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
			// replace whole word only
			text = replaceWord(text, k, replace.get(k));
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
					for (Edge e: elem.getDataInputs()) {
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
	 * Assuming the target of e is a Task or an AND gate (which are compiled 
	 * to a transition in the PN) return the name of the source place in the PN.
	 */
	private String getPNSourcePlaceName(Edge e) {
		String srcId = e.getSrc();
		if (model.isTask(srcId) || model.isAnd(srcId)) {
			return namePlaceBetweenTransitions(e.getId(), compile(srcId), compile(e.getTar()));
		} else {
			return compile(srcId);
		}
	}
	
	/**
	 * Assuming the source of e is a Task or an AND gate (which are compiled
	 * to transition in the PN) return the name of the target place in the PN.
	 */
	private String getPNTargetPlaceName(Edge e) {
		String tarId = e.getTar();
		if (model.isTask(tarId) || model.isAnd(tarId)) {
			return namePlaceBetweenTransitions(e.getId(), compile(e.getSrc()), compile(tarId));
		} else {
			return compile(tarId);
		}
	}

	public String generateTypes() {
		String types = new String("");
		// UNIT_TYPE is the type for undefined contexts.
		types += String.format("record %s {\n\tstring __uuid__\n\tint\tunit\n}\n\n", UNIT_TYPE);
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
		String fieldName = e.getKey();
		String fieldTypeName = e.getValue();	
		return typeToString(fieldTypeName)  + "\t" + fieldName + "\n";
	}
		
	private String typeToString(String dataTypeName) {
		Bpmn4sDataType dataType = model.dataSchema.get(dataTypeName);
		String result = "";
		if (dataType == null) {
			return mapType(dataTypeName);
		} else {
			if (dataType instanceof ListType) {
				ListType lst = ListType.class.cast(dataType);
				result = String.format("%s[]" , typeToString(lst.valueType)); 
			} else if (dataType instanceof MapType) {
				MapType mp = MapType.class.cast(dataType);
				result = String.format("map<%s,%s>", typeToString(mp.keyType), typeToString(mp.valueType));
			} else if (dataType instanceof SetType) {
				SetType st = SetType.class.cast(dataType);			
				result = String.format("set<%s>" , typeToString(st.valueType));
			} else {
				// record, enumerations and basic types go here
				result = mapType(dataType.getName()); 
			}
		}
		return result;
	}
	
	/**
	 * Basic types in BPMN4S editor start with upper case, 
	 * while in pspec they are lower cased.
	 */
	protected String mapType(String name) {
		return switch (name) {
			case "Int", "String" -> name.toLowerCase();
			case "Boolean" -> "bool";
			case "Float" -> "real";
			default -> name;
		};
	}

	//
	// Helper functions
	//
	protected Boolean isAPlace (String id) {
		Element elem = model.getElementById(id);
		ElementType t = elem.getType();
		return t == ElementType.DATASTORE 
				|| t == ElementType.MSGQUEUE 
				|| t == ElementType.XOR_GATE 
				|| t == ElementType.START_EVENT 
				|| t == ElementType.END_EVENT;
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
		String name = elem.getFlowOutputs().get(0).getTar();
		Element result = model.getElementById(name);
		return result;
	}
	
	/**
	 * 
	 * @param elem
	 * @return
	 */
	private Element getPrevFlowElement(Element elem) {
		String name = elem.getFlowInputs().get(0).getSrc();
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
			return String.join("__", el.getParentComponents().stream()
					.map(e -> repr(model.getElementById(e)))
					.collect(Collectors.toList())) + "__" + repr(el);
		}
		return repr(el);
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
	
	
	/**
	 * Return the name of a compiled place representing a connected component of XOR gates. 
	 * For test generation, this is either the name of a single xor gate for singleton nets, 
	 * or a composed name identifying all the gates in the net otherwise.
	 */
	private String buildXorNetName(AbstractSet<String> xorNet) {
		String result = "";
		if (xorNet.size() > 1) {
			result = "merged";
			for(String id: xorNet) {
				result += "_" + repr(model.getElementById(id));
			}	
		}else if(xorNet.size() == 1){
			Element elem = model.getElementById(xorNet.iterator().next());
			result = repr(elem);
		}else {
			result = null;
		}
		return result;
	}
	
	
	/**
	 * Networks of connected XOR gates in the bpmn4s model are merged 
	 * into single places in the target PN. This method returns the name
	 * of the target place. For test generation we build the network of connected components 
	 * and use all its elements to build a name. For simulation we follow a different 
	 * algorithm which does not require to know all elements in the connected component.
	 */
	protected String getCompiledXorName(String xorId) {
		Element xor = model.getElementById(xorId);
		String result = compiledGateName.get(xor.getId());
		if(result == null) {
			AbstractSet<String> net = new HashSet<String>();
			buildXorNet(xor, net);
			result = buildXorNetName(net);
			for(String id: net) {
				compiledGateName.put(id, result);
			}
		}
		return result;
	}
	
	/**
	 * Build the Maximal Connected Component of xor gates that contains <xor> and 
	 * add its elements to <net>. Notice that <net> is used as an accumulator for
	 * the recursive algorithm. Also notice that edges from FORK gates to MERGE gates
	 * do not build connected components, since this is not a sound transformation.
	 */
	private void buildXorNet(Element xor, AbstractSet<String> net) {
		net.add(xor.getId());
		for(Edge input: xor.getFlowInputs()) {
			String srcId = input.getSrc();
			if(model.isXor(srcId)) {
				if(!net.contains(srcId)) {
					if (!(model.isForkGate(srcId) && model.isMergeGate(xor.getId()))) {
						buildXorNet(model.getElementById(srcId), net);
					}
				}
			}
		}
		for(Edge output: xor.getFlowOutputs()) {
			String tarId = output.getTar();
			if(model.isXor(tarId)) {
				if(!net.contains(tarId)) {
					if (!(model.isMergeGate(tarId) && model.isForkGate(xor.getId()))) {
						buildXorNet(model.getElementById(tarId), net);
					}
				}
			}
		}
	}
	
}
