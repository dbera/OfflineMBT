package nl.asml.matala.bpmn4s;
import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.AbstractList;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.camunda.bpm.model.bpmn.Bpmn;
import org.camunda.bpm.model.bpmn.BpmnModelInstance;
import org.camunda.bpm.model.bpmn.instance.Activity;
import org.camunda.bpm.model.bpmn.instance.BaseElement;
import org.camunda.bpm.model.bpmn.instance.DataInputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataObjectReference;
import org.camunda.bpm.model.bpmn.instance.DataOutputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataStoreReference;
import org.camunda.bpm.model.bpmn.instance.EndEvent;
import org.camunda.bpm.model.bpmn.instance.Event;
import org.camunda.bpm.model.bpmn.instance.ExclusiveGateway;
import org.camunda.bpm.model.bpmn.instance.FlowElement;
import org.camunda.bpm.model.bpmn.instance.FlowNode;
import org.camunda.bpm.model.bpmn.instance.ItemAwareElement;
import org.camunda.bpm.model.bpmn.instance.ParallelGateway;
import org.camunda.bpm.model.bpmn.instance.SequenceFlow;
import org.camunda.bpm.model.bpmn.instance.StartEvent;
import org.camunda.bpm.model.bpmn.instance.Process;
import org.camunda.bpm.model.bpmn.instance.SubProcess;
import org.camunda.bpm.model.bpmn.instance.Task;
import org.camunda.bpm.model.xml.instance.ModelElementInstance;

import nl.asml.matala.bpmn4s.extensions.DataType;
import nl.asml.matala.bpmn4s.extensions.DataTypeImpl;
import nl.asml.matala.bpmn4s.extensions.Field;
import nl.asml.matala.bpmn4s.extensions.FieldImpl;
import nl.asml.matala.bpmn4s.extensions.Literal;
import nl.asml.matala.bpmn4s.extensions.LiteralImpl;
import nl.asml.matala.bpmn4s.extensions.TargetDataRefImpl;

import nl.asml.matala.bpmn4s.bpmn4s.Bpmn4s;
import nl.asml.matala.bpmn4s.bpmn4s.ElementType;
import nl.asml.matala.bpmn4s.bpmn4s.EnumerationType;
import nl.asml.matala.bpmn4s.bpmn4s.ListType;
import nl.asml.matala.bpmn4s.bpmn4s.MapType;
import nl.asml.matala.bpmn4s.bpmn4s.RecordType;
import nl.asml.matala.bpmn4s.bpmn4s.SetType;
import nl.asml.matala.bpmn4s.bpmn4s.Bpmn4sCompiler;
import nl.asml.matala.bpmn4s.bpmn4s.Edge;
import nl.asml.matala.bpmn4s.bpmn4s.Element;
import nl.asml.matala.bpmn4s.bpmn4s.Bpmn4sDataType;


public class Main {
	
	static Bpmn4s model;

	static final String SUBTYPE_COMPONENT = "Component";
	static final String SUBTYPE_QUEUE = "Queue";
	static final String SUBTYPE_RUNTASK = "RunTask";
	static final String SUBTYPE_COMPOSETASK = "ComposeTask";
	
	public static void main(String[] args) {
		/*
		 * arg0 is path to input model. 
		 * arg1 is true for simulation tailored compilation, else for test generation. 
		 * arg2 is output folder for generated ps and types files.
		 * arg3 is depth limit for test generation.
		 */
		String inputModel = "";
		boolean simulation = false;
		String output = "";
		int depthLimit = 300;
		
		if(args.length < 1) {
			Logging.logError("Missing model file name!");
			System.exit(1);
		} else {
			inputModel = args[0];
		}
		if(args.length > 1) {
			simulation = Boolean.parseBoolean(args[1]);
		}
		if(args.length > 2) {
			output = args[2];
		}
		if(args.length > 3) {
			depthLimit = Integer.parseInt(args[3]);
		}
		compile(inputModel, simulation, output, depthLimit);
	}
	
