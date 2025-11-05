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

import static nl.asml.matala.bpmn4s.extensions.Constants.BPMN4S_NS;
import static nl.asml.matala.bpmn4s.extensions.Constants.DATATYPES_TYPE;

import java.util.Collection;

import org.camunda.bpm.model.bpmn.impl.instance.ExtensionElementsImpl;
import org.camunda.bpm.model.bpmn.instance.ExtensionElements;
import org.camunda.bpm.model.xml.ModelBuilder;
import org.camunda.bpm.model.xml.impl.instance.ModelTypeInstanceContext;
import org.camunda.bpm.model.xml.type.ModelElementType;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder.ModelTypeInstanceProvider;
import org.camunda.bpm.model.xml.type.child.ChildElement;

public class DataTypesImpl extends ExtensionElementsImpl implements DataTypes {


	private static ChildElement<DataType> datatype;

	public DataTypesImpl(ModelTypeInstanceContext instanceContext) {
		super(instanceContext);
	}

	public static void registerType(ModelBuilder modelBuilder) {
		ModelElementTypeBuilder typeBuilder = modelBuilder.defineType(DataTypes.class, DATATYPES_TYPE)
				.namespaceUri(BPMN4S_NS)
				.instanceProvider(new ModelTypeInstanceProvider<DataTypes>() {
					public DataTypes newInstance(ModelTypeInstanceContext instanceContext) {
						return new DataTypesImpl(instanceContext);
					}
				});

		datatype = typeBuilder.sequence().element(DataType.class).build();
		typeBuilder.build();

	}

	@Override
	public Collection<DataType> getDataType() {
		return datatype.get(this);
	}

}
