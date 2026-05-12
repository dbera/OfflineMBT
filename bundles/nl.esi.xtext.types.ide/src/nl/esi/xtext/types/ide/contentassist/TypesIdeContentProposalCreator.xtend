/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.ide.contentassist

import org.eclipse.xtext.ide.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalCreator
import java.util.regex.Pattern

class TypesIdeContentProposalCreator extends IdeContentProposalCreator {
    static val STARTS_WITH_WORD = Pattern.compile("^\\w")
    static val ENDS_WITH_WORD = Pattern.compile("\\w$")

    override createProposal(String proposal, String prefix, ContentAssistContext context, String kind, (ContentAssistEntry)=>void init) {
        if (insertWhitespace(proposal, prefix, context)) {
            // Inject a whitespace to separate this proposal from the previous text node
            super.createProposal(' ' + proposal, prefix, context, kind, init) => [
                if (label === null) {
                    label = proposal
                }
            ]
        } else {
            super.createProposal(proposal, prefix, context, kind, init)
        }
    }

    protected def boolean insertWhitespace(String proposal, String prefix, ContentAssistContext context) {
        return prefix.empty
            && context.offset == context.lastCompleteNode.endOffset
            && STARTS_WITH_WORD.matcher(proposal).find
            && ENDS_WITH_WORD.matcher(context.lastCompleteNode.text).find
    }

    override isValidProposal(String proposal, String prefix, ContentAssistContext context) {
        // Do not accept the prefix itself
        return super.isValidProposal(proposal, prefix, context) && proposal != prefix
    }
}
