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

/**
 * Automaton provider based on {@link Datatypes}.
 */
public class DatatypesAutomatonProvider implements AutomatonProvider {
	
	private boolean enable_unicodeblocks, enable_unicodecategories, enable_xml;
	
	/**
	 * Constructs a new automaton provider that recognizes all names
	 * from {@link Datatypes#get(String)}.
	 */
	public DatatypesAutomatonProvider() {
		enable_unicodeblocks = enable_unicodecategories = enable_xml = true;
	}
	
	/**
	 * Constructs a new automaton provider that recognizes some of the names
	 * from {@link Datatypes#get(String)}
	 * @param enable_unicodeblocks if true, enable Unicode block names
	 * @param enable_unicodecategories if true, enable Unicode category names
	 * @param enable_xml if true, enable XML related names
	 */
	public DatatypesAutomatonProvider(boolean enable_unicodeblocks, boolean enable_unicodecategories, boolean enable_xml) {
		this.enable_unicodeblocks = enable_unicodeblocks; 
		this.enable_unicodecategories = enable_unicodecategories;
		this.enable_xml = enable_xml;
	}
	
	public Automaton getAutomaton(String name) {
		if ((enable_unicodeblocks && Datatypes.isUnicodeBlockName(name))
				|| (enable_unicodecategories && Datatypes.isUnicodeCategoryName(name))
				|| (enable_xml && Datatypes.isXMLName(name)))
				return Datatypes.get(name);
		return null;
	}
}
