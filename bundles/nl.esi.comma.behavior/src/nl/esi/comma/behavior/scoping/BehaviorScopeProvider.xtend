/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.behavior.scoping

import java.util.ArrayList
import java.util.List
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.BehaviorPackage
import nl.esi.comma.behavior.behavior.DataConstraintsBlock
import nl.esi.comma.behavior.behavior.EventInState
import nl.esi.comma.behavior.behavior.GenericConstraintsBlock
import nl.esi.comma.behavior.behavior.State
import nl.esi.comma.behavior.behavior.TimeConstraintsBlock
import nl.esi.comma.behavior.behavior.TriggeredTransition
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.signature.utilities.InterfaceUtilities
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.IScope

import static org.eclipse.xtext.scoping.Scopes.*
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.ActionsPackage
import nl.esi.comma.behavior.behavior.FeatureExpression
import nl.esi.comma.types.utilities.CommaUtilities
//import nl.esi.comma.systemconfig.configuration.ConfigurationPackage
import java.util.LinkedHashSet
import org.eclipse.emf.common.util.URI
import nl.esi.comma.types.scoping.TypesImportUriGlobalScopeProvider
import org.eclipse.emf.ecore.resource.Resource
//import nl.esi.comma.systemconfig.configuration.FeatureDefinition

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class BehaviorScopeProvider extends AbstractBehaviorScopeProvider {
	override getScope(EObject context, EReference reference){
		if(context instanceof TriggeredTransition && reference == BehaviorPackage.Literals.TRIGGERED_TRANSITION__TRIGGER) {
			return scope_Transition_trigger(context as TriggeredTransition, reference)
		}
		
		if(context instanceof EventInState && reference == BehaviorPackage.Literals.EVENT_IN_STATE__STATE)
			return scope_Event_state(context as EventInState, reference)
		
		if(context instanceof ExpressionVariable && reference == ExpressionPackage.Literals.EXPRESSION_VARIABLE__VARIABLE)
			return scope_variable(context.eContainer)
			
		if(context instanceof AssignmentAction && reference == ActionsPackage.Literals.ASSIGNMENT_ACTION__ASSIGNMENT)
			return scope_variable(context.eContainer)
			
		return super.getScope(context, reference);
	}
	
	def IScope scope_variable(EObject context){
		if(context instanceof ExpressionQuantifier){
			val IScope parentScope = scope_variable(context.eContainer)
			val ArrayList<Variable> vars = new ArrayList<Variable>();
			vars.add(context.iterator)
			return scopeFor(vars, parentScope)
		}
		
		//Interface event parameters can shadow other variables
		if(context instanceof TriggeredTransition){
			if(! context.parameters.empty){
				val IScope parentScope = scope_variable(context.eContainer)
				return scopeFor(context.parameters, parentScope)
			}
			else
				return scope_variable(context.eContainer)
		}
		
		if(context instanceof AbstractBehavior)
			return scopeFor(context.vars)
		
		if(context instanceof DataConstraintsBlock)
			return scopeFor(context.vars)
			
		if(context instanceof GenericConstraintsBlock)
			return scopeFor(context.vars)
		
		//Variables cannot be used in time constraints but still a variable can be put as an expression
		if(context instanceof TimeConstraintsBlock)
			return IScope.NULLSCOPE
		
		//Variables imported from the system config file
		/*if(context instanceof FeatureExpression){
			val configs = CommaUtilities::resolveProxy(context, this.
			getScope(context, ConfigurationPackage.Literals.FEATURE_DEFINITION__FEATURES).allElements)
			.filter[it.eContainer instanceof FeatureDefinition]
			return scopeFor(configs)
		}*/
		
		return scope_variable(context.eContainer)
	}
	
	def scope_Transition_trigger(TriggeredTransition context, EReference ref){ 
		scope_forEvent(context, null)		
  	}
  	
	def scope_Event_state(EventInState context, EReference ref){
		var List<State> states = new ArrayList<State>();
		for(sm : (EcoreUtil2::getContainerOfType(context, AbstractBehavior) as AbstractBehavior).machines){
			states.addAll(sm.states)
		}
		
		return scopeFor(states)
	}
	
	def scope_forEvent(EObject context, Signature i){
		if(i !== null) return scopeFor(InterfaceUtilities::getAllInterfaceEvents(i))
		
		var List<Signature> interfaces = findVisibleInterfaces(context)
		var List<InterfaceEvent> events = new ArrayList<InterfaceEvent>
		
		for(i1 : interfaces) 
			events.addAll(InterfaceUtilities::getAllInterfaceEvents(i1));
			
		return scopeFor(events)
		
	}
}