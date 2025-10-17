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
package nl.esi.comma.abstracttestspecification.generator.to.bpmn;

import nl.esi.comma.abstracttestspecification.abstractTestspecification.AbstractStep;

public class TaskDescriptor extends ElementDescriptor {
	
	public AbstractStep step;

	public TaskDescriptor(String id, String lane) {
		super(id, lane);
	}
}