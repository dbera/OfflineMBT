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
package nl.asml.matala.generator.bpmn;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.camunda.bpm.model.bpmn.Bpmn;
import org.camunda.bpm.model.bpmn.BpmnModelInstance;
import org.camunda.bpm.model.bpmn.instance.BaseElement;
import org.camunda.bpm.model.bpmn.instance.DataAssociation;
import org.camunda.bpm.model.bpmn.instance.DataInputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataOutputAssociation;
import org.camunda.bpm.model.bpmn.instance.DataStoreReference;
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
import org.camunda.bpm.model.xml.instance.ModelElementInstance;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;

import nl.asml.matala.bpmn4s.extensions.Bpmn4sModel;
import nl.asml.matala.bpmn4s.extensions.DataTypes;
import nl.asml.matala.bpmn4s.extensions.Raw;
import nl.asml.matala.product.product.Block;
import nl.asml.matala.product.product.Function;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestSequence;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain;
import nl.esi.comma.abstracttestspecification.generator.utils.Utils;
import nl.esi.comma.assertthat.assertThat.DataAssertionItem;
import nl.esi.comma.assertthat.assertThat.JsonValue;
import nl.esi.comma.testspecification.testspecification.TestDefinition;
import nl.esi.xtext.common.lang.utilities.EcoreUtil3;
import nl.esi.xtext.expressions.expression.ExpressionVariable;
import nl.esi.xtext.types.types.TypeDecl;
import nl.esi.xtext.types.types.TypesModel;

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
	private static final String BPMN4S_STEP_TYPE = "stepType";
	private static final String BPMN4S_DATATYPE_REF = "dataTypeRef";
	private static final String BPMN4S_UPDATE = "update";
	private static final String BPMN4S_ASSERTIONS = "assertions";
	private static final String BPMN4S_INIT = "init";
	private static final String BPMN4S_PERSISTENT_READ = "persistentRead";

	// BPMN DI layout constants. Keep them together so the generated diagram can
	// be tuned without changing the semantic model construction.

	// Horizontal padding between the diagram boundary and the first/last flow
	// elements. Increasing this creates more space around start and end events.
	private static final double DIAGRAM_MARGIN_X = 50.0;

	// Vertical offset between the diagram origin and the top of the first
	// swimlane. Increasing this moves the complete process diagram downward.
	private static final double DIAGRAM_MARGIN_Y = 40.0;

	// Height allocated to each swimlane. Increasing this adds vertical space
	// around tasks and datastores and increases the distance between lanes.
	private static final double LANE_HEIGHT = 300.0;

	// Width of each generated task shape. Increasing this makes task labels
	// easier to read but reduces the free horizontal space between tasks.
	private static final double TASK_WIDTH = 100.0;

	// Height of each generated task shape. This also affects vertical centering
	// through TASK_TOP_OFFSET and determines whether an association source is
	// treated as a task by the current edge-routing logic.
	private static final double TASK_HEIGHT = 80.0;

	// Horizontal distance between the starting positions of consecutive tasks.
	// Increasing this lengthens the swimlanes and provides more routing space
	// between tasks, datastores, and sequence flows.
	private static final double TASK_STEP_X = 250.0;

	// Vertical offset from the top of a swimlane to a task. Deriving the value
	// from LANE_HEIGHT and TASK_HEIGHT centers each task vertically in its lane.
	private static final double TASK_TOP_OFFSET = (LANE_HEIGHT - TASK_HEIGHT) / 2.0 - 50.0;

	// Width and height of start and end event shapes. Event positions use this
	// value to align the events vertically with the center of adjacent tasks.
	private static final double EVENT_SIZE = 36.0;

	// Width and height of datastore shapes. This affects datastore centering,
	// association endpoints, and the vertical gap calculated above input tasks.
	private static final double DATA_SIZE = 50.0;

	// Vertical offset from the top of a swimlane for datastores produced by
	// executable tasks. The datastore is positioned 50 points below the task,
	// preventing the datastore shape from overlapping the task area.
	private static final double DATA_TOP_OFFSET = TASK_TOP_OFFSET + TASK_HEIGHT + 50.0;

	// Horizontal spacing applied when multiple datastores are placed for the
	// same producer or when fallback datastore positions are calculated.
	private static final double DATA_STEP_X = 80.0;
	private static final CharSequence UNIT_RECORD_TYPE = "@context\nrecord UNIT {\n\t@suppress int\tunit\n}\n\n";

	public static String generateBPMNModel(AbstractTestDefinition atd, TestDefinition ctd) {
		List<ElementDescriptor> descriptors = createDescriptors(atd);
		BpmnModelInstance modelInstance = generateBPMNModel(atd, descriptors);
		return Bpmn.convertToString(modelInstance);
	}

	public static List<ElementDescriptor> createDescriptors(AbstractTestDefinition atd) {
		List<ElementDescriptor> elements = new ArrayList<>();
		List<TaskDescriptor> tasks = new ArrayList<>();
		Map<String, List<Map.Entry<String, Binding>>> outputsMap = new LinkedHashMap<>();
		Map<String, DataInstanceDescriptor> dataInstanceMap = new LinkedHashMap<>();

		// Collect executable tasks and all output bindings.
		for (AbstractTestSequence sequence : atd.getTestSeq()) {
			for (AbstractStep step : sequence.getStep()) {
				Set<Binding> outputs = new HashSet<>(step.getOutput());
				Set<String> suppressed = step.getSuppress() != null ? step.getSuppress().getVars().stream()
						.map(variableReference -> variableReference.getVariable().getName()).collect(Collectors.toSet())
						: Collections.emptySet();
				outputs.removeIf(output -> suppressed.contains(output.getName().getName()));

				String stepName = getConsumerName(step);
				String laneName = getComponentName(step);

				TaskDescriptor task = new TaskDescriptor(stepName, laneName);
				task.step = step;
				tasks.add(task);

				outputs.forEach(output -> {
					String dataStoreName = output.getName().getName();
					Map.Entry<String, Binding> entry = Map.entry(stepName, output);
					outputsMap.computeIfAbsent(dataStoreName, key -> new ArrayList<>()).add(entry);
				});
			}
		}

		// Create data instances and connect each consumed datum to the binding of
		// the referenced producer step.
		for (AbstractTestSequence sequence : atd.getTestSeq()) {
			for (AbstractStep consumingStep : sequence.getStep()) {
				String consumerName = getConsumerName(consumingStep);
				String laneName = getComponentName(consumingStep);

				consumingStep.getStepRef().forEach(stepReference -> {
					AbstractStep producerStep = stepReference.getRefStep();
					String producerName = getConsumerName(producerStep);

					stepReference.getRefData().forEach(referencedData -> {
						String consumedData = referencedData.getName();
						outputsMap.getOrDefault(consumedData, Collections.emptyList()).stream()
								.filter(entry -> entry.getKey().equals(producerName)).findFirst()
								.ifPresent(matchedEntry -> {
									String key = consumedData + "_" + producerName;
									DataInstanceDescriptor existing = dataInstanceMap.get(key);
									if (existing != null) {
										if (!existing.consumers.contains(consumerName)) {
											existing.consumers.add(consumerName);
										}
										return;
									}

									DataInstanceDescriptor dataInstance = new DataInstanceDescriptor(key, laneName,
											producerName, new ArrayList<>(List.of(consumerName)));
									dataInstance.bind_producer = matchedEntry.getValue();
									dataInstanceMap.put(key, dataInstance);
								});
					});
				});
			}
		}

		// Preserve task/output ordering for executable producers.
		for (TaskDescriptor task : tasks) {
			elements.add(task);
			for (DataInstanceDescriptor dataInstance : dataInstanceMap.values()) {
				if (task.id.equals(dataInstance.producer)) {
					elements.add(dataInstance);
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
		String caseName = normalizeBpmnId(step.getName().replaceAll(".*_(.*_.*)$", "$1"));
		Function function = (Function) step.getCaseRef().eContainer();
		String function_name = function.getElabels();

		return function_name + " " + caseName;
	}

	public static BpmnModelInstance generateBPMNModel(AbstractTestDefinition atd, List<ElementDescriptor> elements) {
		BpmnModelInstance modelInstance = Bpmn4sModel.createEmptyModel();
		Definitions definitions = createDefinitions(modelInstance);
		Process process = createProcess(modelInstance, definitions);
		createDataTypes(atd, modelInstance, process);
		LaneSet laneSet = createLaneSet(modelInstance, process);
		BpmnPlane plane = createDiagram(modelInstance, definitions, process);

		Map<String, Lane> laneMap = new LinkedHashMap<>();
		Map<String, Double> laneYMap = new LinkedHashMap<>();
		Map<String, Task> taskMap = new HashMap<>();
		Map<BaseElement, Bounds> elemBounds = new LinkedHashMap<>();
		long taskCount = elements.stream().filter(TaskDescriptor.class::isInstance).count();
		double laneWidth = Math.max(800.0,
				DIAGRAM_MARGIN_X * 2 + EVENT_SIZE * 2 + TASK_STEP_X * Math.max(1, taskCount));

		createLanes(modelInstance, elements, laneSet, plane, laneMap, laneYMap, DIAGRAM_MARGIN_Y, laneWidth);

		FlowNode previousNode = null;
		int nodeIdx = 0;

		for (ElementDescriptor e : elements) {
			if (e instanceof TaskDescriptor td) {
				String taskId = td.id;
				double x = DIAGRAM_MARGIN_X + EVENT_SIZE + 55.0 + nodeIdx * TASK_STEP_X;
				double y = laneYMap.get(td.lane) + TASK_TOP_OFFSET;

				Task task = createTaskWithIO(modelInstance, process, td);
				addBpmnExtension(task, td.step);
				laneMap.get(td.lane).getFlowNodeRefs().add(task);
				taskMap.put(taskId, task);

				Bounds taskBounds = createBounds(modelInstance, x, y, TASK_WIDTH, TASK_HEIGHT);
				elemBounds.put(task, taskBounds);
				addShapeToPlane(modelInstance, plane, task, taskBounds);

				if (nodeIdx == 0) {
					StartEvent startEvent = createStartEvent(modelInstance, process, td.lane, laneMap);
					Bounds startBounds = createBounds(modelInstance, DIAGRAM_MARGIN_X,
							laneYMap.get(td.lane) + TASK_TOP_OFFSET + (TASK_HEIGHT - EVENT_SIZE) / 2.0, EVENT_SIZE,
							EVENT_SIZE);
					addShapeToPlane(modelInstance, plane, startEvent, startBounds);
					createSequenceFlowWithEdge(modelInstance, process, plane, startEvent, task, "flow_start",
							startBounds, taskBounds);
				}

				if (previousNode != null) {
					Bounds prevBounds = elemBounds.get(previousNode);
					if (prevBounds == null) {
						prevBounds = createBounds(modelInstance, DIAGRAM_MARGIN_X,
								laneYMap.get(td.lane) + TASK_TOP_OFFSET, TASK_WIDTH, TASK_HEIGHT);
					}
					createSequenceFlowWithEdge(modelInstance, process, plane, previousNode, task,
							"flow_" + (nodeIdx - 1) + "_" + nodeIdx, prevBounds, taskBounds);
				}

				if (nodeIdx == taskCount - 1) {
					EndEvent endEvent = createEndEvent(modelInstance, process, td.lane, laneMap);
					Bounds endBounds = createBounds(modelInstance, taskBounds.getX() + TASK_WIDTH + 55.0,
							taskBounds.getY() + (TASK_HEIGHT - EVENT_SIZE) / 2.0, EVENT_SIZE, EVENT_SIZE);
					addShapeToPlane(modelInstance, plane, endEvent, endBounds);
					createSequenceFlowWithEdge(modelInstance, process, plane, task, endEvent, "flow_end", taskBounds,
							endBounds);
				}

				previousNode = task;
				nodeIdx++;
			}
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

					// Keep produced data in the producer's lane. Multiple objects fan out
					// horizontally instead of growing into the lane below.
					x = taskBounds.getX() + (taskBounds.getWidth() - DATA_SIZE) / 2.0 + count * DATA_STEP_X;
					y = laneYMap.get(ds.lane) + DATA_TOP_OFFSET;

					producerDataCount.put(ds.producer, count + 1);
				} else {
					x = DIAGRAM_MARGIN_X + EVENT_SIZE + 55.0 + nodeIdx * DATA_STEP_X;
					y = laneYMap.get(ds.lane) + DATA_TOP_OFFSET;
				}

				// Create shape without connection
				Bounds objBounds = createBounds(modelInstance, x, y, DATA_SIZE, DATA_SIZE);
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

	private static void addBpmnExtension(Task task, AbstractStep step) {
		if (step instanceof RunStep)
			addBpmnExtension(task, (RunStep) step);
		else if (step instanceof ComposeStep)
			addBpmnExtension(task, (ComposeStep) step);
		else if (step instanceof AssertionStep)
			addBpmnExtension(task, (AssertionStep) step);
		else
			throw new IllegalArgumentException("Unexpected executable step: " + step);
	}

	private static void addBpmnExtension(Task task, ComposeStep step) {
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_COMPOSE_TASK);
	}

	private static void addBpmnExtension(Task task, RunStep step) {
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_RUN_TASK);
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_STEP_TYPE, ((RunStep) step).getStepType());
	}

	private static void addBpmnExtension(Task task, AssertionStep step) {
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_RUN_TASK
		// BPMN4S_ASSERT_TASK // TODO change it later
		);
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_STEP_TYPE, ((AssertionStep) step).getStepType());

		AssertionStep assertionStep = (AssertionStep) step;
		String assertions = assertionStep.getAsserts().stream().flatMap(assertion -> assertion.getCe().stream())
				.flatMap(constraintExpression -> constraintExpression.getConstr().stream())
				.map(assertionItem -> printDai(assertionStep, assertionItem)).filter(assertion -> !assertion.isBlank())
				.collect(Collectors.joining("\n"));

		if (!assertions.isBlank()) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_ASSERTIONS, assertions);
		}
	}

	private static void addBpmnExtension(DataAssociation da, Binding bind) {
		TypeDecl b_type = bind.getName().getType().getType();
		JsonValue b_val = bind.getJsonvals();
		String b_str = ConcreteExpressionHandler.createTypeDeclValue(b_type, b_val);
		da.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_UPDATE, b_str);
	}

	private static void addBpmnExtension(DataAssociation da, DataInstanceDescriptor dsDescriptor) {
		String updateAssignment = createUpdateAssignment(dsDescriptor);
		if (updateAssignment != null) {
			da.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_UPDATE, updateAssignment);
		}
	}

	private static String createUpdateAssignment(DataInstanceDescriptor dsDescriptor) {
		Binding bind = dsDescriptor.bind_producer;
		if (bind == null) {
			return null;
		}

		String variableId = normalizeBpmnId(dsDescriptor.id);
		TypeDecl bindingType = bind.getName().getType().getType();
		JsonValue bindingValue = bind.getJsonvals();
		String initialValue = ConcreteExpressionHandler.createTypeDeclValue(bindingType, bindingValue);
		return variableId + " := " + initialValue;
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
		process.setExecutable(true);
		process.setId("BPMNProcess_id");
		process.setName("BPMNProcess");
		definitions.addChildElement(process);
		return process;
	}

	private static void createDataTypes(AbstractTestDefinition atd, BpmnModelInstance modelInstance, Process process) {
		ExtensionElements extElem = modelInstance.newInstance(ExtensionElements.class);
		DataTypes dtype_list = modelInstance.newInstance(DataTypes.class);

		Raw dt_raw = modelInstance.newInstance(Raw.class);
		dt_raw.setTextContent(getTypesRaw(atd));
		dtype_list.addChildElement(dt_raw);

		process.addChildElement(extElem);
		extElem.addChildElement(dtype_list);
	}

	/**
	 * Resolves the product-specific types file imported indirectly by the test
	 * specification and returns its original UTF-8 source text.
	 *
	 * <p>
	 * The expected import chain is:
	 * </p>
	 * <ol>
	 * <li>the {@link TSMain} containing {@code atd} imports the TSpec types
	 * file;</li>
	 * <li>that {@link TypesModel} imports the product-specific types file;</li>
	 * <li>the product-specific types source is embedded in BPMN4S {@code Raw}.</li>
	 * </ol>
	 */
	private static String getTypesRaw(AbstractTestDefinition atd) {
		if (atd == null) {
			throw new IllegalArgumentException("Abstract test definition must not be null");
		}

		EObject container = atd.eContainer();
		while (container != null && !(container instanceof TSMain)) {
			container = container.eContainer();
		}
		if (!(container instanceof TSMain)) {
			throw new IllegalArgumentException(
					"Expected the abstract test definition to be contained in a TSMain parsed by the TSpec language");
		}

		TSMain tsMain = (TSMain) container;
		Resource tspecResource = tsMain.eResource();
		if (tspecResource == null || tspecResource.getResourceSet() == null) {
			throw new IllegalArgumentException("The TSpec model is not attached to an EMF resource set");
		}
		if (tsMain.getImports().isEmpty()) {
			throw new IllegalArgumentException("The TSpec model does not import a TSpec types file");
		}

		URI tSpecTypesUri = resolveImport(tspecResource.getURI(), tsMain.getImports().get(0).getImportURI());
		Resource tSpecTypesResource = tspecResource.getResourceSet().getResource(tSpecTypesUri, true);
		if (tSpecTypesResource.getContents().isEmpty()
				|| !(tSpecTypesResource.getContents().get(0) instanceof TypesModel)) {
			throw new IllegalArgumentException(
					"Expected the imported TSpec types resource to contain a TypesModel parsed by the Types language: "
							+ tSpecTypesUri);
		}

		TypesModel tSpecTypes = (TypesModel) tSpecTypesResource.getContents().get(0);
		if (tSpecTypes.getImports().isEmpty()) {
			throw new IllegalArgumentException(
					"The TSpec types model does not import a product-specific types file: " + tSpecTypesUri);
		}

		URI productTypesUri = resolveImport(tSpecTypesResource.getURI(), tSpecTypes.getImports().get(0).getImportURI());
		return readUtf8(tspecResource, productTypesUri).replace(UNIT_RECORD_TYPE, "");
	}

	private static URI resolveImport(URI baseResourceUri, String importUri) {
		if (importUri == null || importUri.isBlank()) {
			throw new IllegalArgumentException("Types import URI must not be empty");
		}
		URI uri = URI.createURI(importUri);
		return uri.isRelative() ? uri.resolve(baseResourceUri) : uri;
	}

	private static String readUtf8(Resource contextResource, URI uri) {
		try (InputStream input = contextResource.getResourceSet().getURIConverter().createInputStream(uri)) {
			return new String(input.readAllBytes(), StandardCharsets.UTF_8);
		} catch (IOException exception) {
			throw new IllegalArgumentException("Could not read imported product types file: " + uri, exception);
		}
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
			BpmnPlane plane, Map<String, Lane> laneMap, Map<String, Double> laneYMap, double baseY, double laneWidth) {

		for (ElementDescriptor e : elements) {
			if (!laneMap.containsKey(e.lane)) {
				Lane lane = modelInstance.newInstance(Lane.class);
				lane.setId(normalizeBpmnId("lane_" + e.lane));
				lane.setName(e.lane);
				laneSet.addChildElement(lane);
				laneMap.put(e.lane, lane);

				double y = baseY + (laneMap.size() - 1) * LANE_HEIGHT;
				laneYMap.put(e.lane, y);

				Bounds bounds = createBounds(modelInstance, 10.0, y, laneWidth, LANE_HEIGHT);
				addShapeToPlane(modelInstance, plane, lane, bounds);
			}
		}
	}

	/**
	 * BPMN ids use the XML Schema NCName datatype. Keep the human-readable element
	 * name unchanged, but replace characters that are illegal in an NCName (for
	 * example parentheses) in generated ids.
	 */
	private static String normalizeBpmnId(String id) {
		if (id == null || id.isEmpty()) {
			return "id";
		}
		String normalized = id.replaceAll("[^A-Za-z0-9_.]", "_");
		if (!normalized.substring(0, 1).matches("[A-Za-z_]")) {
			normalized = "id_" + normalized;
		}
		return normalized;
	}

	private static String normalizeTaskId(String td_id) {
		return normalizeBpmnId(td_id);
	}

	private static String normalizeTaskId(TaskDescriptor td) {
		return normalizeTaskId(td.id);
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
		task.setName(td.id.replace('_', ' '));
		process.addChildElement(task);

		Property prop = modelInstance.newInstance(Property.class);
		prop.setId(task_id + "_placeholder_id");
		prop.setName(td.id + "_placeholder");
		task.addChildElement(prop);

		return task;
	}

	private static String printDai(AssertionStep step, DataAssertionItem item) {
		return EcoreUtil3.serialize(item, object -> {
			if (object instanceof ExpressionVariable) {
				ExpressionVariable expressionVariable = (ExpressionVariable) object;
				String variableName = Utils.getVarField(expressionVariable.getVariable());
				return Utils.getInputVar(step) + "." + variableName;
			}
			return null;
		}).stripIndent().trim();
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

	private static String getBindingType(DataInstanceDescriptor dsDescriptor) {
		TypeDecl b_type = dsDescriptor.bind_producer.getName().getType().getType();
		return b_type.getName();
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

	private static DataStoreReference linkDataInstanceToTasks(BpmnModelInstance modelInstance, Definitions definitions,
			Process process, BpmnPlane plane, DataInstanceDescriptor dsDescriptor, Map<String, Task> taskMap,
			Map<BaseElement, Bounds> elemBounds, double x, double y) {
		boolean hasProducerTask = dsDescriptor.producer != null && taskMap.containsKey(dsDescriptor.producer);
		boolean hasConsumerTask = dsDescriptor.consumers.stream().anyMatch(taskMap::containsKey);
		if (!hasProducerTask && !hasConsumerTask)
			return null;

		String dsId = normalizeBpmnId("dataobject_" + dsDescriptor.id);

		// 1 Create DataStoreReference in the process
		DataStoreReference dsRef = modelInstance.newInstance(DataStoreReference.class);
		dsRef.setId(dsId + "_ref");
		dsRef.setName(normalizeTaskId(dsDescriptor.id));
		dsRef.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_DATATYPE_REF, getBindingType(dsDescriptor));
//		// Compose is not represented as a BPMN task. Its update assignment
//		// initializes the persistent data store directly.
//		if (dsDescriptor.initializedByCompose) {
//			String initializationAssignment = createUpdateAssignment(dsDescriptor);
//			if (initializationAssignment != null) {
//				dsRef.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_INIT, initializationAssignment);
//			}
//		}
		process.addChildElement(dsRef);

		// 2 Add diagram shape for the DataStoreReference.
		BpmnShape dsShape = modelInstance.newInstance(BpmnShape.class);
		dsShape.setId("shape_" + dsId);
		dsShape.setBpmnElement(dsRef);
		Bounds dsBounds = createBounds(modelInstance, x, y, DATA_SIZE, DATA_SIZE);
		dsShape.setBounds(dsBounds);

		plane.addChildElement(dsShape);
		// 3 Link producer task to DataStoreReference
		if (dsDescriptor.producer != null) {
			Task producer = taskMap.get(dsDescriptor.producer);
			if (producer != null) {
				DataOutputAssociation doa = modelInstance.newInstance(DataOutputAssociation.class);
				doa.setId("doa_" + dsId + "_" + producer.getId());
				doa.setTarget(dsRef);

				addBpmnExtension(doa, dsDescriptor);
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

		// 4 Link DataStoreReference to each consumer task (input)
		for (int consumerIdx = 0; consumerIdx < dsDescriptor.consumers.size(); consumerIdx++) {
			String consumerId = dsDescriptor.consumers.get(consumerIdx);
			Task consumer = taskMap.get(consumerId);
			if (consumer != null) {
				String dstaskLabel = dsId + "_" + consumer.getId();
				String uid = "_" + UUID.randomUUID().toString();

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
				// Datastore reads are non-consuming: the stored value remains
				// available to subsequent consumers.
				dia.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_PERSISTENT_READ, "true");

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

		return dsRef;
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

			// Distribute arrival points on top edge of the data store
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

			// A datastore-to-task association enters the task at its top edge. This is
			// especially important for compose-initialized stores positioned directly
			// above their first executable consumer.
			double sourceOffsetX = calculateHorizontalOffset(sourceConnectionIndex, totalSourceConnections,
					sourceWidth);
			double exitX = sourceBounds.getX() + sourceOffsetX;

			// If the task has both inputs and outputs, keep input connections on the
			// right half of the task top edge. Otherwise distribute over the full edge.
			int totalTaskOutputs = totalSourceOutputs;
			boolean taskHasBothInputsAndOutputs = (totalTargetInputs > 0 && totalTaskOutputs > 0);

			double offsetX;
			if (taskHasBothInputsAndOutputs) {
				offsetX = calculateHorizontalOffsetInRegion(targetConnectionIndex, totalTargetConnections, targetWidth,
						0.55, 1.0);
			} else {
				offsetX = calculateHorizontalOffset(targetConnectionIndex, totalTargetConnections, targetWidth);
			}
			double inputX = targetBounds.getX() + offsetX;
			double routingY = Math.min(sourceBottomY, targetTopY) - 20.0 - (targetConnectionIndex * 10);

			wp1.setX(exitX);
			wp1.setY(sourceBottomY);

			wp2.setX(exitX);
			wp2.setY(routingY);

			wp3.setX(inputX);
			wp3.setY(routingY);

			wp4.setX(inputX);
			wp4.setY(targetTopY - 1.0);
		}

		edge.getWaypoints().addAll(Arrays.asList(wp1, wp4));

		plane.addChildElement(edge);
	}

	// Count total outputs from a task
	private static int countTotalOutputs(Task task) {
		int count = task.getChildElementsByType(DataOutputAssociation.class).size();
		return Math.max(1, count);
	}

	// Count total inputs to a task
	private static int countTotalInputs(Task task) {
		int count = task.getChildElementsByType(DataInputAssociation.class).size();
		return Math.max(1, count);
	}

	// Get the index of a specific output association
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

	// Get the index of a specific input association
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
//
//	// Distribute connections evenly along a vertical edge
//	private static double calculateVerticalOffset(int index, int total, double height) {
//		if (total == 1) {
//			return height / 2.0;
//		}
//
//		// Leave 20% margin on top and bottom, distribute in the middle 60%
//		double usableHeight = height * 0.6;
//		double margin = height * 0.2;
//		double spacing = usableHeight / (total - 1);
//
//		return margin + (index * spacing);
//	}
}