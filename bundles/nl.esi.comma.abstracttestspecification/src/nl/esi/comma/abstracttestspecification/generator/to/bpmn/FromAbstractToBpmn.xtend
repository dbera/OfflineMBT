/**
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
package nl.esi.comma.abstracttestspecification.generator.to.bpmn

import org.camunda.bpm.model.bpmn.BpmnModelInstance;

import nl.esi.comma.abstracttestspecification.abstractTestspecification.TSMain
import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractTestDefinition

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.abstracttestspecification.generator.utils.Utils.*
import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import org.camunda.bpm.model.bpmn.Bpmn
import org.camunda.bpm.model.bpmn.instance.Definitions
import org.camunda.bpm.model.bpmn.instance.Collaboration
import org.camunda.bpm.model.bpmn.instance.Process
import org.camunda.bpm.model.bpmn.instance.Participant
import org.camunda.bpm.model.bpmn.instance.Task
import org.camunda.bpm.model.bpmn.instance.SequenceFlow
import static org.camunda.bpm.model.bpmn.impl.BpmnModelConstants.CAMUNDA_NS
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnPlane
import org.camunda.bpm.model.bpmn.instance.bpmndi.BpmnDiagram
import org.camunda.bpm.model.bpmn.instance.LaneSet
import org.camunda.bpm.model.bpmn.instance.Lane

class FromAbstractToBpmn extends AbstractGenerator {
    
    
    final static String XMLNS_XSI="http://www.w3.org/2001/XMLSchema-instance" 
    final static String XMLNS_DI="http://www.omg.org/spec/DD/20100524/DI" 
    final static String XMLNS_DC="http://www.omg.org/spec/DD/20100524/DC" 
    final static String XMLNS_COLOR="http://www.omg.org/spec/BPMN/non-normative/color/1.0" 
    final static String XMLNS_BPMNDI="http://www.omg.org/spec/BPMN/20100524/DI" 
    final static String XMLNS_BPMN4S="http://bpmn4s" 
    final static String XMLNS_BPMN2="http://www.omg.org/spec/BPMN/20100524/MODEL" 
    final static String XMLNS_BIOC="http://bpmn.io/schema/bpmn/biocolor/1.0"

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val atd = res.contents.filter(TSMain).map[model].filter(AbstractTestDefinition).head
        if (atd === null) {
            throw new Exception('No abstract tspec found in resource: ' + res.URI)
        }

        val conTspecFileName = res.URI.lastSegment.replaceAll('\\.atspec$','.bpmn')
        fsa.generateFile(conTspecFileName, atd.generateBPMNModel())
    }
    
    
    
    def public generateBPMNModel(AbstractTestDefinition atd) {
//        var BpmnModelInstance modelInstance = Bpmn.createProcess()
//        .startEvent()
//        .sendTask('task_a')
//        .sendTask('task_b')
//        .sendTask('task_c')
//        .sendTask('task_d')
//        .endEvent()
//        .done();
        var BpmnModelInstance modelInstance = Bpmn.createEmptyModel();

        var Definitions definitions = modelInstance.newInstance(Definitions);
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

        var BpmnDiagram bpmnDiagram = modelInstance.newInstance(BpmnDiagram);

        var BpmnPlane bpmnPlane = modelInstance.newInstance(BpmnPlane);

        definitions.addChildElement(bpmnDiagram);
        bpmnDiagram.addChildElement(bpmnPlane);

        // Create collaboration
        var Collaboration collaboration = modelInstance.newInstance(Collaboration);
        collaboration.setId("collaboration");
        definitions.addChildElement(collaboration);

        // Create the process
        var Process process = modelInstance.newInstance(Process);
        process.setId("laneProcess");
        process.setExecutable(true);
        definitions.addChildElement(process);
        
        bpmnPlane.setBpmnElement(process);
        
        // Create a lane set
        var LaneSet laneSet = modelInstance.newInstance(LaneSet);
        laneSet.setId("laneSet");
        process.addChildElement(laneSet);
        
        // Create Lane 1
        var Lane lane1 = modelInstance.newInstance(Lane);
        lane1.setId("Lane_1b5mqqr");
        lane1.setName("lane a and d");
        laneSet.addChildElement(lane1);

//        // Create Lane 2
//        var Lane lane2 = modelInstance.newInstance(Lane);
//        lane2.setId("Lane_07j5dxz");
//        lane2.setName("lane b with data store");
//        laneSet.addChildElement(lane2);
//
//        // Create Lane 3
//        var Lane lane3 = modelInstance.newInstance(Lane);
//        lane3.setId("Lane_16fpfh0");
//        lane3.setName("lane c");
//        laneSet.addChildElement(lane3);

        // Create tasks
        var Task taskA = modelInstance.newInstance(Task);
        taskA.setId("task_a");
        taskA.setName("Task A");
        process.addChildElement(taskA);
        lane1.getFlowNodeRefs().add(taskA);
//
//        var Task taskB = modelInstance.newInstance(Task);
//        taskB.setId("task_b");
//        taskB.setName("Task B");
//        process.addChildElement(taskB);
//        lane2.getFlowNodeRefs().add(taskB);
//
//        var Task taskC = modelInstance.newInstance(Task);
//        taskC.setId("task_c");
//        taskC.setName("Task C");
//        process.addChildElement(taskC);
//        lane3.getFlowNodeRefs().add(taskC);
//
//        var Task taskD = modelInstance.newInstance(Task);
//        taskD.setId("task_d");
//        taskD.setName("Task D");
//        process.addChildElement(taskD);
//        lane1.getFlowNodeRefs().add(taskD);


//        // Create the BPMN diagram elements
//        var BpmnPlane plane = modelInstance.newInstance(BpmnPlane);
//        plane.setBpmnElement(process);
//        
//        var BpmnDiagram diagram = modelInstance.newInstance(BpmnDiagram);
//        diagram.setId("BPMNDiagram_lane");
//        diagram.addChildElement(plane);
//        definitions.addChildElement(diagram);
//
//        // Create a lane set
//        var LaneSet laneSet = modelInstance.newInstance(LaneSet);
//        laneSet.setId("laneSet");
//        process.addChildElement(laneSet);
//
//        // Create Lane 1 (task_a and task_c)
//        var Lane lane1 = modelInstance.newInstance(Lane);
//        lane1.setId("lane1");
//        lane1.setName("Lane A+C");
//        laneSet.addChildElement(lane1);
//
//        // Create Lane 2 (task_b)
//        var Lane lane2 = modelInstance.newInstance(Lane);
//        lane2.setId("lane2");
//        lane2.setName("Lane B");
//        laneSet.addChildElement(lane2);
//
//        // Create tasks
//        var Task taskA = modelInstance.newInstance(Task);
//        taskA.setId("task_a");
//        taskA.setName("Task A");
//        process.addChildElement(taskA);
//        lane1.getFlowNodeRefs().add(taskA);
//
//        var Task taskB = modelInstance.newInstance(Task);
//        taskB.setId("task_b");
//        taskB.setName("Task B");
//        process.addChildElement(taskB);
//        lane2.getFlowNodeRefs().add(taskB);
//
//        var Task taskC = modelInstance.newInstance(Task);
//        taskC.setId("task_c");
//        taskC.setName("Task C");
//        process.addChildElement(taskC);
//        lane1.getFlowNodeRefs().add(taskC);
//
//        // Connect tasks with sequence flows
//        var SequenceFlow flowAB = modelInstance.newInstance(SequenceFlow);
//        flowAB.setId("flow_ab");
//        flowAB.setSource(taskA);
//        flowAB.setTarget(taskB);
//        process.addChildElement(flowAB);
//        taskA.getOutgoing().add(flowAB);
//        taskB.getIncoming().add(flowAB);
//
//        var SequenceFlow flowBC = modelInstance.newInstance(SequenceFlow);
//        flowBC.setId("flow_bc");
//        flowBC.setSource(taskB);
//        flowBC.setTarget(taskC);
//        process.addChildElement(flowBC);
//        taskB.getOutgoing().add(flowBC);
//        taskC.getIncoming().add(flowBC);
        
        return Bpmn.convertToString(modelInstance)
    }
}
