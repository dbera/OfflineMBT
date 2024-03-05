package nl.esi.comma.behavior.utilities

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.ActionList
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.NonTriggeredTransition
import nl.esi.comma.behavior.behavior.ProvidedPort
import nl.esi.comma.behavior.behavior.RequiredPort
import nl.esi.comma.behavior.behavior.State
import nl.esi.comma.behavior.behavior.StateMachine
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import nl.esi.comma.behavior.generator.poosl.PortEventPair
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.signature.interfaceSignature.Notification
import nl.esi.comma.signature.interfaceSignature.Signal
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.signature.utilities.InterfaceUtilities
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypesPackage
import nl.esi.comma.types.utilities.CommaUtilities
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.IScopeProvider
import nl.esi.comma.actions.actions.ParallelComposition

import static extension nl.esi.comma.actions.utilities.ActionsUtilities.*
import nl.esi.comma.actions.actions.PCFragmentReference
import nl.esi.comma.actions.actions.PCElement

class StateMachineUtilities {
	
	def static Signature getSignatureForMachine(EObject context, IScopeProvider scopeProvider) {
		val signatures = CommaUtilities::resolveProxy(context, 
			scopeProvider.getScope(context, ExpressionPackage.Literals.INTERFACE_AWARE_TYPE__INTERFACE).getAllElements
		)
		
		if(! signatures.empty){
			return signatures.get(0)
		}
		return null;
	}
	
	def static List<Signature> getSignatures(EObject context, IScopeProvider scopeProvider) {
		CommaUtilities::resolveProxy(context, 
			scopeProvider.getScope(context, ExpressionPackage.Literals.INTERFACE_AWARE_TYPE__INTERFACE).getAllElements
		)
	}
	
	/*
	 * Returns all transitions for a given state and machine including the 
	 * transitions for all states and for the given state
	 */
	
	def static List<Transition> transitionsForState(State s){
		return transitionsForState(s.eContainer as StateMachine, s)
	}
	
	def static List<Transition> transitionsForState(StateMachine sm, State s) {
		var ArrayList<Transition> transitions = new ArrayList<Transition>()

		for(allStatesBlock : sm.inAllStates){
			if(! allStatesBlock.excludedStates.contains(s)){
				transitions.addAll(allStatesBlock.transitions)
			}
		}
		if(s !== null){
			transitions.addAll(s.transitions)
		}
		transitions
	}	
	
	def static List<TriggeredTransition> getTriggeredTransitions(StateMachine sm, State s){		
		transitionsForState(sm, s).filter(TriggeredTransition).toList		
	}
	
	def static List<Transition> getNonTriggeredTransitions(StateMachine sm, State s){
		var transitions = new ArrayList<Transition>()
		transitions.addAll(transitionsForState(sm, s).filter(t | t instanceof NonTriggeredTransition))
		transitions
	}
	
	def static Transition getTransitionContainer(CommandReply r){
		EcoreUtil2.getContainerOfType(r, Transition)
	}
	
	def static Transition getTransitionContainer(Clause c){
		EcoreUtil2.getContainerOfType(c, Transition)
	}
	
	def static List<InterfaceEvent> getAllTriggers(StateMachine sm){
		var result = new ArrayList<InterfaceEvent>
		for(s : sm.states){
			for(t : getTriggeredTransitions(sm, s)){
				if(!result.contains((t as TriggeredTransition).trigger))
					result.add((t as TriggeredTransition).trigger)
			}
		}
		result
	}
	
	def static List<InterfaceEvent> getAllNotifications(StateMachine sm){
		var result = new ArrayList<InterfaceEvent>()
		val evCalls = EcoreUtil2::getAllContentsOfType(sm, EventCall)	
		for(evCall : evCalls){
			if( (evCall.event instanceof Notification) && ! result.contains(evCall.event)) {
				result.add(evCall.event)
			}
		}
		val pComposition = EcoreUtil2::getAllContentsOfType(sm, ParallelComposition)
		for(p : pComposition){
			for(c : p.flatten){
				if(c instanceof EventCall){
					if( (c.event instanceof Notification) && ! result.contains(c.event)) {
						result.add(c.event)
					}
				}
			}
		}
		result
	}
	
	def static StateMachine getStateMachineContainer(EObject  o){		
		EcoreUtil2.getContainerOfType(o, StateMachine)
	}
	
	def static List<ExpressionVariable> getAllExpressionVariables(State state){
		var List<ExpressionVariable> variables = new ArrayList<ExpressionVariable>()
		variables.addAll(EcoreUtil2.getAllContentsOfType(state,ExpressionVariable))
		return variables
	}
	
