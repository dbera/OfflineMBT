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
package nl.esi.xplus.extensions.types

import nl.esi.xtext.types.types.RecordField

import static nl.esi.xtext.common.lang.utilities.AnnotationUtil.hasAnnotation

class TypesExtensionUtil {

    private new() {
        // Private constructor for utilities
    }
    
    static def isSuppressed(RecordField field) {
        hasAnnotation(field, "suppressed")
    }
    
    static def getKind(RecordField field) {
        RecordFieldKind.getKind(field)
    }

}
