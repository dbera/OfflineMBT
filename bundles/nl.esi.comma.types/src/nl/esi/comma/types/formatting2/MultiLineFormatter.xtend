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
package nl.esi.comma.types.formatting2

import org.eclipse.xtext.formatting2.internal.MultilineCommentReplacer
import org.eclipse.xtext.formatting2.regionaccess.IComment
import org.eclipse.xtext.formatting2.internal.WhitespaceReplacer

class MultiLineFormatter extends MultilineCommentReplacer {
	
	final boolean multiline;
	
	new(IComment comment, char prefix) {
		super(comment, prefix)		
		this.multiline = comment.multiline;		
	}

	override configureWhitespace(WhitespaceReplacer leading, WhitespaceReplacer trailing) {
		if (multiline) {
			enforceEmptyLine(leading);
			enforceNewLine(trailing);
		} else {
			enforceEmptyLine(leading);
			enforceSingleSpace(trailing);
		}
	}
	
	def enforceEmptyLine(WhitespaceReplacer replacer) {
		replacer.formatting.newLinesMin = 1
		replacer.formatting.newLinesDefault = 2
		replacer.formatting.newLinesMax = 2
	}
}