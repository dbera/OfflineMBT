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
import org.camunda.bpm.model.bpmn.instance.Documentation;
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
import nl.asml.matala.product.product.RefConstraint;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestSequence;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AssertionStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.Binding;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ComposeStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.ConstraintStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.RunStep;
import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain;
import nl.esi.comma.abstracttestspecification.generator.to.concrete.ConcreteExpressionHandler;
import nl.esi.comma.abstracttestspecification.generator.utils.Utils;
import nl.esi.comma.assertthat.assertThat.DataAssertionItem;
import nl.esi.comma.assertthat.assertThat.JsonValue;
import nl.esi.comma.testspecification.testspecification.TestDefinition;
import nl.esi.xtext.actions.actions.AssignmentAction;
import nl.esi.xtext.actions.actions.RecordFieldAssignmentAction;
import nl.esi.xtext.common.lang.utilities.EcoreUtil3;
import nl.esi.xtext.expressions.expression.ExpressionVariable;
import nl.esi.xtext.types.types.TypeDecl;
import nl.esi.xtext.types.types.TypesModel;

/**
 * Converts abstract test definitions into a BPMN4S process and its BPMN Diagram
 * Interchange (DI) representation.
 *
 * <p>
 * Run, compose and assertion steps remain visible as tasks. Referenced output
 * bindings become persistent datastores connected to their producers and
 * consumers. Compose tasks can therefore receive data from multiple referenced
 * run steps through separate input associations.
 * </p>
 *
 * <p>
 * The conversion records task metadata, binding assignments and assertion
 * expressions; it does not execute the represented test steps.
 * </p>
 */
public class CamundaParser {

	// Namespace URIs used by the semantic BPMN model, its diagram representation
	// and the BPMN4S extension attributes.
	final static String XMLNS_XSI = "http://www.w3.org/2001/XMLSchema-instance";
	final static String XMLNS_DI = "http://www.omg.org/spec/DD/20100524/DI";
	final static String XMLNS_DC = "http://www.omg.org/spec/DD/20100524/DC";
	final static String XMLNS_COLOR = "http://www.omg.org/spec/BPMN/non-normative/color/1.0";
	final static String XMLNS_BPMNDI = "http://www.omg.org/spec/BPMN/20100524/DI";
	final static String XMLNS_BPMN4S = "http://bpmn4s";
	final static String XMLNS_BPMN2 = "http://www.omg.org/spec/BPMN/20100524/MODEL";
	final static String XMLNS_BIOC = "http://bpmn.io/schema/bpmn/biocolor/1.0";

	// Task subtype values and extension attribute names. AssertTask is retained
	// for the pending assertion-subtype change; assertion tasks currently use
	// RunTask.
	private static final String BPMN4S_RUN_TASK = "RunTask";
	private static final String BPMN4S_ASSERT_TASK = "AssertTask";
	private static final String BPMN4S_COMPOSE_TASK = "ComposeTask";
	private static final String BPMN4S_SUB_TYPE = "subType";
	private static final String BPMN4S_STEP_TYPE = "stepType";
	private static final String BPMN4S_DATATYPE_REF = "dataTypeRef";
	private static final String BPMN4S_UPDATE = "update";
	private static final String BPMN4S_UPDATE_REF = "referenceUpdate";
	private static final String BPMN4S_ASSERTIONS = "assertions";

	// Retained for the disabled datastore-initialization block below. Active
	// generation writes compose outputs through producer associations instead.
	private static final String BPMN4S_INIT = "init";
	private static final String BPMN4S_PERSISTENT_READ = "persistentRead";

	// BPMN DI layout constants. Keep them together so the generated diagram can
	// be tuned without changing the semantic model construction.

	// Base horizontal offset used for start-event placement, task positioning
	// and lane-width calculation.
	private static final double DIAGRAM_MARGIN_X = 50.0;

	// Vertical offset between the diagram origin and the top of the first
	// swimlane. Increasing this moves all lanes and their contents downward.
	private static final double DIAGRAM_MARGIN_Y = 40.0;

	// Height allocated to each swimlane. This controls lane spacing and also
	// contributes to the task and datastore vertical offsets.
	private static final double LANE_HEIGHT = 300.0;

	// Width of each generated task shape. Increasing this provides more label
	// space but reduces the horizontal gap between consecutive task shapes.
	private static final double TASK_WIDTH = 100.0;

	// Height of each generated task shape. Data-association routing currently
	// distinguishes task sources from datastore sources using a height threshold
	// of 50, so changing this value can also affect routing classification.
	private static final double TASK_HEIGHT = 80.0;

	// Horizontal distance between the starting positions of consecutive tasks,
	// including tasks belonging to different swimlanes.
	private static final double TASK_STEP_X = 250.0;

	// Position tasks 50 points above their vertically centered position within
	// the lane, leaving additional space below them for output datastores.
	private static final double TASK_TOP_OFFSET = (LANE_HEIGHT - TASK_HEIGHT) / 2.0 - 50.0;

	// Width and height of start and end event shapes. Events are vertically
	// aligned with the center of their adjacent task.
	private static final double EVENT_SIZE = 36.0;

	// Width and height of datastore shapes. This value affects centering and
	// data-association endpoint placement.
	private static final double DATA_SIZE = 50.0;

	// Default datastore top position relative to its descriptor's lane origin.
	// This leaves a 50-point gap below a task positioned at TASK_TOP_OFFSET in
	// the same lane.
	private static final double DATA_TOP_OFFSET = TASK_TOP_OFFSET + TASK_HEIGHT + 50.0;

	// Horizontal spacing between datastores associated with the same producer,
	// also used when calculating fallback datastore positions.
	private static final double DATA_STEP_X = 80.0;

