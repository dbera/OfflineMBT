package nl.esi.comma.abstracttestspecification.generator.to.bpmn;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.camunda.bpm.model.bpmn.Bpmn;
import org.camunda.bpm.model.bpmn.BpmnModelInstance;
import org.camunda.bpm.model.bpmn.instance.BaseElement;
import org.camunda.bpm.model.bpmn.instance.DataInput;
import org.camunda.bpm.model.bpmn.instance.DataInputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataOutput;
import org.camunda.bpm.model.bpmn.instance.DataOutputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataStore;
import org.camunda.bpm.model.bpmn.instance.DataStoreReference;
import org.camunda.bpm.model.bpmn.instance.Definitions;
import org.camunda.bpm.model.bpmn.instance.EndEvent;
import org.camunda.bpm.model.bpmn.instance.FlowNode;
import org.camunda.bpm.model.bpmn.instance.InputSet;
import org.camunda.bpm.model.bpmn.instance.IoSpecification;
import org.camunda.bpm.model.bpmn.instance.Lane;
import org.camunda.bpm.model.bpmn.instance.LaneSet;
import org.camunda.bpm.model.bpmn.instance.OutputSet;
import org.camunda.bpm.model.bpmn.instance.Process;
import org.camunda.bpm.model.bpmn.instance.SequenceFlow;
import org.camunda.bpm.model.bpmn.instance.StartEvent;
import org.camunda.bpm.model.bpmn.instance.Task;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnDiagram;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnEdge;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnPlane;
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnShape;
import org.camunda.bpm.model.bpmn.instance.dc.Bounds;
import org.camunda.bpm.model.bpmn.instance.di.Waypoint;

public class MainCamunda {

