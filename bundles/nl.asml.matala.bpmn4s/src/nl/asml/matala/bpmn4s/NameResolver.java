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
package nl.asml.matala.bpmn4s;

import org.camunda.bpm.model.bpmn.instance.DataInput;
import org.camunda.bpm.model.bpmn.instance.DataOutput;
import org.camunda.bpm.model.bpmn.instance.DataStore;
import org.camunda.bpm.model.bpmn.instance.FlowElement;
import org.camunda.bpm.model.bpmn.instance.ItemAwareElement;
import org.camunda.bpm.model.bpmn.instance.Property;

public class NameResolver {
	public static final String getName(ItemAwareElement element) {
		return switch (element) {
			case FlowElement e -> e.getName();
			case DataInput e -> e.getName();
			case DataOutput e -> e.getName();
			case DataStore e -> e.getName();
			case Property e -> e.getName();
			default -> throw new IllegalArgumentException("Unknown type: " + element.getClass().getName());
		};
	}
}
