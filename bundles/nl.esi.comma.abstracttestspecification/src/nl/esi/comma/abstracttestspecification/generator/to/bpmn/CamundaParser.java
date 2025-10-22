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

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
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
import org.camunda.bpm.model.bpmn.instance.DataStore;
import org.camunda.bpm.model.bpmn.instance.DataStoreReference;
import org.camunda.bpm.model.bpmn.instance.Definitions;
import org.camunda.bpm.model.bpmn.instance.EndEvent;
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
import org.camunda.bpm.model.xml.instance.ModelElementInstance;

import com.google.common.base.Optional;

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
	private static final String BPMN4S_UPDATE = "update";

	final static double OFFSET_X = 150.0;
	final static double OFFSET_Y = 50.0;
	final static double baseY = 50.0;

	public static void main(String[] args) {
		try {
			File f = new File("test.bpmn");
			FileWriter fw = new FileWriter(f);

			List<ElementDescriptor> descriptors = createDescriptors();

			for (int i = 0; i < descriptors.size(); i++) {
				ElementDescriptor e = descriptors.get(i);
				if (e instanceof TaskDescriptor) {	
				} else if (e instanceof DataInstanceDescriptor) {
					DataInstanceDescriptor ds = (DataInstanceDescriptor) e;					
				}
			}

			BpmnModelInstance modelInstance = generateBPMNModel(descriptors);
			fw.write(Bpmn.convertToString(modelInstance));
			fw.close();

		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public static List<ElementDescriptor> createDescriptors() {
		List<ElementDescriptor> elements = new ArrayList<>();

		// Create 10 tasks
		List<TaskDescriptor> tasks = new ArrayList<>();
		for (int i = 1; i <= 15; i++) {
			tasks.add(new TaskDescriptor("task" + i, "lane" + ((i % 3) + 1)));
		}

		// Create datastores and insert them after their producer
		DataInstanceDescriptor ds1 = new DataInstanceDescriptor("datastore1", "lane2", tasks.get(0).id,
				Arrays.asList(tasks.get(1).id, tasks.get(2).id));

		DataInstanceDescriptor ds2 = new DataInstanceDescriptor("datastore2", "lane1", tasks.get(2).id,
				Arrays.asList(tasks.get(4).id, tasks.get(5).id, tasks.get(6).id));

		DataInstanceDescriptor ds3 = new DataInstanceDescriptor("datastore3", "lane3", tasks.get(7).id,
				Arrays.asList(tasks.get(8).id, tasks.get(9).id));

		DataInstanceDescriptor ds4 = new DataInstanceDescriptor("datastore4", "lane3", tasks.get(7).id,
				Arrays.asList());
		// 3️ Add tasks and datastores to the list in correct order
		for (int i = 0; i < tasks.size(); i++) {
			elements.add(tasks.get(i));

			// Insert datastore after its producer
			if (tasks.get(i).id.equals(ds1.producer)) {
				elements.add(ds1);
			}
			if (tasks.get(i).id.equals(ds2.producer)) {
				elements.add(ds2);
			}
			if (tasks.get(i).id.equals(ds3.producer)) {
				elements.add(ds3);
			}
			if (tasks.get(i).id.equals(ds4.producer)) {
				elements.add(ds4);
			}
		}

		return elements;
	}

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
		Map<String, DataInstanceDescriptor> datastoreMap = new HashMap<>();
		List<TaskDescriptor> tasks = new ArrayList<>();
		Map<String, List<Map.Entry<String, Binding>>> outputsMap = new HashMap<>();
		Map<String, DataInstanceDescriptor> dataInstanceMap = new HashMap<>();
		
		
		// For generating datastoresdataStore :: Add the consumer in the dataStores and
		// then remove the dataStores that do not have consumer
		for (AbstractTestSequence sys : atd.getTestSeq()) {
			for (AbstractStep step : sys.getStep()) {
				String caseName = step.getName().replaceAll(".*_(.*_.*)$", "$1");
				Function function = (Function) step.getCaseRef().eContainer();
				String consumerName = function.getName() + "_" + caseName;

				step.getStepRef().stream().forEach(a ->{ 				
					a.getRefData().forEach(s-> {s.getName();
							//check if we have it already in the map, if yes, add the consumer, if not add both
							dataSetConsumer.computeIfAbsent(s.getName(), k -> new ArrayList<>()).add(consumerName);
							}
						);					
					}
				);
			}
		}


		for (AbstractTestSequence sys : atd.getTestSeq()) {
			for (AbstractStep step : sys.getStep()) {				
				String caseName = step.getName().replaceAll(".*_(.*_.*)$", "$1");
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
				Function function = (Function) step.getCaseRef().eContainer();

				// name of system block/lane
				Block block = (Block) function.eContainer();
				String taskName = function.getName() + "_" + caseName;

				// 2) create the taskDescriptor objects
				actionLane.put(taskName, block.getName());
				TaskDescriptor task = new TaskDescriptor(taskName, block.getName());
				task.step = step; 
				tasks.add(task);

				// 3) derive datastores out of the output-data elements in each run/compose-step
				outputs.forEach(output -> {
					String dataStoreName = output.getName().getName();					
					// create the outputMap:: which includes dataStores, the producer and the
					// context
					Map.Entry<String, Binding> entry = Map.entry(taskName, output);
					// Add to map under datastore name
					outputsMap.computeIfAbsent(dataStoreName, k -> new ArrayList<>()).add(entry);
				});
			}

		}
		
		// create data instance and the consumers:
		for (AbstractTestSequence sys : atd.getTestSeq()) {
			for (AbstractStep step : sys.getStep()) {
				String caseName = step.getName().replaceAll(".*_(.*_.*)$", "$1");
				Function function = (Function) step.getCaseRef().eContainer();
				String consumerName = function.getName() + "_" + caseName;
				Block block = (Block) function.eContainer();
				step.getStepRef().stream().forEach(a -> {
					a.getRefData().forEach(s -> {
						String dataProducer = a.getRefStep().getName().replaceFirst("^[^_]*_", "");
						String consumedData = s.getName();
						java.util.Optional<Entry<String, Binding>> matchedEntryOpt ;
						if (outputsMap.containsKey(consumedData)) {
							
							matchedEntryOpt = outputsMap.getOrDefault(consumedData, Collections.emptyList()).stream()
									.filter(entry -> entry.getKey().equals(dataProducer)).findFirst();

							if (matchedEntryOpt != null) {
								String producerName = matchedEntryOpt.get().getKey();								
								String key = consumedData + "_" + producerName;
								DataInstanceDescriptor existing = dataInstanceMap.get(key);

								if (existing != null) {
									existing.consumers.add(consumerName);
								} else {
									DataInstanceDescriptor dataInstance = new DataInstanceDescriptor(
											key, block.getName(),producerName,
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

	public static BpmnModelInstance generateBPMNModel(List<ElementDescriptor> elements) {
		BpmnModelInstance modelInstance = Bpmn.createEmptyModel();
		Definitions definitions = createDefinitions(modelInstance);
		createDataTypes(modelInstance, definitions);
		Process process = createProcess(modelInstance, definitions);
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

				Task task = createTaskWithIO(modelInstance, process, taskId, td.id);
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
					Bounds prevBounds = elemBounds.get(previousNode);
					if (prevBounds == null) {
						prevBounds = createBounds(modelInstance, offsetX, laneYMap.get(td.lane) + 60, 100.0, 80.0);
					}
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
		
		Map<String, Integer> producerDataCount = new HashMap<>();

		Map<DataInstanceDescriptor, Bounds> dataBoundsMap = new LinkedHashMap<>();

		for (ElementDescriptor e : elements) {
			if (e instanceof DataInstanceDescriptor ds) {
				double x, y;

				if (ds.producer != null && taskMap.containsKey(ds.producer)) {
					Task producer = taskMap.get(ds.producer);
					Bounds taskBounds = elemBounds.get(producer);
					int count = producerDataCount.getOrDefault(ds.producer, 0);

					x = taskBounds.getX() + (taskBounds.getWidth() / 2) - 25;
					y = taskBounds.getY() + taskBounds.getHeight() + 40 + (count * 60.0);

					producerDataCount.put(ds.producer, count + 1);
				} else {
					x = offsetX + nodeIdx * offsetX;
					y = laneYMap.get(ds.lane) + 36.0;
				}

				// Create shape without connection
				Bounds objBounds = createBounds(modelInstance, x, y, 50.0, 50.0);
				dataBoundsMap.put(ds, objBounds);
			}
			nodeIdx++;
		}
		for (var entry : dataBoundsMap.entrySet()) {
			DataInstanceDescriptor ds = entry.getKey();
			Bounds objBounds = entry.getValue();
			linkDataInstanceToTasks(modelInstance, definitions, process, plane, ds, taskMap, elemBounds,
					objBounds.getX(), objBounds.getY());
		}

		return modelInstance;
	}
	private void addEdgeWithWaypoints(BpmnModelInstance modelInstance, BpmnPlane plane, String edgeId, BaseElement flow,
			Bounds sourceBounds, Bounds targetBounds, boolean isDataAssociation) {

		BpmnEdge edge = modelInstance.newInstance(BpmnEdge.class);
		edge.setBpmnElement(flow);
		edge.setId(edgeId);

		double sourceX = sourceBounds.getX();
		double sourceY = sourceBounds.getY();
		double sourceWidth = sourceBounds.getWidth();
		double sourceHeight = sourceBounds.getHeight();

		double targetX = targetBounds.getX();
		double targetY = targetBounds.getY();
		double targetWidth = targetBounds.getWidth();
		double targetHeight = targetBounds.getHeight();

		// Compute center Y
		double y = (sourceY + sourceHeight / 2 + targetY + targetHeight / 2) / 2;

		// Default direction
		double startX = sourceX + sourceWidth;
		double endX = targetX;

		// Reverse if target is to the left of source
		if (endX < startX) {
			double tmp = startX;
			startX = sourceX; 
			endX = targetX + targetWidth; 
		}

		// For data association, often draw vertically (below task)
		if (isDataAssociation) {
			startX = sourceX + sourceWidth / 2;
			endX = targetX + targetWidth / 2;

			if (targetY > sourceY) { 
				y = sourceY + sourceHeight + 20;
			} else {
				y = sourceY - 20;
			}
		}

		// Define waypoints
		Waypoint wp1 = modelInstance.newInstance(Waypoint.class);
		wp1.setX(startX);
		wp1.setY(y);

		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		wp2.setX(endX);
		wp2.setY(y);

		edge.getWaypoints().add(wp1);
		edge.getWaypoints().add(wp2);

		plane.getDiagramElements().add(edge);
	}
	private static void addBpmnExtension(Task task, AbstractStep step) {
		if(step instanceof ComposeStep) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_COMPOSE_TASK);
		} else if(step instanceof RunStep) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_RUN_TASK);
		} else if(step instanceof AssertionStep) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_ASSERT_TASK);
		} else throw new IllegalArgumentException("Unexpected value: " + step);
	}

	private static void addBpmnExtension(DataAssociation da, Binding bind) {
		ConcreteExpressionHandler ceh = new ConcreteExpressionHandler();
		TypeDecl b_type = bind.getName().getType().getType();
		JsonValue b_val = bind.getJsonvals();
		String b_str = ceh.createTypeDeclValue(b_type,b_val);
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

	private static void createDataTypes(BpmnModelInstance modelInstance, Definitions definitions) {
		// TODO
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

	private static Task createTaskWithIO(BpmnModelInstance modelInstance, Process process, String id, String name) {
		Task task = modelInstance.newInstance(Task.class);
		task.setId(id);
		task.setName(name);
		process.addChildElement(task);

		Property prop = modelInstance.newInstance(Property.class);
		prop.setId(name + "_placeholder_id");
		prop.setName(name + "_placeholder");
		task.addChildElement(prop);

		return task;
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

	private static DataObject linkDataInstanceToTasks(BpmnModelInstance modelInstance, Definitions definitions,
			Process process, BpmnPlane plane, DataInstanceDescriptor dsDescriptor, Map<String, Task> taskMap,
			Map<BaseElement, Bounds> elemBounds, double x, double y) {

		String dsId = "dataobject_" + dsDescriptor.id.replaceAll("\\s+", "_");

		// 1️ Create top-level DataStore in definitions
		DataObject dataObject = modelInstance.newInstance(DataObject.class);
		dataObject.setId(dsId);
		dataObject.setName(dsDescriptor.id);
		process.addChildElement(dataObject);
		
		// 2️ Create DataStoreReference in the process
		DataObjectReference dsRef = modelInstance.newInstance(DataObjectReference.class);
		dsRef.setId(dsId + "_ref");
		dsRef.setName(dsDescriptor.id); 
		dsRef.setDataObject(dataObject);
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
				// Count total outputs from this producer
				int outputIndex = getOutputIndex(producer, doa);
				int totalOutputs = countTotalOutputs(producer);
				int totalInputs = countTotalInputs(producer);				
				createDataAssociationEdge(modelInstance, plane, doa, producerBounds, dsBounds, outputIndex,
						totalOutputs, 0, 1, totalOutputs, totalInputs);
			}
		}

		// Link DataObjectReference to each consumer task (input)		
		for (int consumerIdx = 0; consumerIdx < dsDescriptor.consumers.size(); consumerIdx++) {
			String consumerId = dsDescriptor.consumers.get(consumerIdx);
			Task consumer = taskMap.get(consumerId);
			String dstaskLabel = dsId + "_" + consumerId;
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
				int inputIndex = getInputIndex(consumer, dia);
				int totalInputs = countTotalInputs(consumer);
				int totalOutputs = countTotalOutputs(consumer);				
				int dataObjOutputIndex = consumerIdx; 
				int totalDataObjOutputs = dsDescriptor.consumers.size(); 
				createDataAssociationEdge(modelInstance, plane, dia, dsBounds, consumerBounds, inputIndex, totalInputs,
						dataObjOutputIndex, totalDataObjOutputs, totalOutputs, totalInputs);
			}
		}

		return dataObject;
	}

	private static void createDataAssociationEdge(BpmnModelInstance modelInstance, BpmnPlane plane,
			BaseElement association, Bounds sourceBounds, Bounds targetBounds, int targetConnectionIndex,
			int totalTargetConnections, int sourceConnectionIndex, int totalSourceConnections, int totalSourceOutputs,
			int totalTargetInputs) {
		BpmnEdge edge = modelInstance.newInstance(BpmnEdge.class);
		edge.setId(association.getId() + "_edge");
		edge.setBpmnElement(association);

		
		double sourceRightX = sourceBounds.getX() + sourceBounds.getWidth();
		double sourceBottomY = sourceBounds.getY() + sourceBounds.getHeight();
		double sourceWidth = sourceBounds.getWidth();

		double targetTopY = targetBounds.getY();
		double targetBottomY = targetBounds.getY() + targetBounds.getHeight();
		double targetWidth = targetBounds.getWidth();
		
		Waypoint wp1 = modelInstance.newInstance(Waypoint.class);
		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		Waypoint wp3 = modelInstance.newInstance(Waypoint.class);
		Waypoint wp4 = modelInstance.newInstance(Waypoint.class);

		boolean isTaskOutput = sourceBounds.getHeight() > 50;

		if (isTaskOutput) {

			// Decide if we need to split the edge: split if task has BOTH inputs and
			// outputs
			int totalTaskInputs = totalTargetInputs;
			boolean taskHasBothInputsAndOutputs = (totalSourceOutputs > 0 && totalTaskInputs > 0);

			double offsetX;
			if (taskHasBothInputsAndOutputs) {
				// Split: outputs use LEFT half
				offsetX = calculateHorizontalOffsetInRegion(sourceConnectionIndex, totalSourceConnections, sourceWidth,
						0.0, 0.45);
			} else {
				// No split: use full width
				offsetX = calculateHorizontalOffset(sourceConnectionIndex, totalSourceConnections, sourceWidth);
			}
			double outputX = sourceBounds.getX() + offsetX;

			// Distribute arrival points on top edge of DataObject
			double targetOffsetX = calculateHorizontalOffset(targetConnectionIndex, totalTargetConnections,
					targetWidth);
			double arrivalX = targetBounds.getX() + targetOffsetX;

			wp1.setX(outputX);
			wp1.setY(sourceBottomY);

			wp2.setX(outputX);
			wp2.setY(sourceBottomY + 20 + (sourceConnectionIndex * 10));

			wp3.setX(arrivalX);
			wp3.setY(wp2.getY());

			wp4.setX(arrivalX);
			wp4.setY(targetTopY - 1);
		} else {

			double sourceOffsetY = calculateVerticalOffset(sourceConnectionIndex, totalSourceConnections,
					sourceBounds.getHeight());
			double exitY = sourceBounds.getY() + sourceOffsetY;

			// Decide if we need to split the edge: split if task has BOTH inputs and
			// outputs
			int totalTaskOutputs = totalSourceOutputs;
			boolean taskHasBothInputsAndOutputs = (totalTargetInputs > 0 && totalTaskOutputs > 0);

			double offsetX;
			if (taskHasBothInputsAndOutputs) {
				// Split: inputs use RIGHT half
				offsetX = calculateHorizontalOffsetInRegion(targetConnectionIndex, totalTargetConnections, targetWidth,
						0.55, 1.0);
			} else {
				// No split: use full width
				offsetX = calculateHorizontalOffset(targetConnectionIndex, totalTargetConnections, targetWidth);
			}
			double inputX = targetBounds.getX() + offsetX;

			double horizontalOffset = 20 + (sourceConnectionIndex * 15);

			wp1.setX(sourceRightX);
			wp1.setY(exitY);

			wp2.setX(sourceRightX + horizontalOffset);
			wp2.setY(exitY);

			wp3.setX(sourceRightX + horizontalOffset);
			wp3.setY(targetBottomY + 30 + (targetConnectionIndex * 10));

			wp4.setX(inputX);
			wp4.setY(targetBottomY + 30 + (targetConnectionIndex * 10));

			Waypoint wp5 = modelInstance.newInstance(Waypoint.class);
			wp5.setX(inputX);
			wp5.setY(targetBottomY - 1);

			edge.getWaypoints().addAll(Arrays.asList(wp1, wp2, wp3, wp4, wp5));
			plane.addChildElement(edge);
			return;
		}

		edge.getWaypoints().addAll(Arrays.asList(wp1, wp2, wp3, wp4));

		plane.addChildElement(edge);
	}

	//Count total outputs from a task
	private static int countTotalOutputs(Task task) {
		int count = task.getChildElementsByType(DataOutputAssociation.class).size();
		return Math.max(1, count); 
	}
	
	//Count total inputs to a task
	private static int countTotalInputs(Task task) {
		int count = task.getChildElementsByType(DataInputAssociation.class).size();
		return Math.max(1, count);
	}
	//Get the index of a specific output association
	private static int getOutputIndex(Task task, DataOutputAssociation targetAssociation) {
		int index = 0;
		for (ModelElementInstance element : task.getChildElementsByType(DataOutputAssociation.class)) {
			if (element.equals(targetAssociation)) {
				return index;
			}
			index++;
		}
		return 0;
	}
	//Get the index of a specific input association
	private static int getInputIndex(Task task, DataInputAssociation targetAssociation) {
		int index = 0;
		for (ModelElementInstance element : task.getChildElementsByType(DataInputAssociation.class)) {
			if (element.equals(targetAssociation)) {
				return index;
			}
			index++;
		}
		return 0;
	}
	// Distribute connections evenly along a horizontal edge
	private static double calculateHorizontalOffset(int index, int total, double width) {
		if (total == 1) {
			return width / 2.0;
		}

		double usableWidth = width * 0.6;
		double margin = width * 0.2;
		double spacing = usableWidth / (total - 1);

		return margin + (index * spacing);
	}
	
	private static double calculateHorizontalOffsetInRegion(int index, int total, double width, double regionStart,
			double regionEnd) {
		double regionWidth = width * (regionEnd - regionStart);
		double regionOffset = width * regionStart;

		if (total == 1) {
			return regionOffset + regionWidth / 2.0;
		}

		double usableWidth = regionWidth * 0.8;
		double margin = regionWidth * 0.1;
		double spacing = usableWidth / (total - 1);

		return regionOffset + margin + (index * spacing);
	}
	//Distribute connections evenly along a vertical edge
	private static double calculateVerticalOffset(int index, int total, double height) {
		if (total == 1) {
			return height / 2.0;
		}

		// Leave 20% margin on top and bottom, distribute in the middle 60%
		double usableHeight = height * 0.6;
		double margin = height * 0.2;
		double spacing = usableHeight / (total - 1);

		return margin + (index * spacing);
	}
}