	static def List<RecordTypeDecl> getRecordTypes(EObject topLevelObject, IScopeProvider scopeProvider){
		CommaUtilities::resolveProxy(topLevelObject, scopeProvider.getScope(topLevelObject, ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE).allElements)
	}
	
	static def List<TypeDecl> getGlobalTypesForConfig(EObject topLevelObject, IScopeProvider scopeProvider){
        var List<TypeDecl> allTypes = CommaUtilities::resolveProxy(topLevelObject, scopeProvider.getScope(topLevelObject, TypesPackage.Literals.TYPE__TYPE).allElements)
        var result = new ArrayList<TypeDecl>()
        
        for(t : allTypes){
            //if(! (t.eContainer instanceof Signature) && !TypeUtilities.isPredefinedType(t)) 
            result.add(t)
        }
        
        result
    }
	
	
	static def List<TypeDecl> getGlobalTypes(EObject topLevelObject, IScopeProvider scopeProvider){
		var List<TypeDecl> allTypes = CommaUtilities::resolveProxy(topLevelObject, scopeProvider.getScope(topLevelObject, TypesPackage.Literals.TYPE__TYPE).allElements)
		var result = new ArrayList<TypeDecl>()
		
		for(t : allTypes){
			if(! (t.eContainer instanceof Signature) && !TypeUtilities.isPredefinedType(t)) 
				result.add(t)
		}
		
		result
	}
	
	static def Map<StateMachine, List<InterfaceEvent>> getEventPartitions(AbstractBehavior behavior, Signature sig) {
		var result = new HashMap<StateMachine, List<InterfaceEvent>>()
		var List<InterfaceEvent> unusedEvents = InterfaceUtilities::getAllInterfaceEvents(sig)
		for (m : behavior.machines) {
			val triggersForMachine = getAllTriggers(m)
			unusedEvents.removeAll(triggersForMachine)
			result.put(m, triggersForMachine)
		}
		for (m : behavior.machines) {
			val notificationsForMachine = getAllNotifications(m)
			unusedEvents.removeAll(notificationsForMachine)
			result.get(m).addAll(notificationsForMachine)
		}
		result.get(behavior.machines.get(0)).addAll(unusedEvents)

		result
	}

	def static HashMap<String, ArrayList<Transition>> getPNCommandsMapForState(StateMachine sm, State s) 
	{
		var commands_map = new HashMap<String, ArrayList<Transition>>
		var ArrayList<Transition> list_of_command_transitions
		
		for(transition : StateMachineUtilities::transitionsForState(sm, s)) 
		{
			//if(transition.trigger !== null)
			if(transition instanceof TriggeredTransition)
			{
				if(transition.trigger instanceof Command) 
				{
					val transitionName = transition.trigger.name
					if(commands_map.containsKey(transitionName)) {
						list_of_command_transitions = commands_map.get(transitionName) }
					else {
						list_of_command_transitions = new ArrayList<Transition> }

					list_of_command_transitions.add(transition)
					commands_map.put(transitionName, list_of_command_transitions)
				}
			}
		}
		
		commands_map
	}
		
	def static HashMap<String, ArrayList<Transition>> getPNSignalsMapForState(StateMachine sm, State s) 
	{
		var signals_map = new HashMap<String, ArrayList<Transition>>
		var ArrayList<Transition> list_of_signal_transitions
		
		for(transition : StateMachineUtilities::transitionsForState(sm, s)) 
		{
			//if(transition.trigger !== null)
			if(transition instanceof TriggeredTransition)
			{
				if(transition.trigger instanceof Signal) 
				{
					val transitionName = transition.trigger.name
					if(signals_map.containsKey(transitionName)) 
					{
						list_of_signal_transitions = signals_map.get(transitionName)
					}
					else 
					{
						list_of_signal_transitions = new ArrayList<Transition> 
					}

					list_of_signal_transitions.add(transition)
					signals_map.put(transitionName, list_of_signal_transitions)
				}
			}
		}
		
		signals_map
	}
	
