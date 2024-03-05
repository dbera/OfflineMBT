package nl.esi.comma.behavior.validation

import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.BehaviorPackage
import nl.esi.comma.behavior.behavior.ConditionedAbsenceOfEvent
import nl.esi.comma.behavior.behavior.GroupTimeConstraint
import nl.esi.comma.behavior.behavior.PeriodicEvent
import nl.esi.comma.behavior.behavior.TimeInterval
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import org.eclipse.xtext.validation.Check

class TimeConstraintsValidator extends TransitionsValidator {
	public static final String GROUP_CONSTRAINT_MISING_END = "group_constraint_end"
	public static final String TIME_CONSTRAINT_DUPLICATE = "time_constraint_duplicated"
	
	/*
	 * Constraints:
	 * - The values of period and jitter in periodic rules are positive real constants
	 */
	@Check
	def checkTypingPeriodicEvent(PeriodicEvent evt) {
		if (evt.period !== null) {
			if (!(evt.period instanceof ExpressionConstantReal))
				error('The value of period must be a positive real constant.', BehaviorPackage.Literals.PERIODIC_EVENT__PERIOD)

		}
		if (evt.jitter !== null) {
			if (!(evt.jitter instanceof ExpressionConstantReal))
				error('The value of jitter must be a positive real constant.', BehaviorPackage.Literals.PERIODIC_EVENT__JITTER)
		}
	}
	
	/*
	 * Constraints:
	 * - if both interval boundaries are present, begin of the interval
	 *   is smaller than the end of the interval
	 * - interval boundaries are positive real numbers
	 */
	@Check
	def checkLowerBoundOfIntervalToBeSmallerThanHigherBound(TimeInterval timeInterval) {
		if (timeInterval.begin === null || timeInterval.end === null) return;
		if (timeInterval.begin instanceof ExpressionConstantReal &&
				timeInterval.end instanceof ExpressionConstantReal){
			val begin = (timeInterval.begin as ExpressionConstantReal).value
			val end = (timeInterval.end as ExpressionConstantReal).value
			if(begin >= end)
					error("Lower bound should be less than the upper bound.", timeInterval,
						BehaviorPackage.Literals.TIME_INTERVAL__BEGIN)
		}			
	}
	
	@Check
	def checkTimeInterval(TimeInterval timeInterval) {
		if (timeInterval.begin !== null) {
			if (!(timeInterval.begin instanceof ExpressionConstantReal))
				error('The begin of the interval must be a positive real constant.', BehaviorPackage.Literals.TIME_INTERVAL__BEGIN)
		}
		if (timeInterval.end !== null) {
			if (!(timeInterval.end instanceof ExpressionConstantReal))
				error('The end of the interval must be a positive real constant.', BehaviorPackage.Literals.TIME_INTERVAL__END)
		}
	}

	/*
	 * Constraints:
	 * - if the first rule in a group constraint is ConditionedAbsenceOfEvent, its
	 *   interval has no begin value
	 */
	@Check
	def checkIntervalInGroupConstraintMissingEventTrigger(GroupTimeConstraint gt) {
		if (gt.first instanceof ConditionedAbsenceOfEvent) {
			val TimeInterval i = (gt.first as ConditionedAbsenceOfEvent).interval
			if (i.begin !== null) {
				error('The interval used in this scenario must be in the form [.. RealConst ms].', gt.first,
					BehaviorPackage.Literals.CONDITIONED_ABSENCE_OF_EVENT__INTERVAL, GROUP_CONSTRAINT_MISING_END,
					null)
			}
		}
	}
	
	/*
	 * Constraints:
	 * - time constraints names are unique
	 */
	@Check
	def checkUniqueTimeConstraintsNames(AbstractBehavior spec) {
		checkForNameDuplications(spec.timeConstraintsBlock.timeConstraints, "time constraints",
			TIME_CONSTRAINT_DUPLICATE, "constraint")
	}
}
	