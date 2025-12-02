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
package nl.esi.comma.types

import java.util.Iterator
import nl.esi.comma.types.types.SimpleTypeDecl
import org.eclipse.core.runtime.Platform
import org.eclipse.emf.common.notify.Notifier
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.resource.XtextResourceSet
import nl.esi.comma.types.types.TypeDecl

class BasicTypes {
    static val String JAR_PATH = "nl/esi/comma/types/types.types";
    static val XtextResourceSet DEFAULT_RESOURCE_SET = new XtextResourceSet

    public static val URI TYPES_URI = Platform.running ? URI.createPlatformPluginURI(BasicTypes.package.name + '/' +
        BasicTypes.JAR_PATH, true) : URI.createURI(
        Thread.currentThread().contextClassLoader.getResource(BasicTypes.JAR_PATH).toString)

    static def Iterator<SimpleTypeDecl> getAllBasicTypes() {
        return getAllBasicTypes(null)
    }

    static def Iterator<SimpleTypeDecl> getAllBasicTypes(Notifier anchor) {
        var resourceSet = switch (anchor) {
            ResourceSet: anchor
            Resource: anchor.resourceSet
            EObject: anchor.eResource?.resourceSet
        }
        if (resourceSet === null) {
            resourceSet = DEFAULT_RESOURCE_SET
        }
        val basicTypesResource = resourceSet.getResource(TYPES_URI, true)
        return basicTypesResource.allContents.filter(SimpleTypeDecl)
    }

    private static def SimpleTypeDecl getBasicType(Notifier anchor, String typeName) {
        return getAllBasicTypes(anchor).filter(SimpleTypeDecl).findFirst[base === null && name == typeName]
    }

    static def boolean isBasicType(TypeDecl type) {
        return if (type instanceof SimpleTypeDecl) {
            type.base === null && type.eResource?.URI == TYPES_URI
        } else {
            false
        }
    }

    static def SimpleTypeDecl getAnyType() {
        return getAnyType(null)
    }

    static def SimpleTypeDecl getAnyType(EObject anchor) {
        return getBasicType(anchor, 'any')
    }

    static def SimpleTypeDecl getBoolType() {
        return getBoolType(null)
    }

    static def SimpleTypeDecl getBoolType(EObject anchor) {
        return getBasicType(anchor, 'bool')
    }

    static def SimpleTypeDecl getIntType() {
        return getIntType(null)
    }

    static def SimpleTypeDecl getIntType(EObject anchor) {
        return getBasicType(anchor, 'int')
    }

    static def SimpleTypeDecl getRealType() {
        return getRealType(null)
    }

    static def SimpleTypeDecl getRealType(EObject anchor) {
        return getBasicType(anchor, 'real')
    }

    static def SimpleTypeDecl getStringType() {
        return getStringType(null)
    }

    static def SimpleTypeDecl getStringType(EObject anchor) {
        return getBasicType(anchor, 'string')
    }

    static def SimpleTypeDecl getVoidType() {
        return getVoidType(null)
    }

    static def SimpleTypeDecl getVoidType(EObject anchor) {
        return getBasicType(anchor, 'void')
    }

    static def SimpleTypeDecl getIdType() {
        return getIdType(null)
    }

    static def SimpleTypeDecl getIdType(EObject anchor) {
        return getBasicType(anchor, 'id')
    }

    static def SimpleTypeDecl getBulkDataType() {
        return getBulkDataType(null)
    }

    static def SimpleTypeDecl getBulkDataType(EObject anchor) {
        return getBasicType(anchor, 'bulkdata')
    }
}