	def static HashMap<String, ArrayList<Transition>> getPNNotificationsMapForState(StateMachine machine, State state) 
	{
		var notifications_map = new HashMap<String, ArrayList<Transition>>
		var ArrayList<Transition> list_of_notification_transitions
		
		for(transition : StateMachineUtilities::transitionsForState(machine, state))
		{
			//if(transition.trigger === null)
			if(transition instanceof NonTriggeredTransition)
			{
				for(clause : transition.clauses)
				{
					if(clause.actions !== null)
					{
						for(action: clause.actions.actions)
						{
							if(action instanceof EventCall)
							{
								val eventAction = action as EventCall
								val eventActionName = eventAction.event.name

								if(notifications_map.containsKey(eventActionName)) {
									list_of_notification_transitions = notifications_map.get(eventActionName) }
								else {
									list_of_notification_transitions = new ArrayList<Transition> }
			
								list_of_notification_transitions.add(transition)
								notifications_map.put(eventActionName, list_of_notification_transitions)						
							}
						}
					}
				}
			}
		}

		notifications_map
	}

	def static constructCommandTypeName(Command c, String interface_name)
	{
		if(c.type.type.name.equals("void"))
		{ return "void"; }
		
		if(c.type.type instanceof EnumTypeDecl)
		{ return interface_name+"::"+c.type.type.name+"::"+c.type.type.name; }
		else if(c.type.type instanceof SimpleTypeDecl)
		{ return c.type.type.name; }
		else
		{ return interface_name+"::"+c.type.type.name; }
	}

	// TODO Deprecated. Delete after checking no Usage.
	def static getReturnType(TriggeredTransition t)
	{
		val event = t.trigger
		if(event instanceof Command)
		{
			return event.type.type.name
		}
		else
		{
			return "void"	
		}
	}
	
	// Note: Used by both the CPP and Java Versions
	def static HashMap<String, ArrayList<Transition>> getCommandsMapForState(StateMachine sm, Signature sig, State s) 
	{
		var commands_map = new HashMap<String, ArrayList<Transition>>
		var ArrayList<Transition> list_of_command_transitions
		
		for(transition : StateMachineUtilities::transitionsForState(sm, s)) 
		{
			// if(transition.trigger !== null)
			if(transition instanceof TriggeredTransition) 
			{
				if(transition.trigger instanceof Command) 
				{
					// val transitionName = getContainingInterfaceOfCommand(transition.trigger as Command)+"_"+transition.trigger.name
					val transitionName = sig.name+"_"+transition.trigger.name
					if(commands_map.containsKey(transitionName)) {
						list_of_command_transitions = commands_map.get(transitionName) }
					else {
						list_of_command_transitions = new ArrayList<Transition> }

					list_of_command_transitions.add(transition)
					commands_map.put(transitionName, list_of_command_transitions)
				}
			}
		}
		
		commands_map
	}
	
	// Note: Used by both the CPP and Java Versions
	def static HashMap<String, ArrayList<Transition>> getSignalsMapForState(StateMachine sm, Signature sig, State s) 
	{
		var signals_map = new HashMap<String, ArrayList<Transition>>
		var ArrayList<Transition> list_of_signal_transitions
		
		for(transition : StateMachineUtilities::transitionsForState(sm, s)) 
		{
			// if(transition.trigger !== null)
			if(transition instanceof TriggeredTransition) 
			{
				if(transition.trigger instanceof Signal) 
				{
					val transitionName = sig.name+"_"+transition.trigger.name
					if(signals_map.containsKey(transitionName)) 
					{
						list_of_signal_transitions = signals_map.get(transitionName)
					}
					else 
					{
						list_of_signal_transitions = new ArrayList<Transition> 
					}

					list_of_signal_transitions.add(transition)
					signals_map.put(transitionName, list_of_signal_transitions)
				}
			}
		}
		
		signals_map
	}

	def static checkTransitionForReplies(NonTriggeredTransition nt) 
	{
		var boolean isReplyTransition = false
		//if (t.trigger instanceof Command) {
			for (cl : nt.clauses) {
				if(! EcoreUtil2::getAllContentsOfType(cl, CommandReply).empty) {
					if (hasReply(cl.actions))
						isReplyTransition = true
				}
			}
		//}
		return isReplyTransition
	}

	def static boolean hasReply(ActionList actionList) {
		if (actionList === null) {
			return false
		}
		for (action : actionList.actions) {
			if (action instanceof CommandReply) {
				return true
			}
			if (action instanceof IfAction) {
				if (hasReply(action.thenList) && hasReply(action.elseList)) {
					return true
				}
			}
		}
		return false
	}

