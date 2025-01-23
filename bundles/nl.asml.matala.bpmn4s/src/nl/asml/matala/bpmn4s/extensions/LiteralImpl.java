package nl.asml.matala.bpmn4s.extensions;

import static nl.asml.matala.bpmn4s.extensions.Constants.ATTRIBUTE_NAME;
import static nl.asml.matala.bpmn4s.extensions.Constants.ATTRIBUTE_VALUE;
import static nl.asml.matala.bpmn4s.extensions.Constants.LITERAL_TYPE;
import static nl.asml.matala.bpmn4s.extensions.Constants.BPMN4S_NS;

import org.camunda.bpm.model.bpmn.impl.instance.BpmnModelElementInstanceImpl;
import org.camunda.bpm.model.xml.ModelBuilder;
import org.camunda.bpm.model.xml.impl.instance.ModelTypeInstanceContext;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder.ModelTypeInstanceProvider;
import org.camunda.bpm.model.xml.type.attribute.Attribute;

public class LiteralImpl extends BpmnModelElementInstanceImpl implements Literal{

	protected static Attribute<String> value;
	protected static Attribute<String> name;
	public LiteralImpl(ModelTypeInstanceContext instanceContext) {
		super(instanceContext);
	}
	
	public static void registerType(ModelBuilder modelBuilder) {
		ModelElementTypeBuilder typeBuilder = modelBuilder.defineType(Literal.class, LITERAL_TYPE)
	      .namespaceUri(BPMN4S_NS)
	      .instanceProvider(new ModelTypeInstanceProvider<Literal>() {
	        public Literal newInstance(ModelTypeInstanceContext instanceContext) {
	          return new LiteralImpl(instanceContext);
	        }
	      });
		name = typeBuilder.stringAttribute(ATTRIBUTE_NAME)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		value = typeBuilder.stringAttribute(ATTRIBUTE_VALUE)
		  .namespace(BPMN4S_NS)
	      .required()
	      .build();

	    typeBuilder.build();
	}

	@Override
	public String getValue() {
		return value.getValue(this);
	}

	@Override
	public String getName() {
		return name.getValue(this);
	}

}
