package nl.esi.comma.behavior.ui.quickfix

import nl.esi.comma.actions.ui.quickfix.ActionsQuickfixProvider
import nl.esi.comma.behavior.validation.BehaviorValidator
import nl.esi.comma.behavior.validation.StateMachineValidator
import nl.esi.comma.behavior.validation.TimeConstraintsValidator
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue

class TransitionsQuickfix extends ActionsQuickfixProvider {

	@Fix(BehaviorValidator.STATEMACHINE_DUPLICATE_INTERFACE)
	@Fix(BehaviorValidator.STATEMACHINE_UNUSED_INTERFACE)
	@Fix(BehaviorValidator.STATEMACHINE_DUPLICATE_STATE)
	@Fix(BehaviorValidator.STATEMACHINE_DUPLICATE_VAR)
	@Fix(BehaviorValidator.STATEMACHINE_UNITIALIZED_VAR)
	@Fix(BehaviorValidator.STATEMACHINE_UNUSED_VAR)
	@Fix(StateMachineValidator.STATEMACHINE_DUPLICATE_INITIAL_STATE)
	@Fix(TimeConstraintsValidator.TIME_CONSTRAINT_DUPLICATE)
	def removeElement(Issue issue, IssueResolutionAcceptor acceptor) {
		val element = issue.data.get(0)
		acceptor.accept(issue, 'Remove ' + element, 'Remove ' + element, 'upcase.png') [ context |
			context.xtextDocument.replace(issue.offset, issue.length, "")
		]
	}	
	
//	@Fix("org.eclipse.xtext.diagnostics.Diagnostic.Linking")
//	def resolveEventCall(Issue issue, IssueResolutionAcceptor acceptor) {
		//possible quickfix for when eventcall without interface and interface isnt added to the statemachine either
		// but the eventcall is available in one of the imported interfaces	
//	}

}
