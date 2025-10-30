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
import static nl.asml.matala.bpmn4s.extensions.Constants.ATTRIBUTE_TYPE;
import static nl.asml.matala.bpmn4s.extensions.Constants.DATATYPE_TYPE;
import static nl.asml.matala.bpmn4s.extensions.Constants.BPMN4S_NS;

import org.camunda.bpm.model.bpmn.impl.instance.BpmnModelElementInstanceImpl;
import org.camunda.bpm.model.bpmn.impl.instance.ExtensionElementsImpl;
import org.camunda.bpm.model.xml.ModelBuilder;
import org.camunda.bpm.model.xml.impl.instance.ModelTypeInstanceContext;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder.ModelTypeInstanceProvider;
import org.camunda.bpm.model.xml.type.attribute.Attribute;

public class DataTypeImpl extends ExtensionElementsImpl implements DataType{

	protected static Attribute<String> type;
	protected static Attribute<String> name;
	public DataTypeImpl(ModelTypeInstanceContext instanceContext) {
		super(instanceContext);
	}
	
	public static void registerType(ModelBuilder modelBuilder) {
		ModelElementTypeBuilder typeBuilder = modelBuilder.defineType(DataType.class, DATATYPE_TYPE)
	      .namespaceUri(BPMN4S_NS)
	      .instanceProvider(new ModelTypeInstanceProvider<DataType>() {
	        public DataType newInstance(ModelTypeInstanceContext instanceContext) {
	          return new DataTypeImpl(instanceContext);
	        }
	      });
		name = typeBuilder.stringAttribute(ATTRIBUTE_NAME)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		type = typeBuilder.stringAttribute(ATTRIBUTE_TYPE)
		  .namespace(BPMN4S_NS)
	      .required()
	      .build();

	    typeBuilder.build();
	}


	@Override
	public String getType() {
		return type.getValue(this);
	}

	@Override
	public String getName() {
		return name.getValue(this);
	}

}
