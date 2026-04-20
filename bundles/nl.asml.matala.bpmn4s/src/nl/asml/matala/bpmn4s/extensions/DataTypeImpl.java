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

import static nl.asml.matala.bpmn4s.extensions.Constants.*;

import org.camunda.bpm.model.bpmn.impl.instance.ExtensionElementsImpl;
import org.camunda.bpm.model.xml.ModelBuilder;
import org.camunda.bpm.model.xml.impl.instance.ModelTypeInstanceContext;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder.ModelTypeInstanceProvider;
import org.camunda.bpm.model.xml.type.attribute.Attribute;

public class DataTypeImpl extends ExtensionElementsImpl implements DataType{

	protected static Attribute<String> id;
	protected static Attribute<String> name;
	protected static Attribute<String> type;
	protected static Attribute<String> keyTypeRef;
	protected static Attribute<String> valueTypeRef;
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
		id = typeBuilder.stringAttribute(ATTRIBUTE_ID)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		name = typeBuilder.stringAttribute(ATTRIBUTE_NAME)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		type = typeBuilder.stringAttribute(ATTRIBUTE_TYPE)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		keyTypeRef = typeBuilder.stringAttribute(ATTRIBUTE_KEYTYPEREF)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();
		valueTypeRef = typeBuilder.stringAttribute(ATTRIBUTE_VALUETYPEREF)
				  .namespace(BPMN4S_NS)
			      .required()
			      .build();

	    typeBuilder.build();
	}

	public String getId() {
		return id.getValue(this);
	}

	@Override
	public String getName() {
		return name.getValue(this);
	}

	@Override
	public String getType() {
		return type.getValue(this);
	}
	
	@Override
	public String getKeyTypeRef() {
		return keyTypeRef.getValue(this);
	}
	
	@Override
	public String getValueTypeRef() {
		return valueTypeRef.getValue(this);
	}
}