	public static void compile(String inputModel, boolean simulation, String outputFolder, int depthLimit) {
        BpmnModelInstance modelInst;
        try {
        	registerModelExtensionTypes();
        	Path path = Paths.get(inputModel);
        	String fileName = path.getFileName().toString();
        	fileName = fileName.substring(0, fileName.lastIndexOf('.')); // remove file extension (.pbmn)
        	File file = path.toFile();
        	modelInst = Bpmn.readModelFromFile(file);
        	model = new Bpmn4s();
        	model.setName(fileName);
        	model.setDepthLimit(depthLimit);
        	parseBPMN(modelInst);
        	Bpmn4sCompiler compiler;
        	if (simulation) {
        		compiler = new Bpmn4sCompiler() {
        			@Override
        			protected String repr(Element el) {
        				return el.getId();
        			}		
        			@Override
        			protected String getCompiledXorName(String xorId) {
        				return repr(model.getElementById(xorId));
        			}
        			@Override
        			protected AbstractList<String> getInitialPlaces (String cId) {
        				Element c = model.getElementById(cId);
        				ArrayList<String> result = new ArrayList<String>();
        				result.add(repr(model.getStartEvent(c)));
        				return result;
        			}
        			@Override
        			protected String namePlaceBetweenTransitions(String flowId, String src, String dst) {
        				return flowId;
        			}
        			@Override
        			protected List<String> localsFromStartEvents (Element c) {
        				List<String> result = new ArrayList<String>();
        				for (Element se: model.elements.values()) {
        					if (se.getType().equals(ElementType.START_EVENT) && isParentComponent(c, se)) { 
    							String datatype = mapType(c.getContextDataType() != "" ? c.getContextDataType() : UNIT_TYPE);
    							result.add(tabulate(datatype, sanitize(repr(se))));
        						}
        					}
        				return result;
        			}
        			@Override
        			protected List<String> localsFromEndEvents (Element c) {
        				List<String> result = new ArrayList<String>();
        				for (Element se: model.elements.values()) {
        					if (se.getType().equals(ElementType.END_EVENT) && isParentComponent(c, se)) { 
    							String datatype = mapType(c.getContextDataType() != "" ? c.getContextDataType() : UNIT_TYPE);
    							result.add(tabulate(datatype, sanitize(repr(se))));
        						}
        					}
        				return result;
        			}
        			@Override
        			protected List<String> getFlowActions(String component) {
        				Element c = model.getElementById(component);
        				ArrayList<String> result = new ArrayList<String>();
        				for (Element source: model.elements.values()) {
        					if ((isAPlace(source.getId()) || model.isActivity(source.getId())) 
        							&& isParentComponent( c, source)) { 
        						for(Edge e: source.getOutputs()) {
        							String sourceId = e.getSrc();
        							String targetId = e.getTar();
        				 			if (isAPlace(targetId)) {
        								String action = "";
        								action += "action            " + repr(e) + "\n";
        								action += "case              default\n";
        								action += "with-inputs       " + sourceId + "\n";
        								action += "produces-outputs  " + targetId + "\n";
        								action += String.format("updates:          %s := %s\n", targetId, sourceId);
        								result.add(action);
        							}
        						}
        					}
        				}
        				return result;
        			}
        			@Override
        			protected Map<String, String> buildReplaceMap (Element transition) {
        				Map<String, String> replaceMap = new HashMap<String, String>();
        				ArrayList<String> replaceIds = getInputOutputIds(transition);
        				for(String id: replaceIds) {
        					replaceMap.put(model.getElementById(id).getName(), compile(id));
        				}
        				return replaceMap;
        			}
        		};
        	}else {
        		compiler = new Bpmn4sCompiler();
        	}
        	compiler.compile(model);
        	compiler.writeModelToFiles(outputFolder);
        } catch (Exception e) { e.printStackTrace(); }
	}