	// Get command of signature of reply
	def static getReplyToCommandName(NonTriggeredTransition nt) 
	{
		//var String command_name = "NULL"
		//if (t.trigger instanceof Command) {
			for (cl : nt.clauses) {
				if(! EcoreUtil2::getAllContentsOfType(cl, CommandReply).empty) {
					if(getAnyReply(cl.actions) !== null) 
						return getAnyReply(cl.actions)
					//if (hasReply(cl.actions))
						//isReplyTransition = true
				}
			}
		//}
		return null
	}

	// If a reply exists then get the command reference present in signature
	def static InterfaceEvent getAnyReply(ActionList actionList) {
		if (actionList === null) {
			return null
		}
		for (action : actionList.actions) {
			if (action instanceof CommandReply) {
				return action.command.event
				//return true
			}
			if (action instanceof IfAction) {
				if(getAnyReply(action.thenList) !== null) 
					return getAnyReply(action.thenList)
				if(getAnyReply(action.elseList) !== null)
					return getAnyReply(action.thenList)
				//if (getAnyReply(action.thenList) && getAnyReply(action.elseList)) return true
			}
		}
		return null
	}

	// Note: Used by both the CPP and Java Versions
	// New constraint [deferred replies handling]: Transitions should not have replies in their clauses! 
	// If a Non Triggered Transition has a Reply then it should be handled as a Reply transition. 
	def static HashMap<String, ArrayList<Transition>> getNotificationsMapForState(StateMachine machine, Signature sig, State state) 
	{
		//var notifications_map = new HashMap<String, ArrayList<Transition>>
		//var ArrayList<Transition> list_of_notification_transitions
		
		// Added DB: 30.07.2020: variable to determine if a notification was already visited in a clause
		var isNotificationFoundInClause = false
		
		var ClauseParserUtility clParserUtility = new ClauseParserUtility(sig.name)
		
		//System.out.println("State: "+ state.name)
		
		for(transition : StateMachineUtilities::transitionsForState(machine, state))
		{
			if(transition instanceof NonTriggeredTransition)
			{
				if(!checkTransitionForReplies(transition))
				{
					for(clause : transition.clauses)
					{
						isNotificationFoundInClause = false // New Clause means search for first notification occurence
						if(clause.actions !== null)
						{
							for(action: clause.actions.actions)
							{
								// Edited 30.07.2020: was only a call to clParserUtility.generateAllActionsForClause(action, transition)
								// Added checks to prevent further notifications from being added as duplicate NT transition with different label in PNET file
								if(!isNotificationFoundInClause) clParserUtility.generateAllActionsForClause(action, transition)
								if(action instanceof EventCall || action instanceof ParallelComposition) {
									isNotificationFoundInClause = true
								}
							}
						}
					}
				}
			}
		}
		// for(elm : clParserUtility.notificationsMap.keySet)
            // System.out.println("elm: " + elm)
		clParserUtility.notificationsMap
	}

	def static HashMap<String, ArrayList<Transition>> getRepliesMapForState(StateMachine machine, Signature sig, State state) 
	{
		var replies_map = new HashMap<String, ArrayList<Transition>>
		var ArrayList<Transition> list_of_reply_transitions
		//var ClauseParserUtility clParserUtility = new ClauseParserUtility(sig.name)
		
		for(transition : StateMachineUtilities::transitionsForState(machine, state))
		{
			if(transition instanceof NonTriggeredTransition)
			{
				if(checkTransitionForReplies(transition))
				{
					val transitionName = sig.name+"_" + getReplyToCommandName(transition).name //transition.trigger.name
					//System.out.println(transitionName)
					if(replies_map.containsKey(transitionName)) {
						list_of_reply_transitions = replies_map.get(transitionName) }
					else {
						list_of_reply_transitions = new ArrayList<Transition> }

					list_of_reply_transitions.add(transition)
					replies_map.put(transitionName, list_of_reply_transitions)
				}
			}
		}
		return replies_map
	}


	// TODO: Clarify the Functionality.
	def static ArrayList<ArrayList<String>> getNestedListOfNotification(StateMachine machine, Signature sig, State state)
	{
		var ArrayList<ArrayList<String>> ni_listOflist = new ArrayList<ArrayList<String>>()
		
		for(transition : StateMachineUtilities::transitionsForState(machine, state))
		{
			// if(transition.trigger === null)
			if(transition instanceof NonTriggeredTransition)
			{
				for(clause : transition.clauses)
				{
					if(clause.actions !== null)
					{
						var ArrayList<String> ni_list = new ArrayList<String>()
						for(action: clause.actions.actions)
						{
							if(action instanceof EventCall)
							{
								val eventAction = action as EventCall
								//val eventActionName = eventAction.interface.name+"_"+eventAction.event.name
								//val eventActionName = getContainingInterfaceOfNotification(eventAction as Notification)+"_"+eventAction.event.name
								//val eventActionName = eventAction.event.name
								//val eventActionName = getContainingInterfaceOfNotification(eventAction.event as Notification)+"_"+eventAction.event.name
								val eventActionName = sig.name+"_"+eventAction.event.name
								if(!determineIfNotificationExistsInList(eventActionName, ni_list, ni_listOflist))
								{
									ni_list.add(eventActionName);
								}
							}
						}
						ni_listOflist.add(ni_list);
					}
				}
			}
		}
		
		ni_listOflist		
	}
	
