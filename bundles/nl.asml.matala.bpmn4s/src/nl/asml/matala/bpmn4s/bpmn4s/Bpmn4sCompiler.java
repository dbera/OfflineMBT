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
	
	private final String UNIT_TYPE = "UNIT";
	private final String UNITINIT = "UNIT{ unit=0 }";

	String psFileName = "default.ps";
	String typesFileName = "default.types";
	
	StringBuilder ps = new StringBuilder();
	StringBuilder types = new StringBuilder();
	
	HashSet<String> initialized = new HashSet<String>();
	// Connected XOR gates are collapsed to avoid non-det due to immediately enabled 
	// transitions between them. Here we keep a map from the individual names to the
	// collapsed name in the target CPN.
	AbstractMap<String, String> compiledGateName = new HashMap<String, String>();
	
	public void compile (Bpmn4s model) {
		
		String modelname = sanitize(model.getName());
		
		this.psFileName = modelname + ".ps";
		this.typesFileName = modelname + ".types";
		
		// pspec model
		ps.append("import \"" + this.typesFileName + "\"\r\n"
				+ "specification " + modelname + "\r\n"
				+ "{\r\n");
		
		for (Element c: model.elements.values()) {
			if (model.isComponent(c)) {
				if (hasChildComponents(model, c)){ continue; } // skip top level components
				String component = "";
				String cname = compileComponentName(model, c) + repr(c);
//				if (!cname.equals("")) cname += "_" + c.getName(); else cname = c.getName();
				component += "system " + sanitize(cname) + "\r\n{\r\n";
				String inOut = fabSpecInputOutput(model, c);
				String local = fabSpecLocal(model, c);
				String init = fabSpecInit(model, c.getId());
				String desc = fabSpecDescription(model, c.getId()); 
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
		
		ps.append(String.format("\tSUT-blocks %s\n", String.join(" ", listSUTcomponents(model)))); 
		ps.append("\tdepth-limits 300\n}\r\n");
		
		// types
		types.append(generateFabSpecTypes(model));
	}

	
	/* 
	 * Nested components are compiled with their fully qualified name.
	 */
	private String compileComponentName (Bpmn4s model, Element c) {
		return String.join("", c.getComponent().stream()
				.map(e -> repr(model, e))
				.collect(Collectors.toList()));
	}
	
	/*
	 * Get a list with the names of components that have a RUN task in them.
	 */
	private ArrayList<String> listSUTcomponents (Bpmn4s model) {
		ArrayList<String> result = new ArrayList<String>();
		for (Element elem: model.elements.values()) {
			if (model.isRunTask(elem.getId())) {
				result.add(compileComponentName(model, elem));
			}
		}
		return result;
	}
	
	private String fabSpecInputOutput(Bpmn4s model, Element c) {
		String inStr = "inputs\n";
		String outStr = "outputs\n";
		
		for (Edge e: c.getInputs()) {
			Element node = model.elements.get(e.getSrc());
			inStr += node.getDataType() + "\t" + repr(node) + "\n";
		}
		for (Edge e: c.getOutputs()) {
			Element node = model.elements.get(e.getTar());
			outStr += node.getDataType() + "\t\t" + repr(node) + "\n";
		}
		if (c.getInputs().isEmpty()) { inStr = "//" + inStr; }
		if (c.getOutputs().isEmpty()) { outStr = "//" + outStr; }
		return inStr + "\n" + outStr;
	}
	

	private String fabSpecLocal(Bpmn4s model, Element c) {
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
				String cGateName = getCompiledGateName(model, xor); 
				String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
				if (!visited.contains(cGateName)) {
					visited.add(cGateName);
					locals += tabulate(datatype, sanitize(cGateName)) + "\n";
				}
			}
		}
		/* START_EVENTs introduce a place if followed by a task or an AND gate */
		for (Element se: model.elements.values()) {
			if (se.getType().equals(ElementType.START_EVENT) && isParent( c, se)) { 
				Edge edge = se.getOutputs().get(0);
				Element tar = model.getElementById(edge.getTar());
				if(tar.getType() == ElementType.TASK || tar.getType() == ElementType.AND_GATE) { 
					String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
					locals += tabulate(datatype, sanitize(repr(se))) + "\n";
				}
			}
		}
		/* END_EVENTs introduce a place if preceded by a task or an AND gate */
		for (Element se: model.elements.values()) {
			if (se.getType().equals(ElementType.END_EVENT) && isParent( c, se)) { 
				Edge edge = se.getInputs().get(0);
				Element src = model.getElementById(edge.getSrc());
				if(src.getType() == ElementType.TASK || src.getType() == ElementType.AND_GATE) { 
					String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
					locals += tabulate(datatype, sanitize(repr(se))) + "\n";
				}
			}
		}
		/* Edges between transitions introduce places. */
		for (Edge e: model.edges) {
			String srcId = e.getSrc();
			String tarId = e.getTar();
			Element src = model.getElementById(srcId);
			Element tar = model.getElementById(tarId);
			if (isParent( c, src) 
					&& !model.isXor(srcId) && !model.isData(srcId)
					&& !model.isXor(tarId) && !model.isData(tarId)
					&& !model.isEvent(srcId) && !model.isEvent(tarId)){
				assert isParent( c, tar);
				String datatype = mapType(c.context.dataType != "" ? c.context.dataType : UNIT_TYPE);
				locals += tabulate(datatype, sanitize(namePlaceBetweenTransitions(repr(src), repr(tar)))) + "\n";
			}
		}
		if (!locals.isBlank()) {
			locals = "local\n" + locals;
		}
		return locals;
	}	

	private String fabSpecInit(Bpmn4s model, String component) {
		String init = "";
		Element c = model.getElementById(component);
		String ctxName = c.getContextName();
		String ctxDataType = c.getContextDataType();
		String ctxInit = c.getContextInit();
		AbstractList<String> initPlaces = getInitialPlaces(model, c);
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
					init += replace(ds.getInit(), repr(ds), repr(ds)) + "\n"; // FIXME what am I replacing here??
					initialized.add(ds.getId());
				}
			}
		}
		return init == "" ? "// init\n" : "init\n" + init;
	}
	
	protected AbstractList<String> getInitialPlaces (Bpmn4s model, Element component) {
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
				Element e = getNextFlowElement(model, next);
				if (e.getType() == ElementType.AND_GATE) {
					queue.add(e);
				} else if (e.getType() == ElementType.TASK) {
					result.add(repr(next)); // FIXME need to add start event as a place (what does this mean??? make better comments)
				} else if (e.getType() == ElementType.XOR_GATE) {
					result.add(getCompiledName(model, e));
				} 
			}else if (next.getType() == ElementType.AND_GATE) {
				for (Edge edge: next.getOutputs()) {
					if (model.isXor(edge.getTar())) {
						result.add(getCompiledName(model, edge.getTar()));
					} else if (model.isAnd(edge.getTar())) {
						queue.add(model.getElementById(edge.getTar()));
					} else if (model.isTask(edge.getTar())) {
						String tarId = edge.getTar();
						Element tar = model.getElementById(tarId);
						result.add(namePlaceBetweenTransitions(repr(next), repr(tar)));
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
	private String namePlaceBetweenTransitions(String src, String dst) {
		return String.format("between_%s_and_%s", src, dst);
	}
	
	private String fabSpecDescription(Bpmn4s model, String component) {
		ArrayList<String> desc = new ArrayList<String>();
		for (Element node: model.elements.values()) {
			if (isParent(component, node)) { 
				ElementType nodeType = node.getType();
				if( nodeType == ElementType.TASK  || nodeType == ElementType.AND_GATE ) {			
					// Tasks and Parallel gates are transitions in the CPN
					String task = "";
					// Name of context as defined by user at front end:
					String compCtxName = model.getElementById(component).getContextName();  
					task += "action\t\t\t" + sanitize(repr(node)) + "\n";
					// STEP TYPE
					String stepConf = "";
					if (model.isComposeTask(node.getId())) {
						String stepType = node.getStepType();
						stepConf = String.format(" step-type \"%s\" action-type COMPOSE", stepType);
					} else if(model.isRunTask(node.getId())) {
						String stepType = node.getStepType();
						stepConf = String.format(" step-type \"%s\" action-type RUN", stepType);
					}
					task += "case\t\t\t" + "default" + stepConf + "\n";
					// INPUTS
					List<String> inputs = new ArrayList<String>();
					// FIXME: We are not considering AND join gates properly. 
					// They have several inputs. How do we check for compatible 
					// context from different inputs to the gate?
					Edge inFlow = node.inputs.get(0);	
					// Name of place that holds source context value for this transition:
					String preCtxName  = sanitize(getPNSourceName(model, inFlow));
					for(Edge e: node.getInputs()) {
						inputs.add(sanitize(getPNSourceName(model, e)));
					}
					task += "with-inputs\t\t" + String.join(", ", inputs) + "\n";
					// GUARD
					String guard = node.getGuard();
					if (guard != null) {
						task += "with-guard\t\t" + replace(guard, compCtxName, preCtxName) + "\n";
					}
					for(Edge e: node.getOutputs()) {
						// Name of place that holds target context value for this transition:
						String postCtxName = sanitize(getPNTargetName(model, e)) ;
						if (model.isData(e.getTar())) {
							task += "produces-outputs\t" + sanitize(repr(model, e.getTar()));
							if (isLinked(model, node.getId(), e.getTar())) {
								task += " assert\n";
							} else if (e.isSuppressed()) {
								task += " suppress\n";
							} else {
								task += "\n";
							}
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replace(e.getRefUpdate(), compCtxName, preCtxName)) + "\n}\n" ;
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replace(e.getSymUpdate(), compCtxName, preCtxName)) + "\n}\n";
							}
							if (e.isPersistent()) {
								task += String.format("updates: %s := %s\n",  repr(model, e.getTar()), repr(model, e.getTar())) ;
							}
							if (e.getUpdate() != null && e.getUpdate() != "" ) {
								task += "updates:" + indent(replace(e.getUpdate(), compCtxName, preCtxName)) + "\n";
							}
						} else { // then its context
							task += "produces-outputs\t" + postCtxName + (e.isSuppressed() ? " suppress\n" : "\n");
							if (e.getRefUpdate() != null && e.getRefUpdate() != "") {
								task += "references {\n" + indent(replace(e.getRefUpdate(), compCtxName, preCtxName)) + "\n}\n" ;
							}
							if (e.getSymUpdate() != null && e.getSymUpdate() != "") {
								task += "constraints {\n" + indent(replace(e.getSymUpdate(), compCtxName, preCtxName)) + "\n}\n";
							}
							// move the context between places in the PN
							task += "updates:" + indent(postCtxName + " := " + preCtxName) + "\n";
							String update = e.getUpdate();
							if(update != null && update != "") {
								// Add users updates
								String[] assignment = update.split(":=");
								update = replace(assignment[0] + ":=" + assignment[1], compCtxName, postCtxName);
								task += indent(update) + "\n";
							}
						}
					}
					desc.add(task);
				
				} 
			}
		}
		return "desc \"" + repr(model, component) + "_Model\"\n\n" + String.join("\n", desc);
	}
	
	private boolean isLinked(Bpmn4s model, String source, String data) {
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
	
	private String getPNSourceName(Bpmn4s model, Edge e) {
		//		FIXME check preconditions for this method and its correctness 
		if (this.isAPlace(model, e.getSrc())) {
			return getCompiledName(model, e.getSrc());
		} else {
			if (!model.isTask(e.getSrc()) && !model.isAnd(e.getSrc())) {
				Logging.logError(String.format("%s should be a task or par gate!", e.getSrc()));
			}
			return namePlaceBetweenTransitions(repr(model, e.getSrc()), repr(model, e.getTar()));
		}
	}
	
	private String getPNTargetName(Bpmn4s model, Edge e) {
		// assumes e.getTar() is a task
		// FIXME check preconditions for this method and its correctness 
		if (this.isAPlace(model, e.getTar())) {
			return getCompiledName(model, e.getTar());
		} else {
			if (!model.isTask(e.getTar()) && !model.isAnd(e.getTar())) {
				Logging.logError(String.format("%s should be a task or par gate!", e.getTar()));
			}
			return namePlaceBetweenTransitions(repr(model, e.getSrc()), repr(model, e.getTar()));
		}
	}
	
	public String generateFabSpecTypes(Bpmn4s model) {
		String types = new String("");
		types += String.format("record %s {\n\tint\tunit\n}\n\n", UNIT_TYPE);
		for (Bpmn4sDataType d: model.dataSchema.values()) {
			if(d instanceof RecordType) {
				RecordType rec = RecordType.class.cast(d);
				String type = "record " + rec.getName() + " {\n";
				String parameters = "";
				for (Entry<String, String> e: rec.fields.entrySet()) {
					parameters += generateRecordField(model, e);
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
	
	private String generateRecordField(Bpmn4s model, Entry<String, String> e) {
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
	
	private String mapType(String name) {
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
	private Boolean isAPlace (Bpmn4s model, String name) {
		Element elem = model.getElementById(name);
		if (elem != null) {
			ElementType t = elem.getType();
			return t == ElementType.DATASTORE 
					|| t == ElementType.MSGQUEUE 
					|| t == ElementType.XOR_GATE 
					|| t == ElementType.START_EVENT 
					|| t == ElementType.END_EVENT;
		} else {
			Logging.logWarning("No vertex named " + name);
			return false;
		}
	}
	

	Boolean isParent(Element parent, Element child) {
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
	
	Boolean hasChildComponents(Bpmn4s model, Element c) {
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
	
	private String sanitize(String str) {
		/*
		 * The BPMN4S editor allows spaces and colons in names, 
		 * but PSpec is more restrictive so we replace them.
		 */
//		String result = str.replaceAll("\\p{Zs}+", "00SP00").replace(".", "00CLN00");
		String result = str.replaceAll("\\p{Zs}+", "").replace(".", "");
		return result;
	}
		

	private String indent(String str) {
		return str.replaceAll("(?m)^", "    ");
	}

	private String tabulate (String... strings) {
		return String.join("\t", strings);
	}

	private Element getNextFlowElement(Bpmn4s model, Element elem) {
		/* 
		 * For instance to get the first element after a start event
		 */
		String name = elem.outputs.get(0).getTar();
		Element result = model.getElementById(name);
		return result;
	}

	private String getCompiledName(Bpmn4s model, String elemId) {
		if (model.isXor(elemId)) {
			return getCompiledGateName(model, model.getElementById(elemId));
		} else {
			return repr(model, elemId); // FIXME check if there are no other cases 
		}
	}
	
	private String getCompiledName(Bpmn4s model, Element elem) {
		return getCompiledName(model, elem.getId());
	}

	private String repr(Bpmn4s model, String elId) {
		return repr(model.getElementById(elId));
	}
	
	protected String repr(Element el) {
//		if(this.simulation) {
//			return el.getId();
//		}else {
//			return el.getName();
//		}
		return el.getName();
	}
	
	/*
	 * Networks of connected XOR gates are merged into single
	 * places in the target PN. This method returns the name
	 * of the target place.
	 */	
	protected String getCompiledGateName(Bpmn4s model, Element xor) {
		String result = compiledGateName.get(xor.getId());
		if(result == null) {
			AbstractSet<String> net = new HashSet<String>();
			buildXorNet(model, xor, net);
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
	private void buildXorNet(Bpmn4s model, Element xor, AbstractSet<String> net) {
		net.add(repr(xor));
		for(Edge input: xor.getInputs()) {
			String srcId = input.getSrc();
			if(model.isXor(srcId)) {
				if(!net.contains(repr(model.getElementById(srcId)))) {
					buildXorNet(model, model.getElementById(srcId), net);
				}
			}
		}
		for(Edge output: xor.getOutputs()) {
			String tarId = output.getTar();
			if(model.isXor(tarId)) {
				if(!net.contains(repr(model.getElementById(tarId)))) {
					buildXorNet(model, model.getElementById(tarId), net);
				}
			}
		}
	}
}
