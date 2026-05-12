/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.formatting2

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