	private static void registerModelExtensionTypes() {
		DataTypeImpl.registerType(Bpmn.INSTANCE.getBpmnModelBuilder());
		FieldImpl.registerType(Bpmn.INSTANCE.getBpmnModelBuilder());
		LiteralImpl.registerType(Bpmn.INSTANCE.getBpmnModelBuilder());
		TargetDataRefImpl.registerType(Bpmn.INSTANCE.getBpmnModelBuilder());
	}
	
	/*
	 * Collect all interesting elements from the xml model and populate the 
	 * bpmn4s data structure (i.e. this.model).
	 */
	public static void parseBPMN(BpmnModelInstance modelInst) {
			
		Collection<DataType> datatypes = modelInst.getModelElementsByType(DataType.class);
		for (DataType dt: datatypes) { 
			parseDataType(modelInst, dt); 
		}
		
		Collection<DataStoreReference> dataStores = modelInst.getModelElementsByType(DataStoreReference.class);
		for (DataStoreReference ds: dataStores) {
			makeDataNode(modelInst, ds, ElementType.DATASTORE); 
		}
		
		Collection<DataObjectReference> dataObjects = modelInst.getModelElementsByType(DataObjectReference.class);
		// In BPMN4S these are message queues
		for (DataObjectReference dor: dataObjects) {
			if (! model.elements.containsKey(dor.getAttributeValue("name"))) {
				makeDataNode(modelInst, dor, ElementType.MSGQUEUE); 
			}
		}
		
		// Activities and Components
		Collection<Process> process = modelInst.getModelElementsByType(Process.class);
		for (Process sp: process) {	parseProcess(modelInst, sp); }
		
		Collection<SubProcess> subprocesses = modelInst.getModelElementsByType(SubProcess.class);
		for (SubProcess sp: subprocesses) {	parseSubprocess(modelInst, sp); }
		
		Collection<Task> tasks = modelInst.getModelElementsByType(Task.class);
		for (Task task: tasks) { parseTask(modelInst, task); }
		
		Collection<StartEvent> sevents = modelInst.getModelElementsByType(StartEvent.class);
		for (StartEvent ev: sevents) { parseEvent(modelInst, ev, ElementType.START_EVENT); };
		
		Collection<EndEvent> eevents = modelInst.getModelElementsByType(EndEvent.class);
		for (EndEvent ev: eevents) { parseEvent(modelInst, ev, ElementType.END_EVENT); }; 
		
		Collection<ExclusiveGateway> xor = modelInst.getModelElementsByType(ExclusiveGateway.class);
		for (ExclusiveGateway ev: xor) {makeActionNode(modelInst, ev, ElementType.XOR_GATE); }
		
		Collection<ParallelGateway> and = modelInst.getModelElementsByType(ParallelGateway.class);
		for (ParallelGateway ev: and) { makeActionNode(modelInst, ev, ElementType.AND_GATE); }
	}
	
	/*
	 * Parse and add DataStores and MessageQueues.
	 */
	static void makeDataNode(BpmnModelInstance modelInst, ItemAwareElement elem, ElementType type) {
		String name = NameResolver.getName(elem);
		String id = elem.getId();
		Element node = new Element(type, name, id);
		String origin = getOriginDataReference(elem);
		node.setOriginDataNodeId(origin != null ? origin : id);
		node.setParent(getParentId(elem));
		node.setComponent(getParentComponents(elem));
		String datatyperef = elem.getAttributeValueNs("http://bpmn4s", "dataTypeRef");
		DataType dt = getExtensionElementById(modelInst, DataType.class, datatyperef);
		String dtname = dt != null? dt.getAttributeValue("name"): datatyperef;
		node.setDataType(dtname);
		String init = elem.getAttributeValueNs("http://bpmn4s", "init");
		node.setInit(init);
		model.addElement(id, node);
	}
	
	static boolean isReference(ItemAwareElement elem) {
		return elem.getAttributeValueNs("http://bpmn4s", "originDataReference") != null;
	}
	
