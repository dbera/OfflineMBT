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

import nl.esi.comma.types.BasicTypes
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
