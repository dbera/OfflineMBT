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

import static org.eclipse.lsat.common.queries.QueryableIterable.from;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
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
import org.camunda.bpm.model.xml.ModelBuilder;
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
import nl.asml.matala.bpmn4s.extensions.DataTypesImpl;
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
	
	/**
	 * arg0 is path to input model.<br/>
	 * arg1 is output folder for generated ps and types files.<br/>
	 * arg2 is depth limit for test generation.<br/>
	 * arg3 is number of test cases for test generation.<br/>
	 * arg4 is state-space limit for test generation.<br/>
	 */
	public static void main(String[] args) {
		String inputModel = "";
		String output = "";
		int depthLimit = 300;
		int stateLimit = 1000;
		int numOfTests = 1;
		
		if(args.length < 1) {
			Logging.logError("Missing model file name!");
			System.exit(1);
		} else {
			inputModel = args[0];
		}
		if(args.length > 1) {
			output = args[1];
		}
		if(args.length > 2) {
			depthLimit = Integer.parseInt(args[2]);
		}
		if(args.length > 3) {
			numOfTests = Integer.parseInt(args[3]);
		}
		if(args.length > 4) {
			stateLimit = Integer.parseInt(args[4]);
		}
		try {
			compile(inputModel, output, depthLimit, stateLimit, numOfTests);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
	
	static final int DEFAULT_DEPTH_LIMIT = 300;
	static final int DEFAULT_STATE_LIMIT = 1000;
	static final int DEFAULT_NUM_OF_TESTS = 1;
	
	public static void compile(String inputModel, String outputFolder) {
		compile(inputModel, outputFolder, DEFAULT_DEPTH_LIMIT, DEFAULT_STATE_LIMIT, DEFAULT_NUM_OF_TESTS);
	}
	
	public static void compile(String inputModel, String outputFolder, int depthLimit, int stateLimit, int numOfTests) {
        registerModelExtensionTypes();
    	Path path = Paths.get(inputModel);
    	String fileName = path.getFileName().toString();
    	fileName = fileName.substring(0, fileName.lastIndexOf('.')); // remove file extension (.bpmn)
    	File file = path.toFile();
    	BpmnModelInstance modelInst = Bpmn.readModelFromFile(file);
    	model = new Bpmn4s();
    	model.setName(fileName);
    	model.setDepthLimit(depthLimit);
    	model.setStateLimit(stateLimit);
    	model.setNumOfTests(numOfTests);
    	parseBPMN(modelInst);
    	Bpmn4sCompiler compiler = new Bpmn4sCompiler();
    	compiler.compile(model);
    	compiler.writeModelToFiles(outputFolder);
	}
	


	private static void registerModelExtensionTypes() {
		ModelBuilder modelBuilder = Bpmn.INSTANCE.getBpmnModelBuilder();
		DataTypeImpl.registerType(modelBuilder);
		DataTypesImpl.registerType(modelBuilder);
		FieldImpl.registerType(modelBuilder);
		LiteralImpl.registerType(modelBuilder);
		TargetDataRefImpl.registerType(modelBuilder);
	}
	
	/*
	 * Collect all interesting elements from the xml model and populate the 
	 * bpmn4s data structure (i.e. this.model).
	 */
	public static void parseBPMN(BpmnModelInstance modelInst) {
			
		Map<String, DataType> datatypes = from(modelInst.getModelElementsByType(DataType.class)).toMap(DataType::getId);
		for (DataType dt: datatypes.values()) {
			parseDataType(dt, datatypes);
		}
		
		Collection<DataStoreReference> dataStores = modelInst.getModelElementsByType(DataStoreReference.class);
		for (DataStoreReference ds: dataStores) {
			makeDataNode(ds, ElementType.DATASTORE, datatypes); 
		}
		
		Collection<DataObjectReference> dataObjects = modelInst.getModelElementsByType(DataObjectReference.class);
		// In BPMN4S these are message queues
		for (DataObjectReference dor: dataObjects) {
			if (!model.elements.containsKey(dor.getName())) {
				makeDataNode(dor, ElementType.MSGQUEUE, datatypes); 
			}
		}
		
		// Activities and Components
		Collection<Process> process = modelInst.getModelElementsByType(Process.class);
		for (Process sp: process) {	parseProcess(sp, datatypes); }
		
		Collection<SubProcess> subprocesses = modelInst.getModelElementsByType(SubProcess.class);
		for (SubProcess sp: subprocesses) {	parseSubprocess(sp, datatypes); }
		
		Collection<Task> tasks = modelInst.getModelElementsByType(Task.class);
		for (Task task: tasks) { parseTask(task, datatypes); }
		
		Collection<StartEvent> sevents = modelInst.getModelElementsByType(StartEvent.class);
		for (StartEvent ev: sevents) { parseEvent(ev, ElementType.START_EVENT, datatypes); };
		
		Collection<EndEvent> eevents = modelInst.getModelElementsByType(EndEvent.class);
		for (EndEvent ev: eevents) { parseEvent(ev, ElementType.END_EVENT, datatypes); }; 
		
		Collection<ExclusiveGateway> xor = modelInst.getModelElementsByType(ExclusiveGateway.class);
		for (ExclusiveGateway ev: xor) {makeActionNode(ev, ElementType.XOR_GATE, datatypes); }
		
		Collection<ParallelGateway> and = modelInst.getModelElementsByType(ParallelGateway.class);
		for (ParallelGateway ev: and) { makeActionNode(ev, ElementType.AND_GATE, datatypes); }
		
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
	static void makeDataNode(ItemAwareElement elem, ElementType type, Map<String, DataType> datatypes) {
		String name = NameResolver.getName(elem);
		String id = elem.getId();
		Element node = new Element(type, name, id);
		String origin = getOriginDataReference(elem);
		node.setOriginDataNodeId(origin != null ? origin : id);
		node.setLinkedDataReferenceIds(getLinkedDataReferences(elem));
		node.setParent(getParentId(elem));
		node.setComponent(getParentComponents(elem));
		String datatyperef = elem.getAttributeValueNs("http://bpmn4s", "dataTypeRef");
		String dtname = resolveTypeRef(datatyperef, datatypes);
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
	
	public static void parseTask(Task t, Map<String, DataType> datatypes) {
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
		makeActionNode(t, ElementType.TASK, taskType, datatypes);
		parseDataAssociations(t);
	}

	static void parseEvent(Event ev, ElementType type, Map<String, DataType> datatypes) {
		makeActionNode(ev, type, datatypes);
	}

	public static void parseDataType(DataType dt, Map<String, DataType> datatypes) {
		String type = dt.getType();
		Bpmn4sDataType datatype = switch (type) {
			case Bpmn4sDataType.RECORD_TYPE,
			     Bpmn4sDataType.CONTEXT_TYPE -> parseRecord(dt, datatypes);
			case Bpmn4sDataType.LIST_TYPE -> parseList(dt, datatypes);
			case Bpmn4sDataType.SET_TYPE -> parseSet(dt, datatypes);
			case Bpmn4sDataType.MAP_TYPE -> parseMap(dt, datatypes);
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
		return new BaseType(dt.getName(), dt.getType());
	}

	public static EnumerationType parseEnum(DataType dt) {
		EnumerationType result = new EnumerationType(dt.getName());
		for(Literal lit: dt.getChildElementsByType(Literal.class)) {
			String name = lit.getName();
			String value = lit.getValue();
			result.addLiteral(name, value);
		}
		return result;
	}
	
	public static RecordType parseRecord(DataType dt, Map<String, DataType> datatypes) {
		String name = dt.getName();
		RecordType rec = new RecordType(name);
		for(Field f: dt.getChildElementsByType(Field.class)) {
			String fname = f.getName();
			// tref is either a string representing a basic type (such as int or string) or
			// an id referencing a user defined data type. We assume the later and fall back 
			// on the former case.
			String ftype = resolveTypeRef(f.getTypeRef(), datatypes);
			RecordFieldKind fKind = RecordFieldKind.parse(f.getAttributeValueNs("http://bpmn4s", "kind"));
			Boolean fSuppress = "true".equalsIgnoreCase(f.getAttributeValueNs("http://bpmn4s", "suppressUpdate"));
			rec.addField(fname, ftype, fKind, fSuppress);
		}
		return rec;
	}
	
	public static String resolveTypeRef(String typeRef, Map<String, DataType> datatypes) {
		return datatypes.containsKey(typeRef) ? datatypes.get(typeRef).getName() : typeRef;
	}
	
	public static ListType parseList (DataType dt, Map<String, DataType> datatypes) {
		return new ListType(dt.getName(), resolveTypeRef(dt.getValueTypeRef(), datatypes));
	}
	
	public static SetType parseSet (DataType dt, Map<String, DataType> datatypes) {
		return new SetType(dt.getName(), resolveTypeRef(dt.getValueTypeRef(), datatypes));
	}
	
	public static MapType parseMap (DataType dt, Map<String, DataType> datatypes) {
		return new MapType(dt.getName(), dt.getKeyTypeRef(), resolveTypeRef(dt.getValueTypeRef(), datatypes));
	}

	public static void parseProcess(Process p, Map<String, DataType> datatypes) {
		makeActionNode(p, ElementType.COMPONENT, datatypes);
	}	
	
	public static void parseSubprocess(SubProcess sp, Map<String, DataType> datatypes) {
		String subtype = sp.getAttributeValueNs("http://bpmn4s", "subType");
		if (subtype != null && subtype.equals(SUBTYPE_COMPONENT)) {
			makeActionNode(sp, ElementType.COMPONENT, datatypes);
			parseDataAssociations(sp);
		} else {
			makeActionNode(sp, ElementType.ACTIVITY, datatypes);
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
	
	public static void makeActionNode(BaseElement elem, ElementType type, Map<String, DataType> datatypes) {
		makeActionNode(elem, type, ElementType.NONE, datatypes);
	}
	
	/**
	 * Tasks, events, gates and components are compiled into bpmn4s elements.
	 * Task elements may have a taskType such as COMPOSE or RUN, to indicate 
	 * they are part of generated tests.
	 */
	public static void makeActionNode(BaseElement elem, ElementType type, ElementType taskType, Map<String, DataType> datatypes) {
		String name = elem.getAttributeValue("name");
		String id = elem.getId();
		Element node = new Element(type, taskType, name);
		node.setId(id);
		if (elem instanceof FlowNode) {
			node.setParent(getParentId(elem));
			node.setComponent(getParentComponents(elem));
			node.setGuard(elem.getAttributeValueNs("http://bpmn4s", "guard"));
			node.setStepType(elem.getAttributeValueNs("http://bpmn4s", "stepType"));
			node.setPriority(elem.getAttributeValueNs("http://bpmn4s", "priority"));
		}
		String contextName = elem.getAttributeValueNs("http://bpmn4s", "ctxName");
		String contextInit = elem.getAttributeValueNs("http://bpmn4s", "ctxInit");
		String contextTypeId = elem.getAttributeValueNs("http://bpmn4s", "ctxTypeRef");
		String contextTypeName = "";
		if (contextTypeId != null) {
			contextTypeName = resolveTypeRef(contextTypeId, datatypes);
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
}
