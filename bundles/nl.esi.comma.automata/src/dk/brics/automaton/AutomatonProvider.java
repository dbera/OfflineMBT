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
package dk.brics.automaton;

import java.io.IOException;

/**
 * Automaton provider for <code>RegExp.</code>{@link RegExp#toAutomaton(AutomatonProvider)}
 */
public interface AutomatonProvider {
	
	/**
	 * Returns automaton of the given name.
	 * @param name automaton name
	 * @return automaton
	 * @throws IOException if errors occur
	 */
	Automaton getAutomaton(String name) throws IOException;
}
