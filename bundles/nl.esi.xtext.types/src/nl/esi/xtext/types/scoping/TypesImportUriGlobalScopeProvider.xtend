/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.scoping

import nl.esi.xtext.types.BasicTypes
import nl.esi.xtext.common.lang.scoping.BaseImportUriGlobalScopeProvider
import org.eclipse.emf.ecore.resource.Resource

class TypesImportUriGlobalScopeProvider extends BaseImportUriGlobalScopeProvider {
    override getImportedUris(Resource resource) {
        val importedURIs = super.getImportedUris(resource)
        // implicit import of the built-in types in types.types
        importedURIs += BasicTypes.TYPES_URI;
        return importedURIs
    }
}
