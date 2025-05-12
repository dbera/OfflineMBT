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
package nl.esi.comma.expressions.ide.contentassist;

import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import org.eclipse.xtend.lib.annotations.Accessors

class UnsupportedTypeException extends RuntimeException {
    static final long serialVersionUID = -2982313254232292289L;

    @Accessors
    val TypeDecl typeDeclaration;

    new(Type type) {
        this(type?.type)
    }

    new(TypeDecl typeDeclaration) {
        super('''Unsupported type: «typeDeclaration?.name»''');
        this.typeDeclaration = typeDeclaration;
    }
}
