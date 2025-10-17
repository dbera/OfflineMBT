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

import java.util.List;

public class DataInstanceDescriptor extends ElementDescriptor {

	public List<String> consumers;
	public String producer;

	public DataInstanceDescriptor(String id,String lane, String producer, List<String> consumers) {
    	super(id,lane);
        this.producer = producer;
        this.consumers = consumers;
    }
}