	static String getOriginDataReference(ItemAwareElement elem) {
		return elem.getAttributeValueNs("http://bpmn4s", "originDataReference");
	}
	
	public static void parseTask(BpmnModelInstance modelInst, Task t) {
		String subTypeString = t.getAttributeValueNs("http://bpmn4s", "subType");
		ElementType taskType = ElementType.NONE;;
		if(subTypeString != null) {
			if (subTypeString.equals(SUBTYPE_COMPOSETASK)) {
				taskType = ElementType.COMPOSE_TASK;
			} else if (subTypeString.equals(SUBTYPE_RUNTASK)) {
				taskType = ElementType.RUN_TASK;
			}
		}
		makeActionNode(modelInst, t, ElementType.TASK, taskType);
		parseDataAssociations(t);
	}

	static void parseEvent(BpmnModelInstance modelInst, Event ev, ElementType type) {
		makeActionNode(modelInst, ev, type);
	}

	public static void parseDataType(BpmnModelInstance modelInst, DataType dt) {
		Bpmn4sDataType datatype = new Bpmn4sDataType("");
		String type = dt.getAttributeValue("type");
		if (type.equals("Record")) {
			datatype = parseRecord(modelInst, dt);
		}else if(type.equals("List")) {
			datatype = parseList(modelInst, dt);
		}else if(type.equals("Set")) {
			datatype = parseSet(modelInst, dt);
		}else if(type.equals("Map")) {
			datatype = parseMap(modelInst, dt);
		}else if(type.equals("Enumeration")){
			datatype = parseEnum(dt);
		}else {
			Logging.logError(String.format("Skipping unsuported datatype %s.", type));
		}
		model.dataSchema.put(datatype.getName(), datatype);
	}
	
	public static EnumerationType parseEnum(DataType dt) {
		EnumerationType result = new EnumerationType(dt.getAttributeValue("name"));
		for(Literal lit: dt.getChildElementsByType(Literal.class)) {
			String name = lit.getAttributeValue("name");
			String value = lit.getAttributeValue("value");
			result.addLiteral(name, value);
		}
		return result;
	}
	
	public static RecordType parseRecord(BpmnModelInstance modelInst, DataType dt) {
		String name = dt.getAttributeValue("name");
		RecordType rec = new RecordType(name);
		for(Field f: dt.getChildElementsByType(Field.class)) {
			String fname = f.getAttributeValue("name");
			String tref = f.getAttributeValue("typeRef");
			Collection<DataType> datatypes = modelInst.getModelElementsByType(DataType.class);
			String ftype = "";
			for (DataType t: datatypes) {
				if (tref.equals(t.getAttributeValue("id"))) {
					ftype = t.getAttributeValue("name");
					break;
				}
			}
			ftype = ftype.equals("") ? tref : ftype;
			rec.addField(fname, ftype);
		}
		return rec;
	}
	
	public static String getInnerType(BpmnModelInstance modelInst, DataType dt) {
		String tref = dt.getAttributeValue("valueTypeRef");
		DataType datatype = getExtensionElementById(modelInst, DataType.class, tref);
		String vtype = datatype != null ? datatype.getAttributeValue("name") : tref;
		return vtype;
	}
	
	public static ListType parseList (BpmnModelInstance modelInst, DataType dt) {
		String name = dt.getAttributeValue("name");
		ListType list = new ListType(name, getInnerType(modelInst, dt));
		return list;
	}
	
	public static SetType parseSet (BpmnModelInstance modelInst, DataType dt) {
		String name = dt.getAttributeValue("name");
		SetType set = new SetType(name, getInnerType(modelInst, dt));
		return set;
	}
	
	public static MapType parseMap (BpmnModelInstance modelInst, DataType dt) {
		String ktype = dt.getAttributeValue("keyTypeRef");
		String name = dt.getAttributeValue("name");
		MapType map = new MapType(name, ktype, getInnerType(modelInst, dt));
		return map;
	}

