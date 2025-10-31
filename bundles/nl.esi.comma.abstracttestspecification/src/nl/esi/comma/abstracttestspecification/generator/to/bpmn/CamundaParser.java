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
package nl.esi.comma.abstracttestspecification.generator.to.bpmn;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.camunda.bpm.model.bpmn.Bpmn;
import org.camunda.bpm.model.bpmn.BpmnModelInstance;
import org.camunda.bpm.model.bpmn.instance.BaseElement;
import org.camunda.bpm.model.bpmn.instance.DataAssociation;
import org.camunda.bpm.model.bpmn.instance.DataInputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataObject;
import org.camunda.bpm.model.bpmn.instance.DataObjectReference;
import org.camunda.bpm.model.bpmn.instance.DataOutputAssociation;
import org.camunda.bpm.model.bpmn.instance.Definitions;
import org.camunda.bpm.model.bpmn.instance.EndEvent;
import org.camunda.bpm.model.bpmn.instance.ExtensionElements;
import org.camunda.bpm.model.bpmn.instance.FlowNode;
import org.camunda.bpm.model.bpmn.instance.Lane;
import org.camunda.bpm.model.bpmn.instance.LaneSet;
import org.camunda.bpm.model.bpmn.instance.Process;
import org.camunda.bpm.model.bpmn.instance.Property;
import org.camunda.bpm.model.bpmn.instance.SequenceFlow;
import org.camunda.bpm.model.bpmn.instance.StartEvent;
import org.camunda.bpm.model.bpmn.instance.Task;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnDiagram;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnEdge;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnPlane;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnShape;
import org.camunda.bpm.model.bpmn.instance.dc.Bounds;
import org.camunda.bpm.model.bpmn.instance.di.Waypoint;

import nl.asml.matala.bpmn4s.extensions.Bpmn4sModel;
import nl.asml.matala.bpmn4s.extensions.DataType;
import nl.asml.matala.bpmn4s.extensions.DataTypes;
import nl.asml.matala.bpmn4s.extensions.Field;
import nl.asml.matala.product.product.Block;
import nl.asml.matala.product.product.Function;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestSequence;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep;
import nl.esi.comma.abstracttestspecification.generator.to.concrete.ConcreteExpressionHandler;
import nl.esi.comma.assertthat.assertThat.JsonValue;
import nl.esi.comma.expressions.expression.ExpressionVariable;
import nl.esi.comma.types.types.TypeDecl;

public class CamundaParser {

	final static String XMLNS_XSI = "http://www.w3.org/2001/XMLSchema-instance";
	final static String XMLNS_DI = "http://www.omg.org/spec/DD/20100524/DI";
	final static String XMLNS_DC = "http://www.omg.org/spec/DD/20100524/DC";
	final static String XMLNS_COLOR = "http://www.omg.org/spec/BPMN/non-normative/color/1.0";
	final static String XMLNS_BPMNDI = "http://www.omg.org/spec/BPMN/20100524/DI";
	final static String XMLNS_BPMN4S = "http://bpmn4s";
	final static String XMLNS_BPMN2 = "http://www.omg.org/spec/BPMN/20100524/MODEL";
	final static String XMLNS_BIOC = "http://bpmn.io/schema/bpmn/biocolor/1.0";

	private static final String BPMN4S_RUN_TASK = "RunTask";
	private static final String BPMN4S_ASSERT_TASK = "AssertTask";
	private static final String BPMN4S_COMPOSE_TASK = "ComposeTask";
	private static final String BPMN4S_SUB_TYPE = "subType";
	private static final String BPMN4S_DATATYPE_REF = "dataTypeRef";
	private static final String BPMN4S_UPDATE = "update";
	private static final String BPMN4S_QUEUE = "Queue";

	final static double OFFSET_X = 150.0;
	final static double OFFSET_Y = 50.0;
	final static double baseY = 50.0;