	final static String XMLNS_XSI = "http://www.w3.org/2001/XMLSchema-instance";
	final static String XMLNS_DI = "http://www.omg.org/spec/DD/20100524/DI";
	final static String XMLNS_DC = "http://www.omg.org/spec/DD/20100524/DC";
	final static String XMLNS_COLOR = "http://www.omg.org/spec/BPMN/non-normative/color/1.0";
	final static String XMLNS_BPMNDI = "http://www.omg.org/spec/BPMN/20100524/DI";
	final static String XMLNS_BPMN4S = "http://bpmn4s";
	final static String XMLNS_BPMN2 = "http://www.omg.org/spec/BPMN/20100524/MODEL";
	final static String XMLNS_BIOC = "http://bpmn.io/schema/bpmn/biocolor/1.0";

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
				System.out.print("Index " + i + ": ");
				if (e instanceof TaskDescriptor) {
					System.out.println("Task - ID: " + e.id + ", Lane: " + e.lane);
				} else if (e instanceof DatastoreDescriptor) {
					DatastoreDescriptor ds = (DatastoreDescriptor) e;
					System.out.println("Datastore - ID: " + ds.id + ", Lane: " + ds.lane + ", Producer: " + ds.producer
							+ ", Consumers: " + ds.consumers);
				}
			}

			BpmnModelInstance modelInstance = generateBPMNModel(descriptors);
			fw.write(Bpmn.convertToString(modelInstance));
			fw.close();

		} catch (

		IOException e) {
			// TODO Auto-generated catch block
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
		DatastoreDescriptor ds1 = new DatastoreDescriptor("datastore1", "lane2", tasks.get(0).id,
				Arrays.asList(tasks.get(1).id, tasks.get(2).id));

		DatastoreDescriptor ds2 = new DatastoreDescriptor("datastore2", "lane1", tasks.get(2).id,
				Arrays.asList(tasks.get(4).id, tasks.get(5).id, tasks.get(6).id));

		DatastoreDescriptor ds3 = new DatastoreDescriptor("datastore3", "lane3", tasks.get(7).id,
				Arrays.asList(tasks.get(8).id, tasks.get(9).id));

		// Add tasks and datastores to the list in correct order
		for (int i = 0; i < tasks.size(); i++) {
			elements.add(tasks.get(i));

			// Insert datastore after its producer
			if (tasks.get(i).id.equals(ds1.producer)) {
				elements.add(ds1);
			} else if (tasks.get(i).id.equals(ds2.producer)) {
				elements.add(ds2);
			} else if (tasks.get(i).id.equals(ds3.producer)) {
				elements.add(ds3);
			}
		}

		return elements;
	}

	public static BpmnModelInstance generateBPMNModel(List<ElementDescriptor> elements) {
		BpmnModelInstance modelInstance = Bpmn.createEmptyModel();
		Definitions definitions = createDefinitions(modelInstance);
		Process process = createProcess(modelInstance, definitions);
		LaneSet laneSet = createLaneSet(modelInstance, process);
		BpmnPlane plane = createDiagram(modelInstance, definitions, process);

		Map<String, Lane> laneMap = new HashMap<>();
		Map<String, Double> laneYMap = new HashMap<>();
		Map<String, Task> taskMap = new HashMap<>();
		Map<BaseElement, Bounds> elemBounds = new LinkedHashMap<>();
		double baseY = 50.0;
		double offsetX = 150.0;

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
			if (e instanceof DatastoreDescriptor ds) {
				double x = offsetX + (nodeIdx + 1) * offsetX;
				double y = laneYMap.get(ds.lane) + 36.0;
				linkDataStoreToTasks(modelInstance, definitions, process, plane, ds, taskMap, elemBounds, x, y);
			}
			nodeIdx++;
		}

		return modelInstance;
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

	private static Process createProcess(BpmnModelInstance modelInstance, Definitions definitions) {
		Process process = modelInstance.newInstance(Process.class);
		process.setId("laneProcess");
		definitions.addChildElement(process);
		return process;
	}

	private static LaneSet createLaneSet(BpmnModelInstance modelInstance, Process process) {
		LaneSet laneSet = modelInstance.newInstance(LaneSet.class);
		laneSet.setId("laneSet");
		process.addChildElement(laneSet);
		return laneSet;
	}

	private static BpmnPlane createDiagram(BpmnModelInstance modelInstance, Definitions definitions, Process process) {
		BpmnDiagram diagram = modelInstance.newInstance(BpmnDiagram.class);
		diagram.setId("BPMNDiagram_1");
		definitions.addChildElement(diagram);
		BpmnPlane plane = modelInstance.newInstance(BpmnPlane.class);
		plane.setBpmnElement(process);
		diagram.addChildElement(plane);
		return plane;
	}

	private static void createLanes(BpmnModelInstance modelInstance, List<ElementDescriptor> elements, LaneSet laneSet,
			BpmnPlane plane, Map<String, Lane> laneMap, Map<String, Double> laneYMap,
			// double laneHeight, double laneWidth,
			double baseY) {
		double laneHeight = 50.0 * elements.stream().map(e -> e.lane).distinct().count();
		double laneWidth = 150 * (elements.size() + 2);

		for (ElementDescriptor e : elements) {
			if (!laneMap.containsKey(e.lane)) {
				Lane lane = modelInstance.newInstance(Lane.class);
				lane.setId("lane_" + e.lane.replaceAll("\\s+", "_"));
				lane.setName(e.lane);
				laneSet.addChildElement(lane);
				laneMap.put(e.lane, lane);

				double y = baseY + laneMap.size() * laneHeight;
				laneYMap.put(e.lane, y);

				Bounds bounds = createBounds(modelInstance, 100.0, y, laneWidth, laneHeight);
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

		IoSpecification ioSpec = modelInstance.newInstance(IoSpecification.class);
		task.setIoSpecification(ioSpec);

		DataOutput dataOutput = modelInstance.newInstance(DataOutput.class);
		dataOutput.setId(id + "_output");
		dataOutput.setName("output_" + id);
		ioSpec.getDataOutputs().add(dataOutput);

		OutputSet outputSet = modelInstance.newInstance(OutputSet.class);
		ioSpec.getOutputSets().add(outputSet);
		outputSet.getDataOutputRefs().add(dataOutput);

		DataInput dataInput = modelInstance.newInstance(DataInput.class);
		dataInput.setId(id + "_input");
		dataInput.setName("input_" + id);
		ioSpec.getDataInputs().add(dataInput);

		InputSet inputSet = modelInstance.newInstance(InputSet.class);
		ioSpec.getInputSets().add(inputSet);
		inputSet.getDataInputs().add(dataInput);

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
		

		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		Waypoint wp3 = modelInstance.newInstance(Waypoint.class);

		double midpoint = (sourceBounds.getX() + sourceBounds.getWidth() + targetBounds.getX())/2;
		wp2.setX(midpoint);
		wp2.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		wp3.setX(midpoint);
		wp3.setY(targetBounds.getY() + targetBounds.getHeight() / 2);

		Waypoint wp4 = modelInstance.newInstance(Waypoint.class);
		wp4.setX(targetBounds.getX());
		wp4.setY(targetBounds.getY() + targetBounds.getHeight() / 2);

		edge.getWaypoints().add(wp1);
		edge.getWaypoints().add(wp2);
		edge.getWaypoints().add(wp3);
		edge.getWaypoints().add(wp4);
		plane.addChildElement(edge);
	}

	private static DataStore linkDataStoreToTasks(BpmnModelInstance modelInstance, Definitions definitions,
			Process process, BpmnPlane plane, DatastoreDescriptor dsDescriptor, Map<String, Task> taskMap,
			Map<BaseElement, Bounds> elemBounds, double x, double y) {
		String dsId = "datastore_" + dsDescriptor.id.replaceAll("\\s+", "_");

		DataStore dataStore = modelInstance.newInstance(DataStore.class);
		dataStore.setId(dsId);
		dataStore.setName(dsDescriptor.id);
		definitions.addChildElement(dataStore);

		DataStoreReference dsRef = modelInstance.newInstance(DataStoreReference.class);
		dsRef.setId(dsId + "_ref");
		dsRef.setDataStore(dataStore);
		dsRef.setName(dsDescriptor.id);
		process.addChildElement(dsRef);

		BpmnShape dsShape = modelInstance.newInstance(BpmnShape.class);
		dsShape.setId(dsId + "_shape");
		dsShape.setBpmnElement(dsRef);
		Bounds dsBounds = createBounds(modelInstance, x, y, 50.0, 50.0);
		dsShape.setBounds(dsBounds);
		plane.addChildElement(dsShape);

		// Link producer to datastore
		Task producer = taskMap.get(dsDescriptor.producer);

		if (producer != null && producer.getIoSpecification() != null) {
			DataOutputAssociation doa = modelInstance.newInstance(DataOutputAssociation.class);
			doa.setId(producer.getId() + "_doa");
			doa.getSources().add(producer.getIoSpecification().getDataOutputs().iterator().next());
			doa.setTarget(dsRef);
			producer.addChildElement(doa);

			Bounds producerBounds = elemBounds.get(producer);
			createDataAssociationEdge(modelInstance, plane, doa, producerBounds, dsBounds);

		}

		// Link datastore to consumers
		for (String consumerId : dsDescriptor.consumers) {
			Task consumer = taskMap.get(consumerId);
			if (consumer != null && consumer.getIoSpecification() != null) {
				DataInputAssociation dia = modelInstance.newInstance(DataInputAssociation.class);
				dia.setId(consumer.getId() + "_dia");
				dia.setTarget(consumer.getIoSpecification().getDataInputs().iterator().next());
				dia.getSources().add(dsRef);
				consumer.addChildElement(dia);

				Bounds consumerBounds = elemBounds.get(consumer);
				createDataAssociationEdge(modelInstance, plane, dia, dsBounds, consumerBounds);

			}
		}
		return dataStore;
	}

	private static void createDataAssociationEdge(BpmnModelInstance modelInstance, BpmnPlane plane,
			BaseElement association, Bounds sourceBounds, Bounds targetBounds) {
		BpmnEdge edge = modelInstance.newInstance(BpmnEdge.class);
		edge.setBpmnElement(association);

		Waypoint wp1 = modelInstance.newInstance(Waypoint.class);
		wp1.setX(sourceBounds.getX() + sourceBounds.getWidth());
		wp1.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		
		double midpoint = (sourceBounds.getX() + sourceBounds.getWidth() + targetBounds.getX())/2;

		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		wp2.setX(midpoint);
		wp2.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);

		Waypoint wp3 = modelInstance.newInstance(Waypoint.class);
		wp3.setX(midpoint);
		wp3.setY(targetBounds.getY() + targetBounds.getHeight() / 2);

		Waypoint wp4 = modelInstance.newInstance(Waypoint.class);
		wp4.setX(targetBounds.getX());
		wp4.setY(targetBounds.getY() + targetBounds.getHeight() / 2);

		edge.getWaypoints().add(wp1);
		edge.getWaypoints().add(wp2);
		edge.getWaypoints().add(wp3);
		edge.getWaypoints().add(wp4);
		plane.addChildElement(edge);
	}

}