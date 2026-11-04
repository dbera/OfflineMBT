/*
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
package nl.esi.xplus.extensions.types;

import static nl.esi.xtext.common.lang.utilities.AnnotationUtil.hasAnnotation;

import nl.esi.xtext.types.types.RecordField;
import nl.esi.xtext.types.types.RecordTypeDecl;

public class TypesExtensionUtil {

	private TypesExtensionUtil() {
		// Private constructor for utilities
	}

	public static boolean isContext(RecordTypeDecl typeDecl) {
		return hasAnnotation(typeDecl, "context");
	}

	public static boolean isSuppressed(RecordField field) {
		return hasAnnotation(field, "suppress");
	}

	public static RecordFieldKind getKind(RecordField field) {
		return RecordFieldKind.getKind(field);
	}

}
