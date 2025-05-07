/**
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
package nl.esi.comma.types.scoping

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.scoping.impl.ImportUriGlobalScopeProvider
import java.util.LinkedHashSet
import org.eclipse.xtext.EcoreUtil2
import nl.esi.comma.types.types.ModelContainer

class TypesImportUriGlobalScopeProvider extends ImportUriGlobalScopeProvider {
	static final String BASIC_TYPES_JAR_PATH = "nl/esi/comma/types/types.types";
	static final URI BASIC_TYPES_PATH = URI.createURI(
		Thread.currentThread().contextClassLoader.getResource(BASIC_TYPES_JAR_PATH).toString)
	
	override getImportedUris(Resource resource) {
		var LinkedHashSet<URI> importedURIs = new LinkedHashSet<URI>(5);
				
		if(resource.allContents.head instanceof ModelContainer){
			val knownURIs = new LinkedHashSet<URI>(5);
			knownURIs.add(resource.URI)
			importedURIs =  traverseImportedURIs(resource, knownURIs);
		}else{
			importedURIs = super.getImportedUris(resource)
		}
		//implicit import of the built-in types in types.types
		importedURIs.add(BASIC_TYPES_PATH);
		
		return importedURIs
	}
		
	static def LinkedHashSet<URI> traverseImportedURIs(Resource resource, LinkedHashSet<URI> knownURIs){
		val LinkedHashSet<URI> result = new LinkedHashSet<URI>(5);
		
		val root = resource.allContents.head as ModelContainer
		for(import : root.imports.filter[it.importURI !== null]){
			val Resource importedResource = EcoreUtil2.getResource(resource, import.importURI)
			if(importedResource !== null){
				if(importedResource.allContents.head instanceof ModelContainer){
					if(! knownURIs.contains(importedResource.URI)){
						knownURIs.add(importedResource.URI);
						result.add(importedResource.URI)
						result.addAll(traverseImportedURIs(importedResource, knownURIs))
					}
				}
			}
		}
		
		return result
	}
	
}