	public static String generateBPMNModel(AbstractTestDefinition atd) {
		List<ElementDescriptor> descriptors = createDescriptors(atd);
		BpmnModelInstance modelInstance = generateBPMNModel(descriptors);
		return Bpmn.convertToString(modelInstance);
	}

	public static List<ElementDescriptor> createDescriptors(AbstractTestDefinition atd) {
		List<ElementDescriptor> elements = new ArrayList<>();
		// 1) fetch step identifiers and split them into lane & task id
		Map<String, String> actionLane = new HashMap<>();
		Map<String, List<String>> dataSetConsumer = new HashMap<>();
		List<TaskDescriptor> tasks = new ArrayList<>();
		Map<String, List<Map.Entry<String, Binding>>> outputsMap = new HashMap<>();
		Map<String, DataInstanceDescriptor> dataInstanceMap = new HashMap<>();

		// For generating datastoresdataStore :: Add the consumer in the dataStores and
		// then remove the dataStores that do not have consumer
		for (AbstractTestSequence sys : atd.getTestSeq()) {
			for (AbstractStep step : sys.getStep()) {
				String consumerName = getConsumerName(step);
				step.getStepRef().stream().forEach(a -> {
					a.getRefData().forEach(s -> {
						s.getName();
						// check if we have it already in the map, if yes, add the consumer, if not add
						// both
						dataSetConsumer.computeIfAbsent(s.getName(), k -> new ArrayList<>()).add(consumerName);
					});
				});
			}
		}

		for (AbstractTestSequence sys : atd.getTestSeq()) {
			for (AbstractStep step : sys.getStep()) {
				Set<Binding> outputs = new HashSet<>();
				// make output
				step.getOutput().forEach(a -> {
					outputs.add(a);
				});

				// Get suppressed
				final Set<String> suppressed = (step.getSuppress() != null) ? step.getSuppress().getVarFields().stream()
						.filter(exp -> exp instanceof ExpressionVariable).map(exp -> (ExpressionVariable) exp)
						.map(vr -> vr.getVariable().getName()).collect(Collectors.toSet()) : Collections.emptySet();

				// Remove suppressed ones
				outputs.removeIf(out -> suppressed.contains(out.getName().getName()));

				// name of action/ task id
				String taskName = getConsumerName(step);

				// name of system block/lane
				String lane_name = getComponentName(step);

				// 2) create the taskDescriptor objects
				actionLane.put(taskName, lane_name);
				TaskDescriptor task = new TaskDescriptor(taskName, lane_name);
				task.step = step;
				tasks.add(task);

				// 3) derive DataInstance out of the output-data elements in each
				// run/compose-step
				outputs.forEach(output -> {
					String dataStoreName = output.getName().getName();
					// create the outputMap:: which includes dataStores, the producer and the
					// context
					Map.Entry<String, Binding> entry = Map.entry(taskName, output);
					// Add to map under DataInstance name
					outputsMap.computeIfAbsent(dataStoreName, k -> new ArrayList<>()).add(entry);
				});
			}

		}

		// create data instance and the consumers:
		for (AbstractTestSequence sys : atd.getTestSeq()) {
			for (AbstractStep step : sys.getStep()) {
				String consumerName = getConsumerName(step);
				String lane_name = getComponentName(step);
				step.getStepRef().stream().forEach(a -> {
					a.getRefData().forEach(s -> {
						String dataProducer = getConsumerName(a.getRefStep());
						String consumedData = s.getName();
						java.util.Optional<Entry<String, Binding>> matchedEntryOpt;
						if (outputsMap.containsKey(consumedData)) {

							matchedEntryOpt = outputsMap.getOrDefault(consumedData, Collections.emptyList()).stream()
									.filter(entry -> entry.getKey().equals(dataProducer)).findFirst();

							if (matchedEntryOpt.isPresent()) {
								String producerName = matchedEntryOpt.get().getKey();
								String key = consumedData + "_" + producerName;
								DataInstanceDescriptor existing = dataInstanceMap.get(key);

								if (existing != null) {
									existing.consumers.add(consumerName);
								} else {
									DataInstanceDescriptor dataInstance = new DataInstanceDescriptor(
											key,
											lane_name, producerName, 
											new ArrayList<>(List.of(consumerName)));
									dataInstance.bind_producer = matchedEntryOpt.get().getValue();
									dataInstanceMap.put(key, dataInstance);
								}
							}
						}
					});
				});
			}
		}

		// 5) Add tasks and datastores to the list in correct order
		for (TaskDescriptor task : tasks) {
			elements.add(task); // Add the task first

			// Check for datastores that have this task as their producer
			for (DataInstanceDescriptor ds : dataInstanceMap.values()) {

				if (task.id.equals(ds.producer)) {
					elements.add(ds);
				}
			}
		}
		return elements;
	}

