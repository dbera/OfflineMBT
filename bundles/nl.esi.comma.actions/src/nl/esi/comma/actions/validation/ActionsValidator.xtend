/**
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
/*
 * generated by Xtext 2.10.0
 */
package nl.esi.comma.actions.validation

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import nl.esi.comma.actions.actions.ActionsPackage
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.EventPattern
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.InterfaceEventInstance
import nl.esi.comma.actions.actions.PCElement
import nl.esi.comma.actions.actions.PCFragment
import nl.esi.comma.actions.actions.PCFragmentDefinition
import nl.esi.comma.actions.actions.ParameterizedEvent
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.actions.actions.VariableDeclBlock
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.Field
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.DIRECTION
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypesPackage
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.validation.Check
import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import static extension nl.esi.comma.actions.utilities.ActionsUtilities.*
import nl.esi.comma.actions.actions.Multiplicity

class ActionsValidator extends AbstractActionsValidator {
	public static final String REPLY_WRONG_NUMBER_PARAMS = "trigger_remove_param"
	public static final String REPLY_INVALID_TYPE = "trigger_invalid_type"
	public static final String STATEMACHINE_DUPLICATE_VAR = "statemachine_duplicate_var"
	
	/*
  	 * Constraints:
  	 * - the type of the expression conforms to the type of the variable
  	 */
	@Check
	def checkTypingAssignment(AssignmentAction act){
		val t = act?.exp?.typeOf
		if(!t.subTypeOf(act.assignment?.type.typeObject)){ 
			error("Type mismatch: actual type does not match the expected type", ActionsPackage.Literals.ASSIGNMENT_ACTION__EXP)
		}
	} 
	
	/*
	 * Constraints:
	 * - the type of the expression conforms to the type of the field
	 */
	@Check
	def checkTypingFieldAssignment(RecordFieldAssignmentAction act){
		val t = act.exp?.typeOf
		if(!t.subTypeOf(act.fieldAccess?.typeOf)){
			error("Type mismatch: actual type does not match the expected type", ActionsPackage.Literals.RECORD_FIELD_ASSIGNMENT_ACTION__EXP)
		}	
	} 
	
	/*
	 * Constraints:
	 * - the type of the condition is boolean
	 */
	@Check
	def checkTypingIfAction(IfAction act){
		val t  = act.guard?.typeOf
		if(!t.subTypeOf(boolType)){
			error("Type mismatch: the type of the condition must be boolean", ActionsPackage.Literals.IF_ACTION__GUARD)
		}
	}
	
	/*
	 * Constraints:
	 * - the wildcard value * can only be used in:
	 *   + as a value in parameterized event
	 *   + as a value of a record field which record is used in parameterized event
	 */
	@Check
	def checkUsageAnyValue(ExpressionAny exp){
		var parent = exp.eContainer
		var problemFound = false
		while(parent !==null && !(parent instanceof ParameterizedEvent) && ! problemFound){
			if( !(parent instanceof Field || parent instanceof ExpressionRecord) ){
				problemFound = true
			}
			parent = parent.eContainer
		}
		if(problemFound || parent === null){
			error("Expression * cannot be used in this context", exp.eContainer, exp.eContainingFeature)
		}
	}
	
	/*
	 * Constraints:
	 * - if parameters are given then their number is the same as the number in the event definition
	 * - if parameters are given then their types conform to the type in the event definition
	 */
	@Check
	def checkEventInstanceParameters(InterfaceEventInstance ev){
		if( !(ev instanceof EventPattern) || ! ev.parameters.empty){
			if (ev.parameters.size != ev.event.parameters.size) {
				error('The number of parameters does not match.', ev,
					ActionsPackage.Literals.PARAMETERIZED_EVENT__PARAMETERS)
				return
			}
			for(i : 0..< ev.parameters.size()){
				val t = ev.parameters.get(i).typeOf
				if(!t.subTypeOf(ev.event.parameters.get(i).type.typeObject)){
					error('The type of the expression must match the type in the signature.', 
						ev, ActionsPackage.Literals.PARAMETERIZED_EVENT__PARAMETERS, i)
				}
			}
		}
	}
	
