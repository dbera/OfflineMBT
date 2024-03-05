package nl.esi.comma.behavior.ui.quickfix

import nl.esi.comma.behavior.behavior.StateMachine
import nl.esi.comma.behavior.validation.StateMachineValidator
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.ui.editor.model.edit.IModificationContext
import org.eclipse.xtext.ui.editor.model.edit.ISemanticModification
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue

class InterfaceBehaviorQuickfix extends StateMachineQuickfix {

	@Fix(StateMachineValidator.STATEMACHINE_MISSING_INITIAL_STATE)
	def addInitialState(Issue issue, IssueResolutionAcceptor acceptor) {

		val modification = new ISemanticModification() {
			override apply(EObject element, IModificationContext context) throws Exception {
				val sm = element as StateMachine
				var offset = if (!sm.states.empty)
						NodeModelUtils.findActualNodeFor(sm.states.get(0)).offset - 1
					else
						NodeModelUtils.findActualNodeFor(sm).endOffset - 1
				
				val initialState = 
					'''
					
						initial state NewState {
							transition
								next state: NewState«""»
						}

					'''
				context.xtextDocument.replace(offset, 0, initialState)
			}
		}
		acceptor.accept(issue, 'Add initial state', 'Add initial state.', 'upcase.png', modification)
	}
}