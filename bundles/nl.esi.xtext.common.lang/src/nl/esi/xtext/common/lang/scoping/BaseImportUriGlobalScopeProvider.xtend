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
package nl.esi.xtext.common.lang.scoping

import java.util.LinkedHashSet
import nl.esi.xtext.common.lang.base.ModelContainer
import nl.esi.xtext.common.lang.utilities.EcoreUtil3
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.scoping.impl.ImportUriGlobalScopeProvider

class BaseImportUriGlobalScopeProvider extends ImportUriGlobalScopeProvider {
    override getImportedUris(Resource resource) {
        return resource.traverseImportedURIs(newLinkedHashSet)
    }

    static def LinkedHashSet<URI> traverseImportedURIs(Resource resource, LinkedHashSet<URI> uris) {
        val imports = resource.contents.filter(ModelContainer).flatMap[imports].reject[importURI === null]
        for (import : imports) {
            val importResource = EcoreUtil3.getResource(import)
            if (uris += importResource.URI) {
                importResource.traverseImportedURIs(uris)
            }
        }
        return uris
    }
}
