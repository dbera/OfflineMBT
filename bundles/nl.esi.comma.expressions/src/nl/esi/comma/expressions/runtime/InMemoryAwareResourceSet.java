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
package nl.esi.comma.expressions.runtime;

import org.eclipse.xtext.resource.SynchronizedXtextResourceSet;

import com.google.inject.Inject;

import nl.esi.comma.expressions.functions.InMemoryExprResourceRegistry;

/**
 * Custom XtextResourceSet that automatically installs the InMemoryURIHandler.
 * 
 */
public class InMemoryAwareResourceSet extends SynchronizedXtextResourceSet {

	
	
	@Inject
	public InMemoryAwareResourceSet(InMemoryExprResourceRegistry inMemoryRegistry) {
	  // Install the shared InMemoryURIHandler on this ResourceSet (if not already installed)
	  var handler = inMemoryRegistry.getURIHandler();
	  if (!this.getURIConverter().getURIHandlers().contains(handler)) {
          this.getURIConverter().getURIHandlers().add(0, handler);
	  }
	}
	
}
