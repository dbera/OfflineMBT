package nl.asml.matala.bpmn4s.extensions;

import org.camunda.bpm.model.bpmn.instance.BpmnModelElementInstance;

public interface DataType extends BpmnModelElementInstance {
//	Extensions 	getExtensions();
	String 		getType();
	String 		getName();
}
