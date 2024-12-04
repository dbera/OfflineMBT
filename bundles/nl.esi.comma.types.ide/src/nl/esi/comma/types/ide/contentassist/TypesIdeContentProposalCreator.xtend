package nl.esi.comma.types.ide.contentassist

import org.eclipse.xtext.ide.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalCreator

class TypesIdeContentProposalCreator extends IdeContentProposalCreator {
    override createProposal(String proposal, String prefix, ContentAssistContext context, String kind, (ContentAssistEntry)=>void init) {
        if (prefix.empty && context.lastCompleteNode.length > 0 && context.offset == context.lastCompleteNode.endOffset) {
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

    override isValidProposal(String proposal, String prefix, ContentAssistContext context) {
        // Do not accept the prefix itself
        return super.isValidProposal(proposal, prefix, context) && proposal != prefix
    }
}