package nl.asml.matala.bpmn4s;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

import org.camunda.bpm.model.bpmn.BpmnModelInstance;
import org.camunda.bpm.model.bpmn.instance.BoundaryEvent;
import org.camunda.bpm.model.bpmn.instance.DataObjectReference;
import org.camunda.bpm.model.bpmn.instance.DataStoreReference;
import org.camunda.bpm.model.bpmn.instance.EndEvent;
import org.camunda.bpm.model.bpmn.instance.ExclusiveGateway;
import org.camunda.bpm.model.bpmn.instance.InclusiveGateway;
import org.camunda.bpm.model.bpmn.instance.IntermediateCatchEvent;
import org.camunda.bpm.model.bpmn.instance.IntermediateThrowEvent;
import org.camunda.bpm.model.bpmn.instance.ParallelGateway;
import org.camunda.bpm.model.bpmn.instance.SequenceFlow;
import org.camunda.bpm.model.bpmn.instance.ServiceTask;
import org.camunda.bpm.model.bpmn.instance.StartEvent;
import org.camunda.bpm.model.bpmn.instance.SubProcess;
import org.camunda.bpm.model.bpmn.instance.Task;

public class BPMN4SParser {
	
	public void logInfo(String str) { System.out.println(str); }
	
	public StartEvent getStartElement(BpmnModelInstance modelInst) {
		Collection<StartEvent> se = modelInst.getModelElementsByType(StartEvent.class);
		if(se.size() == 1) return se.iterator().next();
		else if(se.size() > 1) logInfo("[ERROR] More than one start element in BPMN model");
		return null;
	}
	
	public Collection<SubProcess> getSubProcesses(BpmnModelInstance modelInst){
		return modelInst.getModelElementsByType(SubProcess.class);
	}
	
	public Collection<StartEvent> getStartEvents(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(StartEvent.class);		
	}
	
	public Collection<EndEvent> getEndEvents(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(EndEvent.class);		
	}
	
	public Collection<ServiceTask> getServiceTask(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(ServiceTask.class);
	}
	
	public Collection<Task> getTask(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(Task.class);
	}
	
	public Collection<ParallelGateway> getParallelGateWay(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(ParallelGateway.class);
	}
	
	public Collection<ExclusiveGateway> getExclusiveGateWay(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(ExclusiveGateway.class);
	}
	
	public Collection<InclusiveGateway> getInclusiveGateWay(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(InclusiveGateway.class);
	}
	
	public Collection<DataStoreReference> getDataStoreReference(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(DataStoreReference.class);
	}
	
	public Collection<DataObjectReference> getDataObjectReference(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(DataObjectReference.class);
	}
	
	public Collection<BoundaryEvent> getBoundaryEvents(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(BoundaryEvent.class);
	}
	
	public Collection<IntermediateCatchEvent> getCatchEvents(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(IntermediateCatchEvent.class);
	}
	
	public Collection<IntermediateThrowEvent> getThrowEvents(BpmnModelInstance modelInst) {
		return modelInst.getModelElementsByType(IntermediateThrowEvent.class);
	}
	
	public Set<String> getTargetsOfTask(Task t) {
		Set<String> ttList = new HashSet<String>(); 
		for(SequenceFlow sf : t.getOutgoing()) {
			ttList.add(getTargetTaskName(sf));   					
		}
		return ttList;
	}
	
	public Set<String> getDataInputsOfTask(Task t) {
		return null;
	}
	
	public Set<String> getDataOutputsOfTask(Task t) {
		return null;
	}

	public Set<String> getTargetsOfServiceTask(ServiceTask t) {
		Set<String> ttList = new HashSet<String>(); 
		for(SequenceFlow sf : t.getOutgoing()) {
			ttList.add(getTargetTaskName(sf));   					
		}
		return ttList;
	}
	
	public Set<String> getDataInputsOfServiceTask(ServiceTask t) {
		//TODO
		return null;
	}
	
	public Set<String> getDataOutputsOfServiceTask(ServiceTask t) {
		//TODO
		return null;
	}
	
	public Set<String> getTargetsOfExGate(ExclusiveGateway eg) {
		Set<String> ttList = new HashSet<String>(); 
		for(SequenceFlow sf : eg.getOutgoing()) {
			ttList.add(getTargetTaskName(sf));   					
		}
		return ttList;
	}
	
	public Set<String> getTargetsOfParGate(ParallelGateway pg) {
		Set<String> ttList = new HashSet<String>(); 
		for(SequenceFlow sf : pg.getOutgoing()) {
			ttList.add(getTargetTaskName(sf));   					
		}
		return ttList;
	}
	
	public Set<String> getTargetsOfDS(DataStoreReference dsr) {
		Set<String> ttList = new HashSet<String>();
		/*
		for(SequenceFlow sf : dsr.getOutgoing()) {
			ttList.add(getTargetTaskName(sf));   					
		}*/
		return ttList;
	}
	
	public String getTargetTaskName(SequenceFlow sf) {
		String targetTaskType = sf.getTarget().getElementType().getTypeName();
		if(targetTaskType.equals("task"))
			return sf.getTarget().getName();
		else if(targetTaskType.equals("serviceTask"))
			return sf.getTarget().getName();
		else if(targetTaskType.equals("parallelGateway"))
			return sf.getTarget().getId();
		else if(targetTaskType.equals("inclusiveGateway"))
			return sf.getTarget().getId();
		else return new String();				
	}
}
