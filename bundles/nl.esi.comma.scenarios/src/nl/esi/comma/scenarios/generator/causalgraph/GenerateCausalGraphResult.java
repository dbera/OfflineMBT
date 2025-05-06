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

public class GenerateCausalGraphResult {
	public final CharSequence graphModel;
	public final CausalFootprint footprint;
	public final CausalGraph causalGraph;
	
	public GenerateCausalGraphResult(CharSequence graphModel, CausalFootprint footprint, CausalGraph causalGraph) {
		this.graphModel = graphModel;
		this.footprint = footprint;
		this.causalGraph = causalGraph;
	}
}