	// Exact source fragment removed from the embedded product types text.
	// Removal is textual, so whitespace and line endings must match this value.
	private static final CharSequence UNIT_RECORD_TYPE = "@context\nrecord UNIT {\n\t@suppress int\tunit\n}\n\n";

	/**
	 * Creates descriptors, builds the BPMN4S model and serializes it as XML.
	 *
	 * <p>
	 * The concrete test definition is accepted by this entry point but is not
	 * currently used by the conversion.
	 * </p>
	 */
	public static String generateBPMNModel(AbstractTestDefinition atd, TestDefinition ctd) {
		List<ElementDescriptor> descriptors = createDescriptors(atd);
		BpmnModelInstance modelInstance = generateBPMNModel(atd, descriptors);
		return Bpmn.convertToString(modelInstance);
	}

	/**
	 * Builds an intermediate representation of tasks and referenced output data.
	 *
	 * <p>
	 * The first pass collects tasks and indexes non-suppressed output bindings. The
	 * second pass resolves step/data references into shared datastore descriptors.
	 * Only outputs referenced by another step receive a datastore descriptor.
	 * </p>
	 *
	 * <p>
	 * Run, compose and assertion steps retain their source traversal order. Each
	 * datastore descriptor is placed immediately after its producer task.
	 * </p>
	 */
	public static List<ElementDescriptor> createDescriptors(AbstractTestDefinition atd) {
		List<ElementDescriptor> elements = new ArrayList<>();
		List<TaskDescriptor> tasks = new ArrayList<>();
		Map<String, List<Map.Entry<String, Binding>>> outputsMap = new LinkedHashMap<>();
		Map<String, DataInstanceDescriptor> dataInstanceMap = new LinkedHashMap<>();

		// First pass: retain all steps as tasks and index their available outputs.
		// Compose steps are not collapsed into datastore initialization.
		for (AbstractTestSequence sequence : atd.getTestSeq()) {
			for (AbstractStep step : sequence.getStep()) {
				// Exclude suppressed output variables from the bindings that can be
				// resolved into datastore descriptors.
				Set<Binding> outputs = new HashSet<>(step.getOutput());
				Set<String> suppressed = step.getSuppress() != null ? step.getSuppress().getVars().stream()
						.map(variableReference -> variableReference.getVariable().getName()).collect(Collectors.toSet())
						: Collections.emptySet();
				outputs.removeIf(output -> suppressed.contains(output.getName().getName()));

				String stepName = getConsumerName(step);
				String laneName = getComponentName(step);

				// Keep the original step so task-specific BPMN4S metadata can be added
				// when the semantic task is created.
				TaskDescriptor task = new TaskDescriptor(stepName, laneName);
				task.step = step;
				tasks.add(task);

				// Index by data name while retaining the producer identity, since
				// different steps may expose outputs with the same name.
				outputs.forEach(output -> {
					String dataStoreName = output.getName().getName();
					Map.Entry<String, Binding> entry = Map.entry(stepName, output);
					outputsMap.computeIfAbsent(dataStoreName, key -> new ArrayList<>()).add(entry);
				});
			}
		}

		// Second pass: resolve each referenced datum against its named producer.
		// The same mechanism connects run outputs to compose inputs, including
		// compose steps that reference data from several run steps.
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
									// Share one datastore per data-name/producer pair rather than
									// creating a separate datastore for every consumer.
									String key = consumedData + "_" + producerName;
									DataInstanceDescriptor existing = dataInstanceMap.get(key);
									if (existing != null) {
										if (!existing.consumers.contains(consumerName)) {
											existing.consumers.add(consumerName);
										}
										return;
									}

									// The first consumer determines the descriptor's lane. Later
									// consumers reuse this descriptor without changing that lane.
									DataInstanceDescriptor dataInstance = new DataInstanceDescriptor(key, laneName,
											producerName, new ArrayList<>(List.of(consumerName)));
									dataInstance.bind_producer = matchedEntry.getValue();
									dataInstanceMap.put(key, dataInstance);
								});
					});
				});
			}
		}

		// Preserve task traversal order and insert referenced output datastores
		// directly after their run or compose producer.
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

	/**
	 * Derives the swimlane name from the block containing the referenced case's
	 * function.
	 */
	private static String getComponentName(AbstractStep step) {
		Function function = (Function) step.getCaseRef().eContainer();
		Block block = (Block) function.eContainer();

		// Prefer the second block label when available; otherwise use the first.
		int component_idx = block.getElabels().size() > 1 ? 1 : 0;

		return block.getElabels().get(component_idx);
	}

	/**
	 * Defines the shared task identity used by task descriptors, producer/consumer
	 * references and producer-qualified datastore keys.
	 *
	 * Preserves the existing suffix extraction, but shortens "default_<idx>" to
	 * "<idx>". Named suffixes remain unchanged.
	 */
	private static String getConsumerName(AbstractStep step) {
		// Preserve the existing extraction and normalization of the case suffix.
		String caseName = normalizeBpmnId(step.getName().replaceAll(".*_(.*_.*)$", "$1"));

		// Remove "default_" only when the complete suffix is default_<numeric index>.
		// Apply this after suffix normalization so a numeric index is not prefixed
		// with "id_"; the complete task identity is normalized separately when needed.
		caseName = caseName.replaceAll("^default_(\\d+)$", "$1");

		Function function = (Function) step.getCaseRef().eContainer();
		String function_name = function.getElabels();

		return function_name + " " + caseName;
	}

	/**
	 * Creates the semantic BPMN4S process and its visual representation.
	 *
	 * <p>
	 * Tasks and sequence flows are created first. Datastore positions are
	 * calculated next, followed by datastore elements and their data associations.
	 * This ensures task bounds are available when positioning and connecting data.
	 * </p>
	 */
	public static BpmnModelInstance generateBPMNModel(AbstractTestDefinition atd, List<ElementDescriptor> elements) {
		BpmnModelInstance modelInstance = Bpmn4sModel.createEmptyModel();
		Definitions definitions = createDefinitions(modelInstance);
		Process process = createProcess(modelInstance, definitions);
		createDataTypes(atd, modelInstance, process);
		LaneSet laneSet = createLaneSet(modelInstance, process);
		BpmnPlane plane = createDiagram(modelInstance, definitions, process);

		// Index semantic elements and their DI coordinates for later association
		// creation and endpoint calculation.
		Map<String, Lane> laneMap = new LinkedHashMap<>();
		Map<String, Double> laneYMap = new LinkedHashMap<>();
		Map<String, Task> taskMap = new HashMap<>();
		Map<BaseElement, Bounds> elemBounds = new LinkedHashMap<>();

		// Allocate horizontal space for the complete task sequence, retaining a
		// minimum lane width for small models.
		long taskCount = elements.stream().filter(TaskDescriptor.class::isInstance).count();
		double laneWidth = Math.max(800.0,
				DIAGRAM_MARGIN_X * 2 + EVENT_SIZE * 2 + TASK_STEP_X * Math.max(1, taskCount));

		createLanes(modelInstance, elements, laneSet, plane, laneMap, laneYMap, DIAGRAM_MARGIN_Y, laneWidth);

		FlowNode previousNode = null;
		int nodeIdx = 0;

		// Create one linear sequence across all task descriptors. The horizontal
		// index advances globally, including when consecutive tasks use different
		// lanes.
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

				// Place the start event in the first task's lane and align their centers.
				if (nodeIdx == 0) {
					StartEvent startEvent = createStartEvent(modelInstance, process, td.lane, laneMap);
					Bounds startBounds = createBounds(modelInstance, DIAGRAM_MARGIN_X,
							laneYMap.get(td.lane) + TASK_TOP_OFFSET + (TASK_HEIGHT - EVENT_SIZE) / 2.0, EVENT_SIZE,
							EVENT_SIZE);
					addShapeToPlane(modelInstance, plane, startEvent, startBounds);
					createSequenceFlowWithEdge(modelInstance, process, plane, startEvent, task, "flow_start",
							startBounds, taskBounds);
				}

				// Connect consecutive tasks regardless of their step type or lane.
				if (previousNode != null) {
					Bounds prevBounds = elemBounds.get(previousNode);
					if (prevBounds == null) {
						prevBounds = createBounds(modelInstance, DIAGRAM_MARGIN_X,
								laneYMap.get(td.lane) + TASK_TOP_OFFSET, TASK_WIDTH, TASK_HEIGHT);
					}
					createSequenceFlowWithEdge(modelInstance, process, plane, previousNode, task,
							"flow_" + (nodeIdx - 1) + "_" + nodeIdx, prevBounds, taskBounds);
				}

				// Place the end event after the last task in that task's lane.
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

		// Track horizontal fan-out separately for each producer.
		Map<String, Integer> producerDataCount = new HashMap<>();

		// Retain datastore positions until their semantic elements and edges are
		// created in the following pass.
		Map<DataInstanceDescriptor, Bounds> dataBoundsMap = new LinkedHashMap<>();

		for (ElementDescriptor e : elements) {
			if (e instanceof DataInstanceDescriptor ds) {
				double x, y;

				if (ds.producer != null && taskMap.containsKey(ds.producer)) {
					Task producer = taskMap.get(ds.producer);
					Bounds taskBounds = elemBounds.get(producer);
					int count = producerDataCount.getOrDefault(ds.producer, 0);

					// Align horizontally with the producer and fan out additional outputs.
					// Vertical placement uses the datastore descriptor's lane, which is
					// assigned from its first consumer during descriptor construction.
					x = taskBounds.getX() + (taskBounds.getWidth() - DATA_SIZE) / 2.0 + count * DATA_STEP_X;
					y = laneYMap.get(ds.lane) + DATA_TOP_OFFSET;

					producerDataCount.put(ds.producer, count + 1);
				} else {
					// Fall back to a lane-relative position when no generated producer
					// task can be found.
					x = DIAGRAM_MARGIN_X + EVENT_SIZE + 55.0 + nodeIdx * DATA_STEP_X;
					y = laneYMap.get(ds.lane) + DATA_TOP_OFFSET;
				}

				// Record bounds only; the actual datastore shape and associations are
				// created after this positioning pass.
				Bounds objBounds = createBounds(modelInstance, x, y, DATA_SIZE, DATA_SIZE);
				dataBoundsMap.put(ds, objBounds);
			}
			// This index includes all descriptors and is used only for fallback
			// datastore positioning in this pass.
			nodeIdx++;
		}

		// Create each datastore and connect it using the previously calculated bounds.
		for (var entry : dataBoundsMap.entrySet()) {
			DataInstanceDescriptor ds = entry.getKey();
			Bounds objBounds = entry.getValue();
			linkDataInstanceToTasks(modelInstance, definitions, process, plane, ds, taskMap, elemBounds,
					objBounds.getX(), objBounds.getY());
		}

		return modelInstance;
	}

	/**
	 * Dispatches task metadata generation to the overload for the concrete step
	 * type. Unsupported step types fail explicitly rather than producing an
	 * unclassified task.
	 */
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

	/**
	 * Marks a visible compose task with the ComposeTask subtype. Its referenced
	 * inputs and produced outputs are represented by the shared data-association
	 * generation logic.
	 */
	private static void addBpmnExtension(Task task, ComposeStep step) {
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_COMPOSE_TASK);
	}

	/**
	 * Adds the run-task subtype and the source model's domain-specific step type.
	 */
	private static void addBpmnExtension(Task task, RunStep step) {
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_RUN_TASK);
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_STEP_TYPE, ((RunStep) step).getStepType());
	}

	/**
	 * Adds assertion expressions and step-type metadata.
	 *
	 * <p>
	 * Assertion tasks currently use the RunTask subtype. The switch to AssertTask
	 * remains pending, as indicated at the subtype assignment below.
	 * </p>
	 */
	private static void addBpmnExtension(Task task, AssertionStep step) {
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_SUB_TYPE, BPMN4S_ASSERT_TASK);
		task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_STEP_TYPE, ((AssertionStep) step).getStepType());

		// Flatten nested constraint items, rewrite their variable references and
		// combine non-empty assertions into one newline-separated attribute value.
		AssertionStep assertionStep = (AssertionStep) step;
		String assertions = assertionStep.getAsserts().stream().flatMap(assertion -> assertion.getCe().stream())
				.flatMap(constraintExpression -> constraintExpression.getConstr().stream())
				.map(assertionItem -> printDai(assertionStep, assertionItem)).filter(assertion -> !assertion.isBlank())
				.collect(Collectors.joining("\n"));

		if (!assertions.isBlank()) {
			task.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_ASSERTIONS, assertions);
		}
	}

	/**
	 * Serializes a binding value as an association-level BPMN4S update expression.
	 * Unlike the descriptor overload, this does not prepend a datastore assignment.
	 */
	private static void addBpmnExtension(DataAssociation da, Binding bind) {
		TypeDecl b_type = bind.getName().getType().getType();
		JsonValue b_val = bind.getJsonvals();
		String b_str = ConcreteExpressionHandler.createTypeDeclValue(b_type, b_val, p -> false);
		da.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_UPDATE, b_str);
	}

	/**
	 * Adds the producer binding as a complete datastore assignment on an output
	 * association, when a producer binding is available.
	 */
	/**
	 * Adds the producer assignment and optional compose reference updates to an
	 * output association.
	 */
	private static void addBpmnExtension(DataAssociation da, DataInstanceDescriptor dsDescriptor) {
		String updateAssignment = createUpdateAssignment(dsDescriptor);
		if (updateAssignment != null) {
			da.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_UPDATE, updateAssignment);
		}

		String referenceUpdates = getReferenceUpdates(dsDescriptor);
		if (referenceUpdates != null) {
			da.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_UPDATE_REF,
					"// Auto-generated by nl.asml.matala.generator.bpmn.FromConcreteToBpmn parser\n" + referenceUpdates
							+ "\n");
		}
	}

	/**
	 * Serializes all reference constraints from all constraint steps of a compose
	 * producer, preserving their source order.
	 *
	 * Assignment targets use output datastore names, while value expressions use
	 * input datastore names. Other constraint elements retain default
	 * serialization.
	 *
	 * @return newline-separated constraints, or null when no reference constraints
	 *         are available
	 */
	private static String getReferenceUpdates(DataInstanceDescriptor dsDescriptor) {
		EObject container = dsDescriptor.bind_producer.eContainer();
		if (!(container instanceof ComposeStep))
			return null;

		ComposeStep composeStep = (ComposeStep) container;
		if (composeStep.getRefs().isEmpty())
			return null;

		Map<String, String> inputDatastores = getProducerQualifiedDatastoreKeysInput(composeStep);
		Map<String, String> outputDatastores = getProducerQualifiedDatastoreKeysOutput(composeStep);
		List<String> referenceUpdates = new ArrayList<>();

		// Visit every constraint step and every reference constraint within it.
		// An empty constraint step does not prevent later steps from being processed.
		for (ConstraintStep constraintStep : composeStep.getRefs()) {
			for (RefConstraint constraint : constraintStep.getCe()) {
				String serializedConstraint = EcoreUtil3.serialize(constraint, object -> {
					EObject target;
					EObject expression;

					// Extract the target and value for either supported assignment form.
					// Serialization below is shared by both forms.
					if (object instanceof AssignmentAction) {
						AssignmentAction action = (AssignmentAction) object;
						target = action.getAssignment();
						expression = action.getExp();
					} else if (object instanceof RecordFieldAssignmentAction) {
						RecordFieldAssignmentAction action = (RecordFieldAssignmentAction) object;
						target = action.getFieldAccess();
						expression = action.getExp();
					} else {
						// Leave all other constraint elements to the default serializer.
						return null;
					}

					String assignment = serializeWithDatastoreNames(target, outputDatastores);
					String value = serializeWithDatastoreNames(expression, inputDatastores);
					return String.format("%s := %s", assignment, value);
				}).stripIndent().trim();

				referenceUpdates.add(serializedConstraint);
			}
		}

		// Preserve the null result when there are no reference constraints at all.
		return referenceUpdates.isEmpty() ? null : String.join("\n", referenceUpdates);
	}

	/**
	 * Serializes a model fragment while replacing expression variables with their
	 * normalized, producer-qualified datastore names.
	 */
	private static String serializeWithDatastoreNames(EObject element, Map<String, String> datastoreNames) {
		return EcoreUtil3.serialize(element, object -> {
			if (object instanceof ExpressionVariable) {
				ExpressionVariable expressionVariable = (ExpressionVariable) object;
				String variableName = Utils.getVarField(expressionVariable.getVariable());

				// Preserve the existing datastore lookup and normalization behavior.
				return normalizeBpmnId(datastoreNames.get(variableName));
			}

			// Preserve default handling of field accesses, operators and literals.
			return null;
		}).stripIndent().trim();
	}

	/**
	 * Builds an assignment of the form {@code datastoreId := serializedValue}.
	 *
	 * @return the assignment, or {@code null} if no producer binding is present
	 */
	private static String createUpdateAssignment(DataInstanceDescriptor dsDescriptor) {
		Binding bind = dsDescriptor.bind_producer;
		if (bind == null) {
			return null;
		}

		String variableId = normalizeBpmnId(dsDescriptor.id);
		TypeDecl bindingType = bind.getName().getType().getType();
		JsonValue bindingValue = bind.getJsonvals();
		String initialValue = ConcreteExpressionHandler.createTypeDeclValue(bindingType, bindingValue, p -> false);
		return variableId + " := " + initialValue;
	}

	/**
	 * Creates the document root and registers namespaces used by BPMN elements,
	 * diagram elements and extension attributes.
	 */
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

	/**
	 * Creates the executable process containing the generated tasks, events,
	 * sequence flows, lanes and datastores.
	 */
	private static Process createProcess(BpmnModelInstance modelInstance, Definitions definitions) {
		Process process = modelInstance.newInstance(Process.class);
		process.setExecutable(true);
		process.setId("BPMNProcess_id");
		process.setName("BPMNProcess");
		definitions.addChildElement(process);
		return process;
	}

	/**
	 * Embeds the product types source, after removal of the configured UNIT
	 * fragment, inside the process's BPMN4S extension elements.
	 */
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
	 * specification, reads its UTF-8 source and removes the exact
	 * {@code UNIT_RECORD_TYPE} fragment.
	 *
	 * <p>
	 * The expected import chain is:
	 * </p>
	 * <ol>
	 * <li>the {@link TSMain} containing {@code atd} imports the TSpec types
	 * file;</li>
	 * <li>that {@link TypesModel} imports the product-specific types file;</li>
	 * <li>the filtered product-specific source is embedded in BPMN4S
	 * {@code Raw}.</li>
	 * </ol>
	 *
	 * <p>
	 * Only the first import at each level is followed; this is not a recursive
	 * traversal of all imported types resources.
	 * </p>
	 */
	private static String getTypesRaw(AbstractTestDefinition atd) {
		if (atd == null) {
			throw new IllegalArgumentException("Abstract test definition must not be null");
		}

		// Locate TSMain through containment rather than assuming it is the direct
		// parent of the abstract test definition.
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

		// Load the first imported types resource through the existing ResourceSet,
		// retaining its resource factories and URI mappings.
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

		// Resolve the product types relative to the intermediate types resource.
		URI productTypesUri = resolveImport(tSpecTypesResource.getURI(), tSpecTypes.getImports().get(0).getImportURI());
		// Remove only exact occurrences of the configured UNIT source fragment.
		return readUtf8(tspecResource, productTypesUri).replace(UNIT_RECORD_TYPE, "");
	}

	/**
	 * Resolves relative imports against the containing resource URI and leaves
	 * absolute import URIs unchanged.
	 */
	private static URI resolveImport(URI baseResourceUri, String importUri) {
		if (importUri == null || importUri.isBlank()) {
			throw new IllegalArgumentException("Types import URI must not be empty");
		}
		URI uri = URI.createURI(importUri);
		return uri.isRelative() ? uri.resolve(baseResourceUri) : uri;
	}

	/**
	 * Reads UTF-8 source through the ResourceSet's URI converter so configured
	 * resource mappings are respected. The input stream is closed automatically.
	 */
	private static String readUtf8(Resource contextResource, URI uri) {
		try (InputStream input = contextResource.getResourceSet().getURIConverter().createInputStream(uri)) {
			return new String(input.readAllBytes(), StandardCharsets.UTF_8);
		} catch (IOException exception) {
			throw new IllegalArgumentException("Could not read imported product types file: " + uri, exception);
		}
	}

	/**
	 * Creates the lane set used to group tasks by their derived component name.
	 */
	private static LaneSet createLaneSet(BpmnModelInstance modelInstance, Process process) {
		LaneSet laneSet = modelInstance.newInstance(LaneSet.class);
		laneSet.setId("LaneSet_id");
		laneSet.setName("LaneSet");
		process.addChildElement(laneSet);
		return laneSet;
	}

	/**
	 * Creates a BPMN DI diagram and a plane referencing the semantic process.
	 * Shapes and edges are subsequently attached to this plane.
	 */
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

	/**
	 * Creates one lane per distinct descriptor lane name, preserving the order in
	 * which names first occur.
	 */
	private static void createLanes(BpmnModelInstance modelInstance, List<ElementDescriptor> elements, LaneSet laneSet,
			BpmnPlane plane, Map<String, Lane> laneMap, Map<String, Double> laneYMap, double baseY, double laneWidth) {

		for (ElementDescriptor e : elements) {
			if (!laneMap.containsKey(e.lane)) {
				Lane lane = modelInstance.newInstance(Lane.class);
				lane.setId(normalizeBpmnId("lane_" + e.lane));
				lane.setName(e.lane);
				laneSet.addChildElement(lane);
				laneMap.put(e.lane, lane);

				// Stack lanes vertically using their insertion index.
				double y = baseY + (laneMap.size() - 1) * LANE_HEIGHT;
				laneYMap.put(e.lane, y);

				Bounds bounds = createBounds(modelInstance, 10.0, y, laneWidth, LANE_HEIGHT);
				addShapeToPlane(modelInstance, plane, lane, bounds);
			}
		}
	}

	/**
	 * Converts an identifier to a restricted ASCII subset suitable for XML Schema
	 * NCName values used by BPMN ids.
	 *
	 * <p>
	 * Characters other than ASCII letters, digits, underscores and dots are
	 * replaced with underscores. A prefix is added when the first character is not
	 * a letter or underscore. This normalization does not guarantee uniqueness.
	 * </p>
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

	/**
	 * Applies the shared BPMN identifier normalization to a task identity.
	 */
	private static String normalizeTaskId(String td_id) {
		return normalizeBpmnId(td_id);
	}

	/**
	 * Normalizes the identity stored in a task descriptor.
	 */
	private static String normalizeTaskId(TaskDescriptor td) {
		return normalizeTaskId(td.id);
	}

	/**
	 * Creates a DI bounds object with the supplied position and dimensions.
	 */
	private static Bounds createBounds(BpmnModelInstance modelInstance, double x, double y, double width,
			double height) {
		Bounds bounds = modelInstance.newInstance(Bounds.class);
		bounds.setX(x);
		bounds.setY(y);
		bounds.setWidth(width);
		bounds.setHeight(height);
		return bounds;
	}

	/**
	 * Adds a visual shape referencing an existing semantic BPMN element.
	 */
	private static void addShapeToPlane(BpmnModelInstance modelInstance, BpmnPlane plane, BaseElement element,
			Bounds bounds) {
		BpmnShape shape = modelInstance.newInstance(BpmnShape.class);
		shape.setId(element.getId() + "_shape");
		shape.setBpmnElement(element);
		shape.setBounds(bounds);
		plane.addChildElement(shape);
	}

	/**
	 * Creates a task and its placeholder property. Actual input properties and data
	 * associations are added later when datastores are linked.
	 */
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

	/**
	 * Serializes an assertion item while qualifying expression variables with the
	 * datastore containing the assertion step's referenced input.
	 *
	 * The datastore key follows the same naming convention as createDescriptors():
	 * consumedData + "_" + producerName. Normalization matches the variable name
	 * emitted by createUpdateAssignment().
	 */
	private static String printDai(AssertionStep step, DataAssertionItem item) {
		HashMap<String, String> datastoreNames = getProducerQualifiedDatastoreKeysInput(step);

		return EcoreUtil3.serialize(item, object -> {
			if (object instanceof ExpressionVariable) {
				ExpressionVariable expressionVariable = (ExpressionVariable) object;
				String variableName = Utils.getVarField(expressionVariable.getVariable());
				String normalizedName = normalizeBpmnId(datastoreNames.get(variableName));

				// Preserve the existing field serialization, replacing only its input
				// qualifier with the resolved producer-qualified datastore variable.
				return normalizedName;
			}

			// Leave non-variable elements to the serializer's default handling.
			return null;
		}).stripIndent().trim();
	}

	private static HashMap<String, String> getProducerQualifiedDatastoreKeysInput(AbstractStep step) {
		// Collect the names of all data inputs referenced by the assertion step.
		Set<String> variables = step.getInput().stream().map(binding -> binding.getName().getName())
				.collect(Collectors.toSet());

		// Resolve the assertion input to its producer-qualified datastore key.
		// Keep distinct keys so repeated references to the same datastore are harmless,
		// while references to different producers remain distinguishable.
		HashMap<String, String> datastoreNames = new LinkedHashMap<>();

		step.getStepRef().forEach(stepReference -> {
			AbstractStep producerStep = stepReference.getRefStep();
			String producerName = getConsumerName(producerStep);

			stepReference.getRefData().forEach(referencedData -> {
				String consumedData = referencedData.getName();
				if (variables.contains(consumedData)) {
					datastoreNames.put(consumedData, consumedData + "_" + producerName);
				}
			});
		});

		return datastoreNames;
	}

	private static HashMap<String, String> getProducerQualifiedDatastoreKeysOutput(AbstractStep step) {
		// Resolve the assertion input to its producer-qualified datastore key.
		// Keep distinct keys so repeated references to the same datastore are harmless,
		// while references to different producers remain distinguishable.
		HashMap<String, String> datastoreNames = new LinkedHashMap<>();

		step.getOutput().forEach(output -> {
			String producerName = getConsumerName(step);
			String producerData = output.getName().getName();
			datastoreNames.put(producerData, producerData + "_" + producerName);
		});

		return datastoreNames;
	}

	/**
	 * Creates the start event and registers it in the specified lane.
	 */
	private static StartEvent createStartEvent(BpmnModelInstance modelInstance, Process process, String laneName,
			Map<String, Lane> laneMap) {
		StartEvent startEvent = modelInstance.newInstance(StartEvent.class);
		startEvent.setId("startEvent");
		startEvent.setName("Start");
		process.addChildElement(startEvent);
		laneMap.get(laneName).getFlowNodeRefs().add(startEvent);
		return startEvent;
	}

	/**
	 * Creates the end event and registers it in the specified lane.
	 */
	private static EndEvent createEndEvent(BpmnModelInstance modelInstance, Process process, String laneName,
			Map<String, Lane> laneMap) {
		EndEvent endEvent = modelInstance.newInstance(EndEvent.class);
		endEvent.setId("endEvent");
		endEvent.setName("End");
		process.addChildElement(endEvent);
		laneMap.get(laneName).getFlowNodeRefs().add(endEvent);
		return endEvent;
	}

	/**
	 * Returns the type name declared by the datastore's producer binding. A
	 * non-null producer binding is expected.
	 */
	private static String getBindingType(DataInstanceDescriptor dsDescriptor) {
		TypeDecl b_type = dsDescriptor.bind_producer.getName().getType().getType();
		return b_type.getName();
	}

	/**
	 * Creates a semantic sequence flow and its four-waypoint DI edge.
	 *
	 * <p>
	 * The edge leaves the source's right-center, changes vertical level at the
	 * horizontal midpoint and enters the target's left-center. For elements on the
	 * same vertical level, the intermediate points are collinear.
	 * </p>
	 */
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

		// Source endpoint: center of the right boundary.
		Waypoint wp1 = modelInstance.newInstance(Waypoint.class);
		wp1.setX(sourceBounds.getX() + sourceBounds.getWidth());
		wp1.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		edge.getWaypoints().add(wp1);

		// First bend: retain the source height at the shared horizontal midpoint.
		double midpoint = (sourceBounds.getX() + sourceBounds.getWidth() + targetBounds.getX()) / 2;
		Waypoint wp2 = modelInstance.newInstance(Waypoint.class);
		wp2.setX(midpoint);
		wp2.setY(sourceBounds.getY() + sourceBounds.getHeight() / 2);
		edge.getWaypoints().add(wp2);

		// Second bend: move vertically to the target center height.
		Waypoint wp3 = modelInstance.newInstance(Waypoint.class);
		wp3.setX(midpoint);
		wp3.setY(targetBounds.getY() + targetBounds.getHeight() / 2);
		edge.getWaypoints().add(wp3);

		// Target endpoint: center of the left boundary.
		Waypoint wp4 = modelInstance.newInstance(Waypoint.class);
		wp4.setX(targetBounds.getX());
		wp4.setY(targetBounds.getY() + targetBounds.getHeight() / 2);
		edge.getWaypoints().add(wp4);

		plane.addChildElement(edge);
	}

	/**
	 * Creates a persistent datastore, its DI shape and associations to generated
	 * producer and consumer tasks.
	 *
	 * <p>
	 * Run and compose producers use output associations carrying datastore
	 * assignments. Each consumer receives an input association targeting a local
	 * property. Multiple such inputs expose the referenced data to a compose task.
	 * </p>
	 *
	 * @return the datastore reference, or {@code null} when neither a producer nor
	 *         a consumer can be resolved to a generated task
	 */
	private static DataStoreReference linkDataInstanceToTasks(BpmnModelInstance modelInstance, Definitions definitions,
			Process process, BpmnPlane plane, DataInstanceDescriptor dsDescriptor, Map<String, Task> taskMap,
			Map<BaseElement, Bounds> elemBounds, double x, double y) {
		boolean hasProducerTask = dsDescriptor.producer != null && taskMap.containsKey(dsDescriptor.producer);
		boolean hasConsumerTask = dsDescriptor.consumers.stream().anyMatch(taskMap::containsKey);

		// Skip descriptors that cannot be connected to any generated task.
		if (!hasProducerTask && !hasConsumerTask)
			return null;

		String dsId = normalizeBpmnId("dataobject_" + dsDescriptor.id);

		// 1. Create the semantic datastore and attach its declared type reference.
		DataStoreReference dsRef = modelInstance.newInstance(DataStoreReference.class);
		dsRef.setId(dsId + "_ref");
		dsRef.setName(normalizeTaskId(dsDescriptor.id));
		dsRef.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_DATATYPE_REF, getBindingType(dsDescriptor));
		// Legacy initialization path retained as documentation. Compose steps are
		// now explicit tasks, so active generation writes their output assignments
		// on DataOutputAssociation rather than setting dataStoreReference
		// documentation.
		String initializationAssignment = createUpdateAssignment(dsDescriptor);
		if (initializationAssignment != null) {
			Documentation doc = modelInstance.newInstance(Documentation.class);
			doc.setTextContent(initializationAssignment);
			dsRef.addChildElement(doc);
		}
		process.addChildElement(dsRef);

		// 2. Add the datastore shape at the previously calculated position.
		BpmnShape dsShape = modelInstance.newInstance(BpmnShape.class);
		dsShape.setId("shape_" + dsId);
		dsShape.setBpmnElement(dsRef);
		Bounds dsBounds = createBounds(modelInstance, x, y, DATA_SIZE, DATA_SIZE);
		dsShape.setBounds(dsBounds);

		plane.addChildElement(dsShape);

		// 3. Connect the run or compose producer to its output datastore.
		if (dsDescriptor.producer != null) {
			Task producer = taskMap.get(dsDescriptor.producer);
			if (producer != null) {
				DataOutputAssociation doa = modelInstance.newInstance(DataOutputAssociation.class);
				doa.setId("doa_" + dsId + "_" + producer.getId());
				doa.setTarget(dsRef);

				// Attach the serialized producer assignment to the output association.
				addBpmnExtension(doa, dsDescriptor);
				producer.addChildElement(doa);

				Bounds producerBounds = elemBounds.get(producer);

				// These indices and counts reflect associations attached so far, not
				// necessarily the final totals after every datastore has been linked.
				int outputIndex = getOutputIndex(producer, doa);
				int totalOutputs = countTotalOutputs(producer);
				int totalInputs = countTotalInputs(producer);
				createDataAssociationEdge(modelInstance, plane, doa, producerBounds, dsBounds, outputIndex,
						totalOutputs, 0, 1, totalOutputs, totalInputs);
			}
		}

		// 4. Connect the datastore to each generated consumer, including compose
		// tasks that receive referenced data from multiple producers.
		for (int consumerIdx = 0; consumerIdx < dsDescriptor.consumers.size(); consumerIdx++) {
			String consumerId = dsDescriptor.consumers.get(consumerIdx);
			Task consumer = taskMap.get(consumerId);
			if (consumer != null) {
				String dstaskLabel = dsId + "_" + consumer.getId();

				// Keep generated property and association ids distinct.
				String uid = "_" + UUID.randomUUID().toString();

				// Use a task-local property as the semantic input target.
				Property inputProp = modelInstance.newInstance(Property.class);
				inputProp.setId("prop_" + dstaskLabel + uid);
				inputProp.setName("input_" + dsDescriptor.id);
				consumer.addChildElement(inputProp);

				// Link the datastore value to the consumer's local input property.
				DataInputAssociation dia = modelInstance.newInstance(DataInputAssociation.class);
				dia.setId("dia_" + dstaskLabel + uid);
				dia.getSources().add(dsRef);
				dia.setTarget(inputProp);

				// BPMN4S reads are non-consuming: the stored value remains available
				// to other consumers.
				dia.setAttributeValueNs(XMLNS_BPMN4S, BPMN4S_PERSISTENT_READ, "true");

				// Apply an optional consumer-specific binding if supplied by the
				// descriptor. createDescriptors() above does not populate this map.
				Binding bind = dsDescriptor.bind_consumers.getOrDefault(consumer.getName(), null);
				if (bind != null) {
					addBpmnExtension(dia, bind);
				}

				consumer.addChildElement(dia);

				// Calculate endpoints using the currently attached task associations
				// and this consumer's position in the datastore consumer list.
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

	/**
	 * Creates a DI edge for a task-to-datastore output or datastore-to-task input.
	 *
	 * <p>
	 * Endpoint placement depends on source dimensions and connection indices.
	 * Intermediate orthogonal waypoints are calculated but are currently excluded
	 * from the emitted edge, which therefore contains only its two endpoints.
	 * </p>
	 */
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

		// Classify the source geometrically: current task shapes are taller than
		// 50 points, whereas datastore shapes are exactly 50 points high.
		boolean isTaskOutput = sourceBounds.getHeight() > 50;

		if (isTaskOutput) {

			// Select a restricted output region when the supplied counts indicate
			// both inputs and outputs. The counting helpers clamp zero counts to one,
			// so these values do not distinguish an absent association kind.
			int totalTaskInputs = totalTargetInputs;
			boolean taskHasBothInputsAndOutputs = (totalSourceOutputs > 0 && totalTaskInputs > 0);

			double offsetX;
			if (taskHasBothInputsAndOutputs) {
				// Use the leftmost 45% of the task's bottom edge.
				offsetX = calculateHorizontalOffsetInRegion(sourceConnectionIndex, totalSourceConnections, sourceWidth,
						0.0, 0.45);
			} else {
				// Use the standard distribution across the full edge's middle region.
				offsetX = calculateHorizontalOffset(sourceConnectionIndex, totalSourceConnections, sourceWidth);
			}
			double outputX = sourceBounds.getX() + offsetX;

			// Determine the arrival position across the datastore's top edge.
			double targetOffsetX = calculateHorizontalOffset(targetConnectionIndex, totalTargetConnections,
					targetWidth);
			double arrivalX = targetBounds.getX() + targetOffsetX;

			// Output endpoint on the task's bottom boundary.
			wp1.setX(outputX);
			wp1.setY(sourceBottomY);

			// Calculate staggered bends for the currently disabled orthogonal route.
			wp2.setX(outputX);
			wp2.setY(sourceBottomY + 20 + (sourceConnectionIndex * 10));

			wp3.setX(arrivalX);
			wp3.setY(wp2.getY());

			// Arrival endpoint just above the datastore's top boundary.
			wp4.setX(arrivalX);
			wp4.setY(targetTopY - 1);
		} else {

			// Datastore inputs leave the store's bottom edge and enter the task at
			// its top edge. This also applies to compose tasks receiving run outputs.
			double sourceOffsetX = calculateHorizontalOffset(sourceConnectionIndex, totalSourceConnections,
					sourceWidth);
			double exitX = sourceBounds.getX() + sourceOffsetX;

			// Select the right input region when the supplied counts indicate both
			// input and output associations. Counts may be clamped to one by callers.
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

			// Calculate a staggered bend level above both endpoint heights. This
			// affects the edge only if intermediate waypoints are emitted below.
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

		// Emit a direct segment between the calculated endpoints. Keep the
		// intermediate waypoints disabled to preserve the current rendering.
		edge.getWaypoints().addAll(Arrays.asList(wp1,
				// wp2, wp3,
				wp4));

		plane.addChildElement(edge);
	}

	// Return the number of currently attached output associations, clamped to at
	// least one for connection-slot calculations. This is not a raw zero-aware
	// count.
	private static int countTotalOutputs(Task task) {
		int count = task.getChildElementsByType(DataOutputAssociation.class).size();
		return Math.max(1, count);
	}

	// Return the number of currently attached input associations, clamped to at
	// least one for connection-slot calculations. This is not a raw zero-aware
	// count.
	private static int countTotalInputs(Task task) {
		int count = task.getChildElementsByType(DataInputAssociation.class).size();
		return Math.max(1, count);
	}

	// Find an output association's zero-based position in the task's current
	// association collection; use the first slot if it is not found.
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

	// Find an input association's zero-based position in the task's current
	// association collection; use the first slot if it is not found.
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

	// Center a single connection or distribute multiple connections across the
	// middle 60% of the edge, leaving a 20% margin on either side.
	// Callers are expected to provide total >= 1 and a valid zero-based index.
	private static double calculateHorizontalOffset(int index, int total, double width) {
		if (total == 1) {
			return width / 2.0;
		}

		double usableWidth = width * 0.6;
		double margin = width * 0.2;
		double spacing = usableWidth / (total - 1);

		return margin + (index * spacing);
	}

	/**
	 * Calculates a connection offset within a fractional subsection of an edge.
	 *
	 * <p>
	 * A single connection is centered in the region. Multiple connections use its
	 * middle 80%, leaving a 10% margin at each end of the region. Callers must
	 * supply a positive total and a valid zero-based connection index.
	 * </p>
	 *
	 * @param regionStart fractional start of the selected region
	 * @param regionEnd   fractional end of the selected region
	 */
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
}