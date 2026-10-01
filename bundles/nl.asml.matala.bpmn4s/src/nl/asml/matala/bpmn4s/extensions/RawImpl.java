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

public class RawImpl extends ExtensionElementsImpl implements Raw{

	protected static Attribute<String> id;
	protected static Attribute<String> name;
	protected static Attribute<String> type;
	protected static Attribute<String> keyTypeRef;
	protected static Attribute<String> valueTypeRef;
	public RawImpl(ModelTypeInstanceContext instanceContext) {
		super(instanceContext);
	}
	
	public static void registerType(ModelBuilder modelBuilder) {
		ModelElementTypeBuilder typeBuilder = modelBuilder.defineType(DataType.class, RAW_TYPE)
	      .namespaceUri(BPMN4S_NS)
	      .instanceProvider(new ModelTypeInstanceProvider<Raw>() {
	        public Raw newInstance(ModelTypeInstanceContext instanceContext) {
	          return new RawImpl(instanceContext);
	        }
	      });
	    typeBuilder.build();
	}

	
	@Override
	public String getValue() {
		return this.getTextContent();
	}
}
