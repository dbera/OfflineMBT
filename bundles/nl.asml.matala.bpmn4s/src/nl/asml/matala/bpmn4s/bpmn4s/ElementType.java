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
package nl.asml.matala.bpmn4s.bpmn4s;

public enum ElementType {
	COMPONENT,
	ACTIVITY,
	TASK,
	RUN_TASK,
	COMPOSE_TASK,
	ASSERT_TASK,
	START_EVENT,
	END_EVENT,
	AND_GATE,
	XOR_GATE,
	DATASTORE,
	MSGQUEUE,
	EDGE,
	DATATYPE,
	NONE
}