package nl.asml.matala.bpmn4s.extensions;

import org.camunda.bpm.model.bpmn.instance.BpmnModelElementInstance;

public interface Field extends BpmnModelElementInstance {
//	Extensions 	getExtensions();
	String 		getTypeRef();
	String 		getName();
}
