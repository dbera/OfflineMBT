package nl.esi.comma.behavior.ui.quickfix

import nl.esi.comma.behavior.behavior.ConditionedAbsenceOfEvent
import nl.esi.comma.behavior.validation.TimeConstraintsValidator
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.ui.editor.model.edit.IModificationContext
import org.eclipse.xtext.ui.editor.model.edit.ISemanticModification
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue

class TimeConstraintsQuickfix extends TransitionsQuickfix {

@Fix(TimeConstraintsValidator.GROUP_CONSTRAINT_MISING_END)
	def changeToEndBoundary(Issue issue, IssueResolutionAcceptor acceptor) {
		
		val modification = new ISemanticModification() {			
			override apply(EObject element, IModificationContext context) throws Exception {
				val expr = NodeModelUtils.findActualNodeFor((element as ConditionedAbsenceOfEvent).interval.begin).text
				context.xtextDocument.replace(issue.offset, issue.length, "[ .. "+ expr +" ms ]")				
			}			
		}
		acceptor.accept(issue, 'Change to end boundary', 'Change to end boundary', 'upcase.png', modification)
	}
}
