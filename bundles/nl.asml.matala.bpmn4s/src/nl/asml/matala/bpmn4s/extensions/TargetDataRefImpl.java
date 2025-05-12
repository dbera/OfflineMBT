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

import org.camunda.bpm.model.bpmn.impl.instance.BpmnModelElementInstanceImpl;
import org.camunda.bpm.model.xml.ModelBuilder;
import org.camunda.bpm.model.xml.impl.instance.ModelTypeInstanceContext;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder;
import org.camunda.bpm.model.xml.type.ModelElementTypeBuilder.ModelTypeInstanceProvider;

public class TargetDataRefImpl extends BpmnModelElementInstanceImpl implements TargetDataRef {
		
	public TargetDataRefImpl(ModelTypeInstanceContext instanceContext) {
		super(instanceContext);
	}
		
	public static void registerType(ModelBuilder modelBuilder) {
		ModelElementTypeBuilder typeBuilder = modelBuilder
				.defineType(TargetDataRef.class, "targetDataRef")
				.namespaceUri(BPMN4S_NS)
				.instanceProvider(new ModelTypeInstanceProvider<TargetDataRef>() {
					public TargetDataRef newInstance(ModelTypeInstanceContext instanceContext) {
				      return new TargetDataRefImpl(instanceContext);
				}
			});

		typeBuilder.build();
	}

}