	public static void parseProcess(BpmnModelInstance modelInst, Process p) {
		makeActionNode(modelInst, p, ElementType.COMPONENT);
	}	
	
	public static void parseSubprocess(BpmnModelInstance modelInst, SubProcess sp) {
		String subtype = sp.getAttributeValueNs("http://bpmn4s", "subType");
		if (subtype != null && subtype.equals(SUBTYPE_COMPONENT)) {
			makeActionNode(modelInst, sp, ElementType.COMPONENT);
			parseDataAssociations(sp);
		} else {
			makeActionNode(modelInst, sp, ElementType.ACTIVITY);
			parseDataAssociations(sp);
		}
	}	
	
	/*
	 * For data interactive flow nodes such as tasks and subprocess (common parent class 
	 * Activity in Camunda) parse its input and output data associations and compile them
	 * as Edges in the bpmn4s model.
	 */
	public static void parseDataAssociations (Activity act) {
		Collection<DataInputAssociation> inputs = act.getDataInputAssociations();
		Collection<DataOutputAssociation> outputs = act.getDataOutputAssociations();
		for (DataOutputAssociation da: outputs) {
			String src = act.getId();
			String dst = da.getTarget().getId();
			String update = da.getAttributeValueNs("http://bpmn4s", "update");
			String ref_update = da.getAttributeValueNs("http://bpmn4s", "referenceUpdate");
			String sym_update = da.getAttributeValueNs("http://bpmn4s", "symbolicUpdate");
			String suppress = da.getAttributeValueNs("http://bpmn4s", "suppressUpdate");
			if(update == null) update = "";
			if(ref_update == null) ref_update = "";
			if(sym_update == null) sym_update = "";
			if(suppress == null) suppress = "";
			if(update.strip().startsWith("=")) update = update.substring(1); // FIXME due to issues with bpmn4s editor lsp integration
			Edge e = new Edge(da.getId(), src, update, ref_update, sym_update, dst);
			if (suppress.equals("true")) e.makeSupressed();
			model.addEdge(e);
			model.associateEdge(e);
		}
		for (DataInputAssociation da: inputs) {
			String dst = act.getId();
			String src = da.getSources().iterator().next().getId();
			Edge e = new Edge(da.getId(), src, "", "", "", dst);
			model.addEdge(e);
			model.associateEdge(e);
			boolean persistent = "true".equals(da.getAttributeValueNs("http://bpmn4s", "persistentRead"));	
			if (persistent) {
				Edge pe = new Edge(da.getId(), dst, "", "", "", src).makePersistent();
				// the update generated by persistent reads on compose tasks is suppressed 
				if(SUBTYPE_COMPOSETASK.equals(act.getAttributeValueNs("http://bpmn4s", "subType"))) pe.makeSupressed();
				model.addEdge(pe);
				model.associateEdge(pe);
			}
		}
		
	}
	
	public static void makeActionNode(BpmnModelInstance modelInst, BaseElement elem, ElementType type) {
		makeActionNode(modelInst, elem, type, ElementType.NONE);
	}
	
	/**
	 * Tasks, events, gates and components are compiled into bpmn4s elements.
	 * Task elements may have a taskType such as COMPOSE or RUN, to indicate 
	 * they are part of generated tests.
	 */
	public static void makeActionNode(BpmnModelInstance modelInst, BaseElement elem, ElementType type, ElementType taskType) {
		String name = getName(elem);
		String id = elem.getId();
		Element node = new Element(type, taskType, name);
		node.setId(id);
		if (elem instanceof FlowNode) {
			node.setParent(getParentId(elem));
			node.setComponent(getParentComponents(elem));
			node.setGuard(elem.getAttributeValueNs("http://bpmn4s", "guard"));
			node.setStepType(elem.getAttributeValueNs("http://bpmn4s", "stepType"));
		}
		String contextName = elem.getAttributeValueNs("http://bpmn4s", "ctxName");
		String contextInit = elem.getAttributeValueNs("http://bpmn4s", "ctxInit");
		String contextTypeId = elem.getAttributeValueNs("http://bpmn4s", "ctxTypeRef");
		String contextTypeName = "";
		if (contextTypeId != null) {
			DataType contextType = getExtensionElementById(modelInst, DataType.class, contextTypeId);
			if (contextType != null) { 
				contextTypeName = contextType.getAttributeValue("name"); 
			} else {
				contextTypeName = contextTypeId;
			}
		}
		if(contextInit != null && contextInit.strip().startsWith("=")) {
			contextInit = contextInit.substring(1); // FIXME due to issues with bpmn4s editor lsp integration
		}
		node.setContext(contextName != null ? contextName : "", 
				contextTypeName != null ? contextTypeName : "", 
						contextInit != null ? contextInit : "");
		model.addElement(id, node);
		if (elem instanceof FlowNode) {
			resolveNodeEdges((FlowNode) elem, node);
		}
	}
	
