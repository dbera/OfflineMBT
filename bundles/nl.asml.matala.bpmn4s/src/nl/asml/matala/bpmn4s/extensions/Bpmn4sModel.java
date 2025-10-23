package nl.asml.matala.bpmn4s.extensions;

import org.camunda.bpm.model.bpmn.Bpmn;
import org.camunda.bpm.model.bpmn.BpmnModelInstance;
import org.camunda.bpm.model.xml.ModelBuilder;

public class Bpmn4sModel extends Bpmn {

	public static Bpmn4sModel INSTANCE = new Bpmn4sModel();

	@Override
	protected void doRegisterTypes(ModelBuilder bpmnModelBuilder) {
		super.doRegisterTypes(bpmnModelBuilder);
		DataTypeImpl.registerType(bpmnModelBuilder);
		DataTypesImpl.registerType(bpmnModelBuilder);
		FieldImpl.registerType(bpmnModelBuilder);
		LiteralImpl.registerType(bpmnModelBuilder);
		TargetDataRefImpl.registerType(bpmnModelBuilder);
	}
	
	public static BpmnModelInstance createEmptyBpmn4sModel() {
	    return INSTANCE.doCreateEmptyModel();
	  }
}
