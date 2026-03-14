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
package nl.esi.comma.expressions.scoping

import com.google.inject.Inject
import nl.esi.comma.expressions.functions.InMemoryExprResourceRegistry
import nl.esi.comma.types.scoping.TypesImportUriGlobalScopeProvider
import org.eclipse.emf.ecore.resource.Resource

class ExpressionsImportUriGlobalScopeProvider extends TypesImportUriGlobalScopeProvider {

    @Inject InMemoryExprResourceRegistry inMemoryRegistry

    override getImportedUris(Resource resource) {
        val importedURIs = super.getImportedUris(resource)

        // Ensure the ResourceSet can load inmemory:/ URIs by installing the handler
        // once (installing the same handler twice is harmless because canHandle is
        // checked before each read, but we guard against duplicates for clarity).
        val uriConverter = resource.resourceSet?.URIConverter
        if (uriConverter !== null) {
            val alreadyInstalled = uriConverter.URIHandlers.exists[it instanceof InMemoryExprResourceRegistry.InMemoryURIHandler]
            if (!alreadyInstalled) {
                uriConverter.URIHandlers.add(0, inMemoryRegistry.createURIHandler)
            }
        }

        // Add every URI that was registered via ExpressionFunctionsRegistry.addLibraryFunctions
        importedURIs += inMemoryRegistry.registeredURIs

        return importedURIs
    }
}