	static void resolveNodeEdges(FlowNode elem, Element node) {
		for(SequenceFlow out: elem.getOutgoing()) {
			Edge e = makeSequenceEdge(out);
			// Flow nodes may update the context
			String ctxUpdate = elem.getAttributeValueNs("http://bpmn4s", "ctxUpdate");
			e.setUpdate(ctxUpdate != null ? ctxUpdate : "");
			node.addOutput(e);
			model.addEdge(e);
		}
		for(SequenceFlow in: elem.getIncoming()) {
			Edge e = makeSequenceEdge(in);
			node.addInput(e);
			// We assume input flows are output flows of other 
			// nodes, thus we avoid duplication here.
			// model.addEdge(e);
		}
	}
	
	static Edge makeSequenceEdge (SequenceFlow elem) {
		FlowNode source = elem.getSource();
		FlowNode target = elem.getTarget();
		String srcId = source.getId();
		String tarId= target.getId();
		Edge e = new Edge(elem.getId(), srcId, "", "", "", tarId);
		boolean suppress = "true".equals(source.getAttributeValueNs("http://bpmn4s", "suppressUpdate"));
		if (suppress) e.makeSupressed();
		return e;
	}
	
	static boolean isComponent(ModelElementInstance sp) {
		String isSubprocess = sp.getElementType().getTypeName();
		String isComponent = sp.getAttributeValueNs("http://bpmn4s", "subType");
		return "subProcess".equals(isSubprocess) && SUBTYPE_COMPONENT.equals(isComponent);
	}
	
	static String getName(ModelElementInstance elem) {
		String name = elem.getAttributeValue("name");
		if (name == null) {
			name = elem.getAttributeValue("id");
		}
		return name;
	}

	/* 
	 * Return a list with the parent elements which are components, 
	 * ordered from top parent to bottom parent.
	 */
	static ArrayList<String> getParentComponents (ModelElementInstance elem) {
		ArrayList<String> result = new ArrayList<String>();
		ModelElementInstance parent = elem.getParentElement();
		while(parent != null) {
			String parentType = parent.getElementType().getTypeName();
			if(parentType.equals("process") || isComponent(parent)) {
				result.add(0, parent.getAttributeValue("id"));
			}
			parent = parent.getParentElement();
		}
		return result;
	}
	
	
	static String getParentId(ModelElementInstance elem) {
		ModelElementInstance parent = elem.getParentElement();
		if(parent == null) {
			return null;
		}
		return parent.getAttributeValue("id");
	}
	
	/*
	 * FIXME I don't know how to getElementById when the element is an
	 * extension element. So I made this function to help me.
	 */
	static <T extends ModelElementInstance> T getExtensionElementById (
			BpmnModelInstance modelInst, 
			Class<T> elementClass, 
			String id) 
	{
		Collection<T> elements = (Collection<T>) modelInst.getModelElementsByType(elementClass);
		for (T elem: elements) {
			if (elem.getAttributeValue("id").equals(id)) {
				return elem;
			}
		}
		return null;
	}

}
