package nl.esi.comma.behavior.generator.poosl

import java.util.ArrayList
import java.util.List
import nl.esi.comma.actions.actions.ActionList
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.NonTriggeredTransition
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import nl.esi.comma.signature.interfaceSignature.Notification
import org.eclipse.xtext.EcoreUtil2

class StateMachineValidityChecker {

	static String IN_ALL_STATES_TRANSITION = "In the all states block of state machine %s, transition %s"
	static String IN_STATE_TRANSITION = "In the state %s, transition %s"

	static String NOT_ONE_NOTIFICATION = " contains zero or more than one notification."
	static String TRIGGER_AND_NOTIFICATION = " has a trigger and contains notifications. Notifications are only allowed in transitions without a trigger."

	def static List<String> isStateMachineValidForMonitoring(AbstractBehavior behavior) {
		val List<String> result = new ArrayList<String>()

		for (machine : behavior.machines) {
			for(allStatesBlock : machine.inAllStates) {
				for (t : allStatesBlock.transitions) {
					var index = 1;
					if (!checkNumberOfNotifications(t).empty) {
						result.add(String.format(IN_ALL_STATES_TRANSITION, machine.name, index) + NOT_ONE_NOTIFICATION)
					}
					if (checkNotificationsForTransition(t)) {
						result.add(String.format(IN_ALL_STATES_TRANSITION, machine.name, index) +
							TRIGGER_AND_NOTIFICATION)
					}
					index++
				}
			}

			for (state : machine.states) {
				for (t : state.transitions) {
					var index = 1;
					if (!checkNumberOfNotifications(t).empty) {
						result.add(String.format(IN_STATE_TRANSITION, state.name, index) + NOT_ONE_NOTIFICATION)
					}
					if (checkNotificationsForTransition(t)) {
						result.add(String.format(IN_STATE_TRANSITION, state.name, index) + TRIGGER_AND_NOTIFICATION)
					}
					index++
				}
			}
		}
		return result
	}

	// Checks if a transition with a trigger sends notifications
	def static boolean checkNotificationsForTransition(Transition t) {
		if (t instanceof NonTriggeredTransition) {
			return false
		}
		for (c : t.clauses) {
			for (ec : EcoreUtil2.getAllContentsOfType(c, EventCall)) {
				if (ec.event instanceof Notification) {
					return true
				}
			}
		}
	}

	def static List<Clause> checkNumberOfNotifications(Transition t) {
		val List<Clause> result = new ArrayList<Clause>();
		if (t instanceof TriggeredTransition) {
			return result;
		}
		for (c : t.clauses) {
			val nots = determineMinNumberOfNotificationsPerBlock(c.actions)
			if (nots != 1) {
				result.add(c)
			}
		}
		return result
	}

	def static int determineMinNumberOfNotificationsPerBlock(ActionList l) {
		var int notifications = 0

		if (l !== null) {
			for (a : l.actions) {
				if (a instanceof EventCall) {
					if (a.event instanceof Notification) {
						notifications++;
					}
				} else if (a instanceof IfAction) {
					var int thenNots = 0
					var int elseNots = 0

					thenNots = determineMinNumberOfNotificationsPerBlock(a.thenList)
					if (a.elseList !== null) {
						elseNots = determineMinNumberOfNotificationsPerBlock(a.elseList)
					}
					notifications += Math.min(thenNots, elseNots)
				}
			}
		}
		return notifications
	}
}
