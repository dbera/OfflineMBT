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
package nl.esi.comma.causalgraph.generator;

import java.util.Arrays;
import java.util.stream.Collectors;

public class StringHelper 
{
	String makeCaps(String input) {
	    if (input == null || input.isEmpty()) {
	        return null;
	    }

	    return Arrays.stream(input.split("\\s+"))
	      .map(word -> Character.toUpperCase(word.charAt(0)) + word.substring(1))
	      .collect(Collectors.joining(" "));
	}
}
