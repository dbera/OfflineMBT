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
