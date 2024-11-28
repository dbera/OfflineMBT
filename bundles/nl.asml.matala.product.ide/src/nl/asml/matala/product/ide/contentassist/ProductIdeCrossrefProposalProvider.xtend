package nl.asml.matala.product.ide.contentassist

import nl.esi.comma.expressions.expression.ExpressionPackage
import org.eclipse.xtext.CrossReference
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.ide.editor.contentassist.IdeCrossrefProposalProvider
import org.eclipse.xtext.resource.IEObjectDescription
import nl.esi.comma.types.types.TypesPackage

class ProductIdeCrossrefProposalProvider extends IdeCrossrefProposalProvider {
    override protected createProposal(IEObjectDescription candidate, CrossReference crossRef, ContentAssistContext context) {
        val proposal = super.createProposal(candidate, crossRef, context)
        proposal.kind = switch (candidate.EClass) {
            case ExpressionPackage.Literals.VARIABLE: ContentAssistEntry.KIND_VARIABLE
            case TypesPackage.Literals.RECORD_TYPE_DECL: ContentAssistEntry.KIND_CLASS
            case TypesPackage.Literals.RECORD_FIELD: ContentAssistEntry.KIND_FIELD
            case TypesPackage.Literals.ENUM_TYPE_DECL: ContentAssistEntry.KIND_ENUM
            case TypesPackage.Literals.ENUM_ELEMENT: ContentAssistEntry.KIND_FIELD
            default: ContentAssistEntry.KIND_REFERENCE
        }
        return proposal
    }
}
