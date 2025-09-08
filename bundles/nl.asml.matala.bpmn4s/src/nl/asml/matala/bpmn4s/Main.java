/*
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.bpmn4s;
import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
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
import org.camunda.bpm.model.bpmn.instance.FlowNode;
import org.camunda.bpm.model.bpmn.instance.ItemAwareElement;
import org.camunda.bpm.model.bpmn.instance.ParallelGateway;
import org.camunda.bpm.model.bpmn.instance.Process;
import org.camunda.bpm.model.bpmn.instance.SequenceFlow;
import org.camunda.bpm.model.bpmn.instance.StartEvent;
import org.camunda.bpm.model.bpmn.instance.SubProcess;
import org.camunda.bpm.model.bpmn.instance.Task;
import org.camunda.bpm.model.xml.instance.ModelElementInstance;

import nl.asml.matala.bpmn4s.bpmn4s.BaseType;
import nl.asml.matala.bpmn4s.bpmn4s.Bpmn4s;
import nl.asml.matala.bpmn4s.bpmn4s.Bpmn4sCompiler;
import nl.asml.matala.bpmn4s.bpmn4s.Bpmn4sDataType;
import nl.asml.matala.bpmn4s.bpmn4s.Edge;
import nl.asml.matala.bpmn4s.bpmn4s.Element;
import nl.asml.matala.bpmn4s.bpmn4s.ElementType;
import nl.asml.matala.bpmn4s.bpmn4s.EnumerationType;
import nl.asml.matala.bpmn4s.bpmn4s.ListType;
import nl.asml.matala.bpmn4s.bpmn4s.MapType;
import nl.asml.matala.bpmn4s.bpmn4s.RecordFieldKind;
import nl.asml.matala.bpmn4s.bpmn4s.RecordType;
import nl.asml.matala.bpmn4s.bpmn4s.SetType;
import nl.asml.matala.bpmn4s.extensions.DataType;
import nl.asml.matala.bpmn4s.extensions.DataTypeImpl;
import nl.asml.matala.bpmn4s.extensions.Field;
import nl.asml.matala.bpmn4s.extensions.FieldImpl;
import nl.asml.matala.bpmn4s.extensions.Literal;
import nl.asml.matala.bpmn4s.extensions.LiteralImpl;
import nl.asml.matala.bpmn4s.extensions.TargetDataRefImpl;


public class Main {
	
	static Bpmn4s model;

	static final String SUBTYPE_COMPONENT = "Component";
	static final String SUBTYPE_QUEUE = "Queue";
	static final String SUBTYPE_RUNTASK = "RunTask";
	static final String SUBTYPE_COMPOSETASK = "ComposeTask";
	static final String SUBTYPE_ASSERTTASK = "AssertTask";
	
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
		int numOfTests = 1;
		
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
		if(args.length > 4) {
			numOfTests = Integer.parseInt(args[4]);
		}
		compile(inputModel, simulation, output, depthLimit, numOfTests);
	}
	
	static final int DEFAULT_DEPTH_LIMIT = 300;
	static final int DEFAULT_NUM_OF_TESTS = 1;
	
	public static void compile(String inputModel, boolean simulation, String outputFolder) {
		compile(inputModel, simulation, outputFolder, DEFAULT_DEPTH_LIMIT, DEFAULT_NUM_OF_TESTS);
	}
	
	public static void compile(String inputModel, boolean simulation, String outputFolder, int depthLimit, int numOfTests) {
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
        	model.setNumOfTests(numOfTests);
        	parseBPMN(modelInst);
        	Bpmn4sCompiler compiler;
        	if (simulation) {
        		compiler = new Bpmn4sCompiler() {
        			
        			@Override
        			protected String repr(Element el) {
        				return el.getId();
        			}
        			
        			@Override
        			/**
        			 * Connected components of XOR gates are collapsed for optimization. A specific gate id
        			 * is chosen as the name for each collapsed set of gates.
        			 * Given an xor gate X, the name of its compiled collapsed component is obtained following this 
        			 * algorithm:
        			 * fun(X)
        			 * IF X is fork gate:
        			 *   get input of X 
        			 *   IF input is xor-fork gate:
        			 *     return fun(X)
        			 *   
        			 * ELSE IF X is merge gate:
        			 *   get output of X
        			 *   IF output is xor gate:
        			 *     return fun(X)
        			 * return id of X
        			 */
        			protected String getCompiledXorName(String xorId) {
        				Element xor = model.getElementById(xorId);
        				if (model.isForkGate(xorId)) {
        					Edge inputEdge = xor.getFlowInputs().get(0);
        					String srcId = inputEdge.getSrc();
        					if (model.isXor(srcId) && model.isForkGate(srcId)) {
        						return getCompiledXorName(srcId);
        					}
        				} else if (model.isMergeGate(xorId)) {
        					Edge outputEdge = xor.getFlowOutputs().get(0);
        					String tarId = outputEdge.getTar();
        					if (model.isXor(tarId)) {
        						return getCompiledXorName(tarId);
        					}
        				} 
        				return repr(xor);
        			}
        			
        			@Override
        			protected String getCompiledComponentName(String componentId) {
        				return repr(model.getElementById(componentId));
        			}
        			
        			@Override
        			protected String namePlaceBetweenTransitions(String flowId, String src, String dst) {
        				return flowId;
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

        			private ArrayList<String> getInputOutputIds(Element elem) {
        				ArrayList<String> result = new ArrayList<String>();
        				for (Edge e: elem.getAllInputs()) {
        					if(isAPlace(e.getSrc())) {
        						result.add(e.getSrc());
        					}
        				}
        				for (Edge e: elem.getAllOutputs()) {
        					if(isAPlace(e.getTar())) {
        						result.add(e.getTar());
        					}
        				}
        				return result;
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
		
		// relate nodes to edges
		for (Edge e: model.edges) {
			String src = e.getSrc();
			String tar = e.getTar();
			if (e.isFlowEdge()) {
				model.getElementById(src).addFlowOutput(e);
				model.getElementById(tar).addFlowInput(e);
			} else {
				model.getElementById(src).addDataOutput(e);
				model.getElementById(tar).addDataInput(e);
			}
		}
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
		node.setLinkedDataReferenceIds(getLinkedDataReferences(elem));
		node.setParent(getParentId(elem));
		node.setComponent(getParentComponents(elem));
		String datatyperef = elem.getAttributeValueNs("http://bpmn4s", "dataTypeRef");
		DataType dt = getExtensionElementById(modelInst, DataType.class, datatyperef);
		String dtname = dt != null? dt.getAttributeValue("name"): datatyperef;
		node.setDataType(dtname);
		String init = elem.getAttributeValueNs("http://bpmn4s", "init");
		node.setInit(init);
		String sutConf = elem.getAttributeValueNs("http://bpmn4s", "sutConfigurations");
		node.setIsSutConfigurations("true".equals(sutConf));
		model.addElement(id, node);
	}
	
	static boolean isReference(ItemAwareElement elem) {
		return elem.getAttributeValueNs("http://bpmn4s", "originDataReference") != null;
	}
	
	static String getOriginDataReference(ItemAwareElement elem) {
		return elem.getAttributeValueNs("http://bpmn4s", "originDataReference");
	}
	
	static String[] getLinkedDataReferences(ItemAwareElement elem) {
		String value = elem.getAttributeValueNs("http://bpmn4s", "linkedDataReferences");
		return value == null ? new String[0] : value.split("\\s+");
	}
	
	public static void parseTask(BpmnModelInstance modelInst, Task t) {
		String subTypeString = t.getAttributeValueNs("http://bpmn4s", "subType");
		ElementType taskType = ElementType.NONE;;
		if(subTypeString != null) {
			if (subTypeString.equals(SUBTYPE_COMPOSETASK)) {
				taskType = ElementType.COMPOSE_TASK;
			} else if (subTypeString.equals(SUBTYPE_RUNTASK)) {
				taskType = ElementType.RUN_TASK;
			} else if (subTypeString.equals(SUBTYPE_ASSERTTASK)) {
				taskType = ElementType.ASSERT_TASK;
			}
		}
		makeActionNode(modelInst, t, ElementType.TASK, taskType);
		parseDataAssociations(t);
	}

	static void parseEvent(BpmnModelInstance modelInst, Event ev, ElementType type) {
		makeActionNode(modelInst, ev, type);
	}

	public static void parseDataType(BpmnModelInstance modelInst, DataType dt) {
		String type = dt.getAttributeValue("type");
		Bpmn4sDataType datatype = switch (type) {
			case Bpmn4sDataType.RECORD_TYPE,
			     Bpmn4sDataType.CONTEXT_TYPE -> parseRecord(modelInst, dt);
			case Bpmn4sDataType.LIST_TYPE -> parseList(modelInst, dt);
			case Bpmn4sDataType.SET_TYPE -> parseSet(modelInst, dt);
			case Bpmn4sDataType.MAP_TYPE -> parseMap(modelInst, dt);
			case Bpmn4sDataType.ENUM_TYPE -> parseEnum(dt);
			case Bpmn4sDataType.STRING_TYPE,
			     Bpmn4sDataType.INT_TYPE,
			     Bpmn4sDataType.BOOLEAN_TYPE,
			     Bpmn4sDataType.FLOAT_TYPE -> parseBase(dt);
			default -> null;
		};
		if (datatype == null) {
			Logging.logError(String.format("Skipping unsuported datatype %s.", type));
		} else {
			model.dataSchema.put(datatype.getName(), datatype);
		}
	}
	
	public static BaseType parseBase(DataType dt) {
		return new BaseType(dt.getAttributeValue("name"),
				dt.getAttributeValue("type"));
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
			// tref is either a string representing a basic type (such as int or string) or
			// an id referencing a user defined data type. We assume the later and fall back 
			// on the former case.
			Collection<DataType> datatypes = modelInst.getModelElementsByType(DataType.class);
			String ftype = "";
			for (DataType t: datatypes) {
				if (tref.equals(t.getAttributeValue("id"))) {
					ftype = t.getAttributeValue("name");
					break;
				}
			}
			ftype = ftype.equals("") ? tref : ftype;
			RecordFieldKind fKind = RecordFieldKind.parse(f.getAttributeValueNs("http://bpmn4s", "kind"));
			Boolean fSuppress = "true".equalsIgnoreCase(f.getAttributeValueNs("http://bpmn4s", "suppressUpdate"));
			rec.addField(fname, ftype, fKind, fSuppress);
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
			Edge e = new Edge(da.getId(), Edge.EDGE_TYPE_DATA, src, update, ref_update, sym_update, dst);
			if (suppress.equalsIgnoreCase("true")) e.makeSupressed();
			model.addEdge(e);
		}
		for (DataInputAssociation da: inputs) {
			String dst = act.getId();
			String src = da.getSources().iterator().next().getId();
			Edge e = new Edge(da.getId(), Edge.EDGE_TYPE_DATA, src, "", "", "", dst);
			model.addEdge(e);
			boolean persistent = "true".equals(da.getAttributeValueNs("http://bpmn4s", "persistentRead"));	
			if (persistent) {
				Edge pe = new Edge(da.getId(), Edge.EDGE_TYPE_DATA, dst, "", "", "", src).makePersistent();
				// the update generated by persistent reads on compose tasks is suppressed 
				if(SUBTYPE_COMPOSETASK.equals(act.getAttributeValueNs("http://bpmn4s", "subType"))) pe.makeSupressed();
				model.addEdge(pe);
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
		if(contextInit != null && contextInit.startsWith("=")) {
			contextInit = contextInit.substring(1); // FIXME due to issues with bpmn4s editor lsp integration
		}
		node.setContext(contextName, contextTypeName, contextInit);
		
		
		if(type.equals(ElementType.TASK)) {
			node.setContextUpdate(elem.getAttributeValueNs("http://bpmn4s", "ctxUpdate"));
			node.setContextSuppressed("true".equalsIgnoreCase(elem.getAttributeValueNs("http://bpmn4s", "suppressUpdate")));
		}

		if(taskType.equals(ElementType.ASSERT_TASK)) {
			node.setAssertions(elem.getAttributeValueNs("http://bpmn4s", "assertions"));
		}
		
		model.addElement(id, node);
		if (elem instanceof FlowNode flowNode) {
			for(SequenceFlow out: flowNode.getOutgoing()) {
				model.addEdge(makeFlowEdge(out));
			}
		}
	}

	static Edge makeFlowEdge (SequenceFlow elem) {
		FlowNode source = elem.getSource();
		FlowNode target = elem.getTarget();
		String srcId = source.getId();
		String tarId= target.getId();
		Edge e = new Edge(elem.getId(), Edge.EDGE_TYPE_FLOW, srcId, "", "", "", tarId);
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