	/*
	 * Constraints:
	 * - reply contains the values of inout or out parameters (if any) and the return value (if any)
	 * - the size and the type of the values must match the definition
	 */
	def checkReplyAgainstCommand(Command c, CommandReply r){
		var expectedTypes = new ArrayList<Type>
		val outParams = c.parameters.filter(p | p.direction != DIRECTION::IN)
		for(p : outParams){expectedTypes.add(p.type)}
		if(!TypeUtilities::isVoid(c.type)) {expectedTypes.add(c.type)}
		//Check if the number of actual params in reply are equal to the size of expectedTypes
		if(r.parameters.size() != expectedTypes.size()){
			error('Wrong number of values in reply.', r,
					ActionsPackage.Literals.PARAMETERIZED_EVENT__PARAMETERS, REPLY_WRONG_NUMBER_PARAMS, null)
			return
		}
		//Number of values Ok, check the types
		for(i : 0..< r.parameters.size){
			val expectedType = expectedTypes.get(i)?.typeObject
			if (! r.parameters.get(i).typeOf.subTypeOf(expectedType))
				error('The type of the value must match the return type of the command or inout/out parameter type.', r,
					ActionsPackage.Literals.PARAMETERIZED_EVENT__PARAMETERS, i, REPLY_INVALID_TYPE, null)
		}
	}
	
	/*
	 * Constraints:
	 * - variable names are unique
	 */
	@Check
	def checkDuplicateVariables(VariableDeclBlock db){
		checkForNameDuplications(db.vars, "variable", ActionsValidator.STATEMACHINE_DUPLICATE_VAR, null)
	}
	
	/*
	 * Constraints:
	 * - warning on non-initialized variables
	 */
	@Check
	def checkNotInitializedVariables(VariableDeclBlock db){
		if(db.vars.size > 0){
			var variables = new ArrayList<Variable>()
			variables.addAll(db.vars)
			var usedVariables = db.initActions.filter(AssignmentAction).map[assignment]
			variables.removeAll(usedVariables)
			variables.forEach[warning('Uninitialized variable.', it, TypesPackage.Literals.NAMED_ELEMENT__NAME)]
		}
	}
	
	/*
	 * Constraints:
	 * - upper bound > 0
	 * - lower bound <= upper bound
	 */
	@Check
	def checkMultiplicity(Multiplicity m){
		if(m.upperInf !== null) {return}
		if(m.upper == 0){
			error("Upper bound cannot be 0", ActionsPackage.Literals.MULTIPLICITY__UPPER)
		}else{
			if(m.lower > m.upper){
				error("Lower bound cannot be greater than the upper bound", ActionsPackage.Literals.MULTIPLICITY__LOWER)
			}
		}
	}
	
	/*
	 * Constraints:
	 * - fragment definitions do not contain circular reference chains
	 * - fragment definitions do not contain replies
	 * Note: parallel composition can contain replies
	 */
	@Check
	def checkFragmentRefCircularity(PCFragmentDefinition fd){
		val referencedFragments = fd.allReferencedFragments(new HashSet<PCFragmentDefinition>)
		if(referencedFragments.contains(fd)){
			error("Circular reference chain", TypesPackage.Literals.NAMED_ELEMENT__NAME)
		}
		fd.components.filter(CommandReply).forEach[
			error("Fragment definition cannot contain replies", ActionsPackage.Literals.PC_FRAGMENT__COMPONENTS, fd.components.indexOf(it))
		]
	}
	
	/*
	 * Constraints:
	 * - after performing flattening, a parallel composition body or a fragment definition:
	 *   + does not contain overlapping event patterns
	 *   + contains only one reply (not relevant for fragment definitions)
	 * 
	 * Overlapping event patterns: patterns that have a non-empty intersection of the sets with
	 * matching events. 
	 * Example: a(1, *) and a(*, 2) both match a(1, 2)
	 * Rationale: ambiguity in parallel composition is not supported, that is, when a given event
	 * is matched by more than one pattern in the parallel composition
	 */
	@Check
	def checkParallelComposition(PCFragment pc){
		val actions = pc.flatten
		val parent = pc.eContainer
		val index = (parent.eGet(pc.eContainingFeature) as List<EObject>).indexOf(pc)
		
		//Check for overlapping events
		for(i : 0..< actions.size-1)
		for(j : (i+1)..< actions.size){
			val current = actions.get(i)
			if(current instanceof EventCall){
				if(current.overlaps(actions.get(j) as PCElement)){
					error("Parallel composition contains overlapping events", parent, pc.eContainingFeature, index)
				}
			}
		}
		
		//Check for single occurrence of reply
		if(actions.filter(CommandReply).size > 1){
			error("Parallel composition contains more than one reply", parent, pc.eContainingFeature, index)
		}
	}
}
