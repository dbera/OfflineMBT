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
package nl.esi.comma.scenarios.generator.causalgraph;

import java.util.HashSet;
import java.util.Set;

import nl.esi.comma.scenarios.scenarios.Attribute;
import nl.esi.comma.scenarios.scenarios.KEY_ID;
import nl.esi.comma.scenarios.scenarios.SpecFlowScenario;

public class Feature {
	public String ID;
	public String name;
	public String path;
	public Set<String> productSet = new HashSet<String>();
	
	public Feature(SpecFlowScenario scn) {
		for (Attribute attr : scn.getFeatureAttributes()) {
			if (attr.getKey() == KEY_ID.LOCATION) this.path = attr.getValue().get(0);
		}
		for (Attribute attr : scn.getScenarioAttributes()) {
			if (attr.getKey() == KEY_ID.SCN_NAME) this.name = attr.getValue().get(0);
		}
		this.ID = scn.getHID();
		scn.getEvents().forEach(a -> a.getProduct().forEach(p -> productSet.addAll(p.getValue())));
	}
}