	def static determineIfNotificationExistsInList(String ni_name, ArrayList<String> ni_list, ArrayList<ArrayList<String>> ni_listOflist)
	{
		if(ni_list.contains(ni_name)) 
			return true
		
		for(elm_list : ni_listOflist)
			if(elm_list.contains(ni_name))
				return true
		
		return false
	}

	// Unlike the function: getNestedListOfNotification, this function returns duplicate events as well
	def static ArrayList<ArrayList<String>> getAllNestedListOfNotifications(StateMachine machine, Signature sig, State state)
	{
		var ArrayList<ArrayList<String>> ni_listOflist = new ArrayList<ArrayList<String>>()
		
		for(transition : StateMachineUtilities::transitionsForState(machine, state))
		{
			if(transition instanceof NonTriggeredTransition)
			{
				for(clause : transition.clauses)
				{
					if(clause.actions !== null)
					{
						var ArrayList<String> ni_list = new ArrayList<String>()
						for(action: clause.actions.actions)
						{
							if(action instanceof EventCall)
							{
								val eventAction = action as EventCall
								//val eventActionName = eventAction.interface.name+"_"+eventAction.event.name
								//val eventActionName = getContainingInterfaceOfNotification(eventAction as Notification)+"_"+eventAction.event.name
								//val eventActionName = eventAction.event.name
								//val eventActionName = getContainingInterfaceOfNotification(eventAction.event as Notification)+"_"+eventAction.event.name
								val eventActionName = sig.name+"_"+eventAction.event.name
								//if(!determineIfNotificationExistsInList(eventActionName, ni_list, ni_listOflist))
								//{
									ni_list.add(eventActionName);
								//}
							}
						}
						ni_listOflist.add(ni_list);
					}
				}
			}
		}
		
		ni_listOflist		
	}
	
	//Pay attention that we do not handle yet commands to required ports
	def static Iterable<PortEventPair> getIncomingEvents(List<PortEventPair> events){
		events.filter(e | (e.port instanceof ProvidedPort && (e.event instanceof Command || e.event instanceof Signal)) ||
			              (e.port instanceof RequiredPort && e.event instanceof Notification)
		)
	}
	
	def static Iterable<PortEventPair> getIncomingCommands(List<PortEventPair> events){
		events.filter(e | e.isIncomingCommand)
	}
	
	//Note that outgoing commands are not supported at the moment
	//It is unclear if this support will be required for components
	def static Iterable<PortEventPair> getOutgoingEvents(List<PortEventPair> events){
		events.filter(e | (e.port instanceof ProvidedPort && e.event instanceof Notification) ||
			              (e.port instanceof RequiredPort && e.event instanceof Signal)
		)
	}
	
	def static isIncomingCommand(PortEventPair ev){
		ev.port instanceof ProvidedPort && ev.event instanceof Command
	}
}

class ClauseParserUtility
{
	var HashMap<String, ArrayList<Transition>> notifications_map
	var ArrayList<Transition> list_of_notification_transitions
	var String signature_name
	
	new(String _signature_name) {
		notifications_map = new HashMap<String, ArrayList<Transition>>
		signature_name = _signature_name
	}
	
	def getNotificationsMap() { return notifications_map }
	
	// Helper function for Notification Map Generation
	def void generateAllActionsForClause(Action action, NonTriggeredTransition transition)
	{	
		if(action instanceof AssignmentAction || 
			action instanceof IfAction || 
			action instanceof RecordFieldAssignmentAction || 
			action instanceof CommandReply || 
			action instanceof EventCall ||
			action instanceof ParallelComposition
		)
			generateAssignmentAction(action, transition)
	}

