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
package nl.asml.matala.bpmn4s.extensions;

import static nl.asml.matala.bpmn4s.extensions.Constants.ATTRIBUTE_NAME;
import static nl.asml.matala.bpmn4s.extensions.Constants.ATTRIBUTE_TYPEREF;
import static nl.asml.matala.bpmn4s.extensions.Constants.FIELD_TYPE;
import static nl.asml.matala.bpmn4s.extensions.Constants.BPMN4S_NS;

import org.camunda.bpm.model.bpmn.impl.instance.BpmnModelElementInstanceImpl;
import org.camunda.bpm.model.xml.ModelBuilder;
import org.camunda.bpm.model.xml.impl.instance.ModelTypeInstanceContext;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder.ModelTypeInstanceProvider;
import org.camunda.bpm.model.xml.type.attribute.Attribute;
//import org.camunda.bpm.model.xml.type.child.ChildElement;
//import org.camunda.bpm.model.xml.type.child.SequenceBuilder;
public class FieldImpl extends BpmnModelElementInstanceImpl implements Field{

//	protected static ChildElement<Extensions> extensions;
	protected static Attribute<String> typeRef;
	protected static Attribute<String> name;
	public FieldImpl(ModelTypeInstanceContext instanceContext) {
		super(instanceContext);
	}
	
	public static void registerType(ModelBuilder modelBuilder) {
		ModelElementTypeBuilder typeBuilder = modelBuilder.defineType(Field.class, FIELD_TYPE)
	      .namespaceUri(BPMN4S_NS)
	      .instanceProvider(new ModelTypeInstanceProvider<Field>() {
	        public Field newInstance(ModelTypeInstanceContext instanceContext) {
	          return new FieldImpl(instanceContext);
	        }
	      });
		name = typeBuilder.stringAttribute(ATTRIBUTE_NAME)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		typeRef = typeBuilder.stringAttribute(ATTRIBUTE_TYPEREF)
		  .namespace(BPMN4S_NS)
	      .required()
	      .build();
//		SequenceBuilder sequenceBuilder = typeBuilder.sequence();
//		extensions = sequenceBuilder.element(Extensions.class).build();
	    typeBuilder.build();
	}

//	@Override
//	public Extensions getExtensions() {
//		return extensions.getChild(this);
//	}

	@Override
	public String getTypeRef() {
		return typeRef.getValue(this);
	}

	@Override
	public String getName() {
		return name.getValue(this);
	}

}
