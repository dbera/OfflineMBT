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
import nl.esi.comma.types.scoping.TypesImportUriGlobalScopeProvider
import org.eclipse.emf.ecore.resource.Resource
import nl.esi.comma.expressions.functions.ExpressionFunctionsRegistry

/**
 * Global scope provider for expression language that integrates dynamically registered function libraries.
 * 
 * <p>This class extends {@link TypesImportUriGlobalScopeProvider} to add support for in-memory function
 * libraries that are registered at runtime via {@link ExpressionFunctionsRegistry}.
 * 
 */
class ExpressionsImportUriGlobalScopeProvider extends TypesImportUriGlobalScopeProvider {

    @Inject ExpressionFunctionsRegistry registry

    /**
     * Extends the list of imported URIs with all dynamically registered function library URIs.
     * 
     * <p>Calls the parent implementation first to get types and other standard URIs, then adds
     * all URIs managed by {@link ExpressionFunctionsRegistry} (which contains generated function grammars).
     * 
     */
    override getImportedUris(Resource resource) {
        var handler = registry.getURIHandler();
        if (!resource.resourceSet?.URIConverter?.URIHandlers.contains(handler)) {
            resource.resourceSet?.URIConverter?.URIHandlers?.add(0, handler);
        }
        val importedURIs = super.getImportedUris(resource)
        // Make all registered function library URIs available in expression scope
        importedURIs += registry.registeredURIs

        return importedURIs
    }
}