	def dispatch void generateAssignmentAction(AssignmentAction action, NonTriggeredTransition transition){}
	def dispatch void generateAssignmentAction(IfAction action, NonTriggeredTransition transition){
		for(act : action.thenList.actions)
			generateAssignmentAction(act, transition)
		if(action.elseList !== null) {
			for(act : action.elseList.actions)
				generateAssignmentAction(act, transition)
		}
	}
	def dispatch void generateAssignmentAction(RecordFieldAssignmentAction action, NonTriggeredTransition transition){}
	def dispatch void generateAssignmentAction(CommandReply action, NonTriggeredTransition transition){}
	def dispatch void generateAssignmentAction(EventCall action, NonTriggeredTransition transition)
	{
		val eventAction = action as EventCall
		val eventActionName = signature_name+"_"+eventAction.event.name
		//System.out.println("  entry: " + eventAction.event.name)

		if(notifications_map.containsKey(eventActionName)) {
			list_of_notification_transitions = notifications_map.get(eventActionName) }
		else {
			list_of_notification_transitions = new ArrayList<Transition> }
		
		// @DB changed on 25.06.2020. Added check if the same notification was repeated twice in the same transition.
		if(!list_of_notification_transitions.contains(transition)) 
			list_of_notification_transitions.add(transition)
		
		notifications_map.put(eventActionName, list_of_notification_transitions)
	}
	
	// Added 19.03.2021. To handle ParallelComposition.
    def dispatch void generateAssignmentAction(ParallelComposition action, NonTriggeredTransition transition){
        for(elm : action.components) {
            if(elm instanceof EventCall) {
                generateAssignmentAction(action, transition)
            }
            if(elm instanceof PCFragmentReference) {
                for(_elm : elm.fragment.components) {
                    parseFragmentReference(_elm, transition)
                }
            }
        }
    }
    // Added 19.03.2021. To handle ParallelComposition.
    def void parseFragmentReference(PCElement pce, NonTriggeredTransition transition) {
        if(pce instanceof EventCall) { 
            generateAssignmentAction(pce, transition)
        }
        if(pce instanceof PCFragmentReference) {
            for(act : pce.fragment.components) {
                parseFragmentReference(act, transition)
            }
        }
    }
}

// container for list of notifications appearing in a clause
class NotificationUtil 
{
    var name = new String()
    var isNotificationPresent = false
    
    def NotificationUtil() { name = new String() isNotificationPresent = false }
    
    def isNotificationPresent(Clause clause) {
        isNotificationPresent = false
        if(clause.actions !== null) {
            for(action: clause.actions.actions) {
                if(action instanceof AssignmentAction || 
                    action instanceof IfAction || 
                    action instanceof RecordFieldAssignmentAction || 
                    action instanceof CommandReply || 
                    action instanceof EventCall ||
                    action instanceof ParallelComposition
                ) {
                    generateNotificationName(action)
                }           
            }
        }
        return isNotificationPresent
    }
    
    def parseClauseForEventCalls(Clause clause) {
        isNotificationPresent = false
        if(clause.actions !== null) {
            for(action: clause.actions.actions) {
                if(action instanceof AssignmentAction || 
                    action instanceof IfAction || 
                    action instanceof RecordFieldAssignmentAction || 
                    action instanceof CommandReply || 
                    action instanceof EventCall ||
                    action instanceof ParallelComposition
                ) {
                    generateNotificationName(action)
                }           
            }
        }
        return name
    }
    
    def dispatch void generateNotificationName(CommandReply action) {}
    def dispatch void generateNotificationName(AssignmentAction action) {}
    def dispatch void generateNotificationName(RecordFieldAssignmentAction action) {}
    def dispatch void generateNotificationName(EventCall action) {
        val eventAction = action as EventCall
        name += "_" + eventAction.event.name
        isNotificationPresent = true
    }
    def dispatch void generateNotificationName(IfAction action) {
        for(act : action.thenList.actions)
            generateNotificationName(act)
        if(action.elseList !== null) {
            for(act : action.elseList.actions)
                generateNotificationName(act)
        }        
    }
    def dispatch void generateNotificationName(ParallelComposition action) {
        for(elm : action.components) {
            if(elm instanceof EventCall) {
                generateNotificationName(action)
            }
            if(elm instanceof PCFragmentReference) {
                for(_elm : elm.fragment.components) {
                    parseFragmentReference(_elm)
                }
            }
        }
    }
    def void parseFragmentReference(PCElement pce) {
        if(pce instanceof EventCall) { 
            generateNotificationName(pce)
        }
        if(pce instanceof PCFragmentReference) {
            for(act : pce.fragment.components) {
                parseFragmentReference(act)
            }
        }
    }
}

