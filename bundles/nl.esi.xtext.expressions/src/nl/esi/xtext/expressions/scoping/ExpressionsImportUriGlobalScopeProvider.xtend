/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.scoping

import com.google.inject.Inject
import nl.esi.xtext.types.scoping.TypesImportUriGlobalScopeProvider
import org.eclipse.emf.ecore.resource.Resource
import nl.esi.xtext.expressions.functions.ExpressionFunctionsRegistry

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
