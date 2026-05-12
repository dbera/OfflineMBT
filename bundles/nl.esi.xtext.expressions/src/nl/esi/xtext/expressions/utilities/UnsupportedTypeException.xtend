/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.utilities;

import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeDecl
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
