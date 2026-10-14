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

import nl.esi.xtext.types.types.RecordField;
import static nl.esi.xtext.common.lang.utilities.AnnotationUtil.hasAnnotation;

@SuppressWarnings("all")
public enum RecordFieldKind {
	CONCRETE,

	SYMBOLIC,

	MIXED;

	public static RecordFieldKind getKind(RecordField field) {
		if (hasAnnotation(field, "mixed")) {
			return RecordFieldKind.MIXED;
		} else if (hasAnnotation(field, "symbolic")) {
			return RecordFieldKind.SYMBOLIC;
		}
		return RecordFieldKind.CONCRETE;
	}
}
