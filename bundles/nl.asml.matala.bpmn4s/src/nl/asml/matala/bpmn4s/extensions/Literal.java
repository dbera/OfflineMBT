package nl.asml.matala.bpmn4s.extensions;

import org.camunda.bpm.model.bpmn.instance.BpmnModelElementInstance;

public interface Literal extends BpmnModelElementInstance {
	String 		getName();
	String 		getValue();
}
