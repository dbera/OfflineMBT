/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.actions.formatting2

import com.google.inject.Inject
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.ActionList
import nl.esi.comma.actions.actions.AnyEvent
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.InterfaceEventInstance
import nl.esi.comma.actions.actions.NotificationEvent
import nl.esi.comma.actions.actions.PCFragment
import nl.esi.comma.actions.actions.ParallelComposition
import nl.esi.comma.actions.actions.ParameterizedEvent
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.actions.actions.SignalEvent
import nl.esi.comma.actions.services.ActionsGrammarAccess
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.formatting2.ExpressionFormatter
import org.eclipse.xtext.formatting2.IFormattableDocument
import nl.esi.comma.actions.actions.Multiplicity

class ActionsFormatter extends ExpressionFormatter {

	@Inject extension ActionsGrammarAccess

	def dispatch void format(AssignmentAction assignmentAction, extension IFormattableDocument document) {
		assignmentAction.regionFor.keyword(assignmentActionAccess.colonEqualsSignKeyword_1).surround(oneSpace)

		assignmentAction.getExp.format;
	}

	def dispatch void format(IfAction ifAction, extension IFormattableDocument document) {
		val rFinder = ifAction.regionFor

		rFinder.keyword(ifActionAccess.ifKeyword_0).append(oneSpace)
		rFinder.keyword(ifActionAccess.thenKeyword_2).prepend(oneSpace)
		rFinder.keyword(ifActionAccess.elseKeyword_4_0).prepend(newLine)
		rFinder.keyword(ifActionAccess.fiKeyword_5).prepend(newLine)

		ifAction.getThenList.prepend(newLine)
		ifAction.elseList.prepend(newLine)
		document.set(ifAction.getThenList.previousHiddenRegion, ifAction.getThenList.nextHiddenRegion, (indent))
		document.set(ifAction.getElseList.previousHiddenRegion, ifAction.getElseList.nextHiddenRegion, (indent))

		ifAction.getGuard.format;
		ifAction.getThenList.format;
		ifAction.getElseList.format;
	}

	def dispatch void format(RecordFieldAssignmentAction assignAction, extension IFormattableDocument document) {
		assignAction.regionFor.keyword(recordFieldAssignmentActionAccess.colonEqualsSignKeyword_1).surround(oneSpace)

		assignAction.exp.format
		formatFieldAccessExp(assignAction.fieldAccess, document)
	}
	
	def void formatFieldAccessExp(Expression fieldAccessExp, extension IFormattableDocument document) {
		fieldAccessExp.regionFor.keyword('.').surround(noSpace)
	}

	def dispatch void format(ActionList actionList, extension IFormattableDocument document) {
		for (Action action : actionList.actions) {
			action.prepend(newLine)
			action.format
		}
	}

	def dispatch void format(CommandReply commandReply, extension IFormattableDocument document) {

		formatParameterizedEvent(commandReply, document)

		val rFinder = commandReply.regionFor
		rFinder.keyword(commandReplyAccess.toKeyword_3_0).surround(oneSpace)

		commandReply.command.format
	}

	def dispatch void format(EventCall eventCall, extension IFormattableDocument document) {
		formatInterfaceEventInstance(eventCall, document)

		val regionFor = eventCall.regionFor
		regionFor.keyword(eventCallAccess.occurenceAsteriskKeyword_1_0_0_0)?.surround(noSpace)
		regionFor.keyword(eventCallAccess.occurencePlusSignKeyword_1_0_0_1)?.surround(noSpace)
		regionFor.keyword(eventCallAccess.occurenceQuestionMarkKeyword_1_0_0_2)?.surround(noSpace)
		
		eventCall.multiplicity?.format
	}
	
	def dispatch void format(Multiplicity multiplicity, extension IFormattableDocument document){
		val regionFor = multiplicity.regionFor
		
		regionFor.keyword(multiplicityAccess.leftSquareBracketKeyword_0)?.surround(noSpace)
		regionFor.keyword(multiplicityAccess.hyphenMinusKeyword_2)?.surround(noSpace)
		regionFor.keyword(multiplicityAccess.rightSquareBracketKeyword_4)?.surround(noSpace)
	}

	def dispatch void format(CommandEvent commEvent, extension IFormattableDocument document) {
		val rFinder = commEvent.regionFor
		rFinder.keyword(commandEventAccess.commandKeyword_0).append(oneSpace)
		formatInterfaceEventInstance(commEvent, document)
	}

	def dispatch void format(NotificationEvent notificationEvent, extension IFormattableDocument document) {
		val rFinder = notificationEvent.regionFor
		rFinder.keyword(notificationEventAccess.notificationKeyword_0).append(oneSpace)
		formatInterfaceEventInstance(notificationEvent, document)
	}

	def dispatch void format(SignalEvent signalEvent, extension IFormattableDocument document) {
		val rFinder = signalEvent.regionFor
		rFinder.keyword(signalEventAccess.signalKeyword_0).append(oneSpace)
		formatInterfaceEventInstance(signalEvent, document)
	}

	def void formatInterfaceEventInstance(InterfaceEventInstance iEventInstance,
		extension IFormattableDocument document) {
		formatParameterizedEvent(iEventInstance, document)
	}

	def dispatch void format(AnyEvent anyEvent, extension IFormattableDocument document) {
		anyEvent.regionFor.keyword(anyEventAccess.anyKeyword_0).append(oneSpace)
	}

	def void formatParameterizedEvent(ParameterizedEvent parameterizedEvent, extension IFormattableDocument document) {
		val rFinder = parameterizedEvent.regionFor
		rFinder.keyword(parameterizedEventAccess.leftParenthesisKeyword_0).surround(noSpace)
		rFinder.keyword(parameterizedEventAccess.rightParenthesisKeyword_3).prepend(noSpace)

		for (Expression expr : parameterizedEvent.parameters) {
			expr.format
		}
	}
	
	def dispatch void format(ParallelComposition parallelComposition, extension IFormattableDocument document) {
		val regionFor = parallelComposition.regionFor
		
		regionFor.keyword(parallelCompositionAccess.anyKeyword_0).append(oneSpace)
		//regionFor.keyword(parallelCompositionAccess.orderKeyword_1).append(noSpace)
		regionFor.keyword(parallelCompositionAccess.leftParenthesisKeyword_2).surround(noSpace)			
		regionFor.keyword(parallelCompositionAccess.rightParenthesisKeyword_4).prepend(noSpace)
		
		val pcFragment = (parallelComposition as PCFragment)
		formatPCFragment(pcFragment, document)
	}
	
	def void formatPCFragment(PCFragment pcFragment, extension IFormattableDocument document) {
		val regionFor = pcFragment.regionFor
		regionFor.keyword(PCFragmentAccess.commaKeyword_1_0)?.prepend(noSpace).append(oneSpace)
		pcFragment.components.last.prepend(oneSpace)

		pcFragment.components.forEach[format]
	}
}