	private static String getComponentName(AbstractStep step) {
		Function function = (Function) step.getCaseRef().eContainer();
		Block block = (Block) function.eContainer();
		int component_idx = block.getElabels().size() > 1 ? 1 : 0;

		return block.getElabels().get(component_idx);
	}

	private static String getConsumerName(AbstractStep step) {
		String caseName = step.getName().replaceAll(".*_(.*_.*)$", "$1").replace('_', ' ');
		Function function = (Function) step.getCaseRef().eContainer();
		String function_name = function.getElabels();

		return function_name + " " + caseName;
	}

	public static BpmnModelInstance generateBPMNModel(List<ElementDescriptor> elements) {
		BpmnModelInstance modelInstance = Bpmn4sModel.createEmptyModel();
		Definitions definitions = createDefinitions(modelInstance);
		Process process = createProcess(modelInstance, definitions);
		createDataTypes(modelInstance, process);
		LaneSet laneSet = createLaneSet(modelInstance, process);
		BpmnPlane plane = createDiagram(modelInstance, definitions, process);

		Map<String, Lane> laneMap = new HashMap<>();
		Map<String, Double> laneYMap = new HashMap<>();
		Map<String, Task> taskMap = new HashMap<>();
		Map<BaseElement, Bounds> elemBounds = new LinkedHashMap<>();
		double baseY = OFFSET_Y;
		double offsetX = OFFSET_X;

		createLanes(modelInstance, elements, laneSet, plane, laneMap, laneYMap, baseY);

		FlowNode previousNode = null;
		int nodeIdx = 0;
		int lastTaskIdx = 0;

		for (ElementDescriptor e : elements) {
			if (e instanceof TaskDescriptor td) {
				String taskId = td.id;
				double x = offsetX + (nodeIdx + 1) * offsetX;
				double y = laneYMap.get(td.lane) + 20.0;

				Task task = createTaskWithIO(modelInstance, process, td);
				addBpmnExtension(task, td.step);
				laneMap.get(td.lane).getFlowNodeRefs().add(task);
				taskMap.put(taskId, task);

				Bounds taskBounds = createBounds(modelInstance, x, y, 100.0, 80.0);
				elemBounds.put(task, taskBounds);
				addShapeToPlane(modelInstance, plane, task, taskBounds);

				if (nodeIdx == 0) {
					StartEvent startEvent = createStartEvent(modelInstance, process, td.lane, laneMap);
					Bounds startBounds = createBounds(modelInstance, offsetX, laneYMap.get(td.lane) + 40.0, 36.0, 36.0);
					addShapeToPlane(modelInstance, plane, startEvent, startBounds);
					createSequenceFlowWithEdge(modelInstance, process, plane, startEvent, task, "flow_start",
							startBounds, taskBounds);
				}

				if (previousNode != null) {
					Bounds prevBounds = createBounds(modelInstance, offsetX + (lastTaskIdx + 1) * offsetX + 100,
							laneYMap.get((elements.get(nodeIdx - 1)).lane) + 60, 0, 0);
					createSequenceFlowWithEdge(modelInstance, process, plane, previousNode, task,
							"flow_" + (nodeIdx - 1) + "_" + nodeIdx, prevBounds, taskBounds);
				}

				if (nodeIdx == elements.size() - 1) {
					EndEvent endEvent = createEndEvent(modelInstance, process, td.lane, laneMap);
					Bounds endBounds = createBounds(modelInstance, taskBounds.getX() + offsetX,
							taskBounds.getY() + 20.0, 36.0, 36.0);
					addShapeToPlane(modelInstance, plane, endEvent, endBounds);
					createSequenceFlowWithEdge(modelInstance, process, plane, task, endEvent, "flow_end", taskBounds,
							endBounds);
				}

				previousNode = task;
				lastTaskIdx = nodeIdx;
			}
			nodeIdx++;
		}
		nodeIdx = 0;

		for (ElementDescriptor e : elements) {
			if (e instanceof DataInstanceDescriptor ds) {
				double x = offsetX + (nodeIdx + 1) * offsetX;
				double y = laneYMap.get(ds.lane) + 36.0;
				linkDataStoreToTasks(modelInstance, definitions, process, plane, ds, taskMap, elemBounds, x, y);
			}
			nodeIdx++;
		}

		return modelInstance;
	}

