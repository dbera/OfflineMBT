package nl.esi.comma.behavior.ui.quickfix

import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.State
import nl.esi.comma.behavior.validation.BehaviorValidator
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.ui.editor.model.edit.IModificationContext
import org.eclipse.xtext.ui.editor.model.edit.ISemanticModification
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue

class StateMachineQuickfix extends TimeConstraintsQuickfix {

	@Fix(BehaviorValidator.CLAUSE_MISSING_NEXT_STATE)
	def addNextState(Issue issue, IssueResolutionAcceptor acceptor) {
		

		val modification = new ISemanticModification() {
			override apply(EObject element, IModificationContext context) throws Exception {				
				if (element instanceof Clause) {
					val actions = NodeModelUtils.findActualNodeFor(element.actions)
					context.xtextDocument.replace(actions.offset + actions.length + 1, 0,
						"next state: " + (element.eContainer.eContainer as State).name)
				}
			}
		}
		acceptor.accept(issue, 'Add next state', 'Add next state.', 'upcase.png', modification)
	}
	

}
