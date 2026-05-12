/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
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