	private static void addBpmnExtension(Task task, AbstractStep step) {
		if (step instanceof ComposeStep) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_COMPOSE_TASK);
		} else if (step instanceof RunStep) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_RUN_TASK);
		} else if (step instanceof AssertionStep) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_ASSERT_TASK);
		} else
			throw new IllegalArgumentException("Unexpected value: " + step);
	}

	private static void addBpmnExtension(DataAssociation da, Binding bind) {
		ConcreteExpressionHandler ceh = new ConcreteExpressionHandler();
		TypeDecl b_type = bind.getName().getType().getType();
		JsonValue b_val = bind.getJsonvals();
		String b_str = ceh.createTypeDeclValue(b_type, b_val);
		da.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_UPDATE, b_str);
	}

	private static Definitions createDefinitions(BpmnModelInstance modelInstance) {
		Definitions definitions = modelInstance.newInstance(Definitions.class);
		definitions.setTargetNamespace("http://bpmn.io/schema/bpmn");
		definitions.getDomElement().registerNamespace("xsi", XMLNS_XSI);
		definitions.getDomElement().registerNamespace("di", XMLNS_DI);
		definitions.getDomElement().registerNamespace("dc", XMLNS_DC);
		definitions.getDomElement().registerNamespace("color", XMLNS_COLOR);
		definitions.getDomElement().registerNamespace("bpmndi", XMLNS_BPMNDI);
		definitions.getDomElement().registerNamespace("bpmn4s", XMLNS_BPMN4S);
		definitions.getDomElement().registerNamespace("bpmn2", XMLNS_BPMN2);
		definitions.getDomElement().registerNamespace("bioc", XMLNS_BIOC);
		modelInstance.setDefinitions(definitions);
		return definitions;
	}

	private static void createDataTypes(BpmnModelInstance modelInstance, Process process) {
		ExtensionElements extElem = modelInstance.newInstance(ExtensionElements.class);
		DataTypes dtype_list = modelInstance.newInstance(DataTypes.class);

		DataType dt_dataset = modelInstance.newInstance(DataType.class);
		dt_dataset.setAttributeValue("id", "dataset_id");
		dt_dataset.setAttributeValue("name", "Dataset");
		dt_dataset.setAttributeValue("type", "String");

		DataType dt_list = modelInstance.newInstance(DataType.class);
		dt_list.setAttributeValue("id", "list_id");
		dt_list.setAttributeValue("name", "ListOfDatasets");
		dt_list.setAttributeValue("type", "List");
		dt_list.setAttributeValue("valueTypeRef", "dataset_id");

		DataType dt_record = modelInstance.newInstance(DataType.class);
		dt_record.setAttributeValue("id", "record_id");
		dt_record.setAttributeValue("name", "MyDataType");
		dt_record.setAttributeValue("type", "Record");

		Field field = modelInstance.newInstance(Field.class);
		field.setAttributeValue("name", "my_list_of_datasets");
		field.setAttributeValue("typeRef", "dataset_id");
		dt_record.addChildElement(field);

		dtype_list.addChildElement(dt_dataset);
		dtype_list.addChildElement(dt_list);
		dtype_list.addChildElement(dt_record);

		extElem.addChildElement(dtype_list);
		process.addChildElement(extElem);
	}

	private static Process createProcess(BpmnModelInstance modelInstance, Definitions definitions) {
		Process process = modelInstance.newInstance(Process.class);
		process.setExecutable(true);
		process.setId("BPMNProcess_id");
		process.setName("BPMNProcess");
		definitions.addChildElement(process);
		return process;
	}

	private static LaneSet createLaneSet(BpmnModelInstance modelInstance, Process process) {
		LaneSet laneSet = modelInstance.newInstance(LaneSet.class);
		laneSet.setId("LaneSet_id");
		laneSet.setName("LaneSet");
		process.addChildElement(laneSet);
		return laneSet;
	}

	private static BpmnPlane createDiagram(BpmnModelInstance modelInstance, Definitions definitions, Process process) {
		BpmnDiagram diagram = modelInstance.newInstance(BpmnDiagram.class);
		diagram.setId("BPMNDiagram_id");
		diagram.setName("BPMNDiagram");
		definitions.addChildElement(diagram);
		BpmnPlane plane = modelInstance.newInstance(BpmnPlane.class);
		plane.setId("BpmnPlane_id");
		plane.setBpmnElement(process);
		diagram.addChildElement(plane);
		return plane;
	}

	private static void createLanes(BpmnModelInstance modelInstance, List<ElementDescriptor> elements, LaneSet laneSet,
			BpmnPlane plane, Map<String, Lane> laneMap, Map<String, Double> laneYMap,
			// double laneHeight, double laneWidth,
			double baseY) {
		double laneHeight = OFFSET_Y * elements.stream().map(e -> e.lane).distinct().count();
		double laneWidth = OFFSET_X * (elements.size() + 2);

		for (ElementDescriptor e : elements) {
			if (!laneMap.containsKey(e.lane)) {
				Lane lane = modelInstance.newInstance(Lane.class);
				lane.setId("lane_" + e.lane.replaceAll("\\s+", "_"));
				lane.setName(e.lane);
				laneSet.addChildElement(lane);
				laneMap.put(e.lane, lane);

				double y = baseY + laneMap.size() * laneHeight;
				laneYMap.put(e.lane, y);

				Bounds bounds = createBounds(modelInstance, 10.0, y, laneWidth, laneHeight);
				addShapeToPlane(modelInstance, plane, lane, bounds);
			}
		}
	}

	private static Bounds createBounds(BpmnModelInstance modelInstance, double x, double y, double width,
			double height) {
		Bounds bounds = modelInstance.newInstance(Bounds.class);
		bounds.setX(x);
		bounds.setY(y);
		bounds.setWidth(width);
		bounds.setHeight(height);
		return bounds;
	}

	private static void addShapeToPlane(BpmnModelInstance modelInstance, BpmnPlane plane, BaseElement element,
			Bounds bounds) {
		BpmnShape shape = modelInstance.newInstance(BpmnShape.class);
		shape.setId(element.getId() + "_shape");
		shape.setBpmnElement(element);
		shape.setBounds(bounds);
		plane.addChildElement(shape);
	}

	private static Task createTaskWithIO(BpmnModelInstance modelInstance, Process process, TaskDescriptor td) {
		Task task = modelInstance.newInstance(Task.class);
		String task_id = normalizeTaskId(td);
		task.setId(task_id);
		task.setName(td.id);
		process.addChildElement(task);

		Property prop = modelInstance.newInstance(Property.class);
		prop.setId(task_id + "_placeholder_id");
		prop.setName(td.id + "_placeholder");
		task.addChildElement(prop);

		return task;
	}

	private static String normalizeTaskId(TaskDescriptor td) {
		return normalizeTaskId(td.id);
	}

	private static String normalizeTaskId(String td_id) {
		return td_id.replaceAll("\\s+", "_");
	}

	private static StartEvent createStartEvent(BpmnModelInstance modelInstance, Process process, String laneName,
			Map<String, Lane> laneMap) {
		StartEvent startEvent = modelInstance.newInstance(StartEvent.class);
		startEvent.setId("startEvent");
		startEvent.setName("Start");
		process.addChildElement(startEvent);
		laneMap.get(laneName).getFlowNodeRefs().add(startEvent);
		return startEvent;
	}

	private static EndEvent createEndEvent(BpmnModelInstance modelInstance, Process process, String laneName,
			Map<String, Lane> laneMap) {
		EndEvent endEvent = modelInstance.newInstance(EndEvent.class);
		endEvent.setId("endEvent");
		endEvent.setName("End");
		process.addChildElement(endEvent);
		laneMap.get(laneName).getFlowNodeRefs().add(endEvent);
		return endEvent;
	}

	private static void createSequenceFlowWithEdge(BpmnModelInstance modelInstance, Process process, BpmnPlane plane,
			FlowNode source, FlowNode target, String flowId, Bounds sourceBounds, Bounds targetBounds) {
		SequenceFlow flow = modelInstance.newInstance(SequenceFlow.class);
		flow.setId(flowId);
		flow.setSource(source);
		flow.setTarget(target);
		process.addChildElement(flow);
		source.getOutgoing().add(flow);
		target.getIncoming().add(flow);

		BpmnEdge edge = modelInstance.newInstance(BpmnEdge.class);
		edge.setId("edge_" + flowId);
		edge.setBpmnElement(flow);

		Waypoint wp1 = modelInstance.newInstance(Waypoint.class);
		wp1.setX(sourceBounds.getX() + sourceBounds.getWidth());
		wp1.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		edge.getWaypoints().add(wp1);

		double midpoint = (sourceBounds.getX() + sourceBounds.getWidth() + targetBounds.getX()) / 2;
		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		wp2.setX(midpoint);
		wp2.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		edge.getWaypoints().add(wp2);

		Waypoint wp3 = modelInstance.newInstance(Waypoint.class);
		wp3.setX(midpoint);
		wp3.setY(targetBounds.getY() + targetBounds.getHeight() / 2);
		edge.getWaypoints().add(wp3);

		Waypoint wp4 = modelInstance.newInstance(Waypoint.class);
		wp4.setX(targetBounds.getX());
		wp4.setY(targetBounds.getY() + targetBounds.getHeight() / 2);
		edge.getWaypoints().add(wp4);

		plane.addChildElement(edge);
	}

	private static DataObject linkDataStoreToTasks(BpmnModelInstance modelInstance, Definitions definitions,
			Process process, BpmnPlane plane, DataInstanceDescriptor dsDescriptor, Map<String, Task> taskMap,
			Map<BaseElement, Bounds> elemBounds, double x, double y) {

		String dsId = "dataobject_" + dsDescriptor.id.replaceAll("\\s+", "_");

		// 1️ Create top-level DataStore in definitions
		DataObject dataObject = modelInstance.newInstance(DataObject.class);
		dataObject.setId(dsId);
		dataObject.setName(dsDescriptor.id);
		process.addChildElement(dataObject);

		// 2️ Create DataObjectReference in the process
		DataObjectReference dsRef = modelInstance.newInstance(DataObjectReference.class);
		dsRef.setId(dsId + "_ref");
		dsRef.setName(normalizeTaskId(dsDescriptor.id));
		dsRef.setDataObject(dataObject);
		dsRef.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_QUEUE);
		dsRef.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_DATATYPE_REF, "record_id");

		process.addChildElement(dsRef);

		// 3️ Add diagram shape for the DataStoreReference
		BpmnShape dsShape = modelInstance.newInstance(BpmnShape.class);
		dsShape.setId("shape_" + dsId);
		dsShape.setBpmnElement(dsRef);
		Bounds dsBounds = createBounds(modelInstance, x, y, 50.0, 50.0);
		dsShape.setBounds(dsBounds);
		plane.addChildElement(dsShape);

		// 4️ Link producer task to DataStoreReference
		if (dsDescriptor.producer != null) {
			Task producer = taskMap.get(dsDescriptor.producer);
			if (producer != null) {
				DataOutputAssociation doa = modelInstance.newInstance(DataOutputAssociation.class);
				doa.setId("doa_" + dsId + "_" + producer.getId());
				doa.setTarget(dsRef);

				Binding bind = dsDescriptor.bind_producer;
				addBpmnExtension(doa, bind);
				producer.addChildElement(doa);

				Bounds producerBounds = elemBounds.get(producer);
				createDataAssociationEdge(modelInstance, plane, doa, producerBounds, dsBounds);
			}
		}

		// 5️ Link datastore to each consumer task
		Map<String, Set<String>> linked = new HashMap<>();
		for (String consumerId : dsDescriptor.consumers) {
			Task consumer = taskMap.get(consumerId);
			String dstaskLabel = dsId + "_" + consumer.getId();
			String uid =  "_" + UUID.randomUUID().toString();

			if (consumer != null) {

				// Create a Property inside the consumer task
				Property inputProp = modelInstance.newInstance(Property.class);
				inputProp.setId("prop_" + dstaskLabel + uid);
				inputProp.setName("input_" + dsDescriptor.id);
				consumer.addChildElement(inputProp);

				// Create DataInputAssociation
				DataInputAssociation dia = modelInstance.newInstance(DataInputAssociation.class);
				dia.setId("dia_" + dstaskLabel + uid);
				dia.getSources().add(dsRef);
				dia.setTarget(inputProp);

				Binding bind = dsDescriptor.bind_consumers.getOrDefault(consumer.getName(), null);
				if (bind != null) {
					addBpmnExtension(dia, bind);
				}

				consumer.addChildElement(dia);

				// Create diagram edge
				Bounds consumerBounds = elemBounds.get(consumer);
				createDataAssociationEdge(modelInstance, plane, dia, dsBounds, consumerBounds);

			}
		}

		return dataObject;
	}

	private static void createDataAssociationEdge(BpmnModelInstance modelInstance, BpmnPlane plane,
			BaseElement association, Bounds sourceBounds, Bounds targetBounds) {
		BpmnEdge edge = modelInstance.newInstance(BpmnEdge.class);
		edge.setId(association.getId() + "_edge");
		edge.setBpmnElement(association);


		Waypoint wp1 = modelInstance.newInstance(Waypoint.class);
		wp1.setX(sourceBounds.getX() + sourceBounds.getWidth());
		wp1.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		edge.getWaypoints().add(wp1);

		double midpoint = (sourceBounds.getX() + sourceBounds.getWidth() + targetBounds.getX()) / 2;

		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		wp2.setX(midpoint);
		wp2.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		edge.getWaypoints().add(wp2);

		Waypoint wp3 = modelInstance.newInstance(Waypoint.class);
		wp3.setX(midpoint);
		wp3.setY(targetBounds.getY() + targetBounds.getHeight() / 2);
		edge.getWaypoints().add(wp3);

		Waypoint wp4 = modelInstance.newInstance(Waypoint.class);
		wp4.setX(targetBounds.getX());
		wp4.setY(targetBounds.getY() + targetBounds.getHeight() / 2);
		edge.getWaypoints().add(wp4);

		plane.addChildElement(edge);
	}


}