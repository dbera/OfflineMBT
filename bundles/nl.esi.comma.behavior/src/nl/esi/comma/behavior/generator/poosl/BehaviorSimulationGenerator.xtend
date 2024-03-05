package nl.esi.comma.behavior.generator.poosl

import java.util.ArrayList
import java.util.List
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.State
import nl.esi.comma.behavior.behavior.StateMachine
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import nl.esi.comma.behavior.utilities.StateMachineUtilities
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.signature.utilities.InterfaceUtilities
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess

abstract class BehaviorSimulationGenerator extends PooslGenerator {

	public final static String UTILITY_DATA_CLASS = "Utility";
	
	final static String SIMULATION_PROCESS_CLASS = "SimulationClass";	
	final static String PLAYER_PROCESS_CLASS = "Player";	
	
	AbstractBehavior behavior
	
	new(String fileName, AbstractBehavior behavior, IFileSystemAccess fsa) {
		super(fileName, fsa)
		this.behavior = behavior
	}

	def doGenerate() {		
		generateFile(toSimulationClass())		
	}

	def toSimulationClass() '''
		import "../api/"
		import "../api/"
		«generateImportsForInterfaces»
		
		/* utility data class that holds global variables and current states */
		«generateUtilityClass»
		«generateSimulationClass»
		«generatePlayerClass»
		«generateSystemSpec»
	'''
	
	def	generateSimulationClass()
	'''
			process class «SIMULATION_PROCESS_CLASS»()
			ports
			/* Port for receiving and sending */
			/* For every used interface -> port is generated */
				port«signature.name»
				
			messages
			/* input messages derived from interface commands in the signature */
				«FOR c : InterfaceUtilities::getCommandsAndSignals(signature)»
					port«signature.name» ? «signature.name»_«c.name»«IF c.parameters.size() > 0»(«FOR pt : c.parameters SEPARATOR ', '»«toPOOSLType(pt.type)»«ENDFOR»)«ENDIF»
				«ENDFOR»
				
			/* output messages for notifications in the signature*/
				«FOR n : signature.notifications»
					port«signature.name» ! «signature.name»_«n.name»«IF n.parameters.size() > 0»(«FOR pt : n.parameters SEPARATOR ', '»«toPOOSLType(pt.type)»«ENDFOR»)«ENDIF»
				«ENDFOR»
				
			/* output messages for reply after command */
				port«signature.name» ! reply(Object)
			
			variables
			/* variables for the state */
				stateOfDecisionClass : «UTILITY_DATA_CLASS»
			
			/* variable for reply values */
				o : Object
			
			/* variables used in message reception */
				«FOR v : getAllTriggerVariables(behavior)»
					«VAR_NAME_PREFIX»«v» : Object
				«ENDFOR»
			
			init
				init()()
			
			methods
			/* initial method */
			init()()
			/* initialization of the state variable */
				stateOfDecisionClass := new(«UTILITY_DATA_CLASS»);
				stateOfDecisionClass init();
			
				/* call the methods for the initial states of the machines */
				«IF behavior.machines.size() > 1»
					par
					«FOR sm : behavior.machines SEPARATOR '
	and'»
						«sm.name»_«sm.states.filter(s | s.initial).get(0).name»()()
					«ENDFOR»
					rap
				«ELSE»
					«behavior.machines.get(0).name»_«behavior.machines.get(0).states.filter(s | s.initial).get(0).name»()()
				«ENDIF»
			
			/* methods that implement machine states */
			«FOR sm : behavior.machines»
				«FOR s : sm.states»
					«sm.name»_«s.name»()()
						«generateStateBody(s, sm)»
				«ENDFOR»
			«ENDFOR»
	'''

	def generateStateBody(State s, StateMachine sm) {
		var Iterable<TriggeredTransition> calledTransitions = StateMachineUtilities.getTriggeredTransitions(sm, s);
		var Iterable<Transition> notificationTransitions = StateMachineUtilities.getNonTriggeredTransitions(sm, s);

		// state body
		'''
			«IF (calledTransitions.size() > 0) || (notificationTransitions.size() > 0)»
				sel
					«FOR trans : calledTransitions SEPARATOR '
or'»
						«generateTriggeredTransitionBody(sm, s, trans)»	
					«ENDFOR»
				«IF (notificationTransitions.size() > 0) && (calledTransitions.size() > 0) »
					or
				«ENDIF»
				«FOR trans : notificationTransitions SEPARATOR '
or'»
					«generateNotificationTransitionBody(sm, s, trans)»
				«ENDFOR»
				les
			«ELSE»
				skip
			«ENDIF»
			
		'''
	}

	def generateNotificationTransitionBody(StateMachine sm, State s, Transition t) {
		'''
			«IF t.guard !== null»[«generateExpression(t.guard)»]«ENDIF»
			«generateGenericTransitionBody(t, sm.name, s.name)»
		'''
	}

	def generateGenericTransitionBody(Transition t, String machineName, String stateName) '''
		«IF t.clauses.size() > 1»
			sel
				«FOR cl : t.clauses SEPARATOR '
or'»
					«generateClauseBody(cl, machineName, stateName)»
				«ENDFOR»
			les
		«ELSE»
			«generateClauseBody(t.clauses.get(0), machineName, stateName)»
		«ENDIF»
	'''

	def generateClauseBody(Clause cl, String machineName, String stateName) '''
		«IF cl.actions !== null»
			«FOR a : cl.actions.actions»
				«generateAction(a)»;
			«ENDFOR»
		«ENDIF»
		«IF cl.target !== null»
			stateOfDecisionClass set_«machineName»("«cl.target.name»");
			«machineName»_«cl.target.name»()()
		«ELSE»
			«machineName»_«stateName»()()
		«ENDIF»
	'''

	def generateTriggeredTransitionBody(StateMachine sm, State s, Transition t) {
		'''
			port«getInterface(t as TriggeredTransition).name» ? «getInterface(t as TriggeredTransition).name»_«(t as TriggeredTransition).trigger.name»(«IF (t as TriggeredTransition).parameters.size() > 0»«FOR v : (t as TriggeredTransition).parameters SEPARATOR ', '»«VAR_NAME_PREFIX»«v.name»«ENDFOR»«ENDIF»«IF t.guard !== null» | «generateExpression(t.guard)»«ENDIF»);
			«generateGenericTransitionBody(t, sm.name, s.name)»
		'''
	}

	def List<String> getAllTriggerVariables(AbstractBehavior intdef) {
		var List<String> result = new ArrayList<String>()

		for (sm : intdef.machines) {
			for(allStatesBlock : sm.inAllStates){
				for (t : allStatesBlock.transitions) {
					if(t instanceof TriggeredTransition){
						for (p : t.parameters) {
							if(!result.contains(p.name)) result.add(p.name)
						}
					}
				}
			}
			for (s : sm.states) {
				for (t : s.transitions) {
					if(t instanceof TriggeredTransition){
						for (p : t.parameters) {
							if(!result.contains(p.name)) result.add(p.name)
						}
					}
				}
			}
		}

		result
	}

	def generatePlayerClass() '''
		/* TODO: this is a dummy skeleton class for stimulating the model */
		
		process class «PLAYER_PROCESS_CLASS»()
		
		ports
			port«signature.name»
		
		messages
		
		/* output messages derived from interface commands of provided interfaces */
			«FOR c : InterfaceUtilities::getCommandsAndSignals(signature)»
				port«signature.name» ! «signature.name»_«c.name»«IF c.parameters.size() > 0»(«FOR pt : c.parameters SEPARATOR ', '»«toPOOSLType(pt.type)»«ENDFOR»)«ENDIF»
			«ENDFOR»
		
		/* input messages for notifications in provided interfaces*/
			«FOR n : signature.notifications»
				port«signature.name» ? «signature.name»_«n.name»«IF n.parameters.size() > 0»(«FOR pt : n.parameters SEPARATOR ', '»«toPOOSLType(pt.type)»«ENDFOR»)«ENDIF»
			«ENDFOR»
		
		/* input messages for reply after command */
			port«signature.name» ? reply(Object)
		
		variables
			o : Object
		
		init
			init()()
		
		methods
		
			/* initial method */
			init()()
				par
					listener()()
				and
					sender()()
				rap
		
			listener()()
				sel
					«FOR n : signature.notifications SEPARATOR '
or'»
					port«(n.eContainer() as Signature).name» ? «(n.eContainer() as Signature).name»_«n.name»«IF n.parameters.size() > 0»(«FOR pt : n.parameters SEPARATOR ', '»o«ENDFOR»)«ENDIF»;
					listener()()
					«ENDFOR»
				«IF !signature.notifications.empty»
					or
				«ENDIF»
					port«signature.name» ? reply(o);
					listener()()
				les
		
			sender()()
			sel
				«val commands = InterfaceUtilities::getCommandsAndSignals(signature)»
				«IF !commands.empty»
				«FOR n : commands SEPARATOR '
or'»
				port«(n.eContainer() as Signature).name» ! «(n.eContainer() as Signature).name»_«n.name»«IF n.parameters.size() > 0»(«FOR pt : n.parameters SEPARATOR ', '»«generateDefaultValue(pt.type)»«ENDFOR»)«ENDIF»;
				sender()()
				«ENDFOR»
				«ELSE»
				skip
				«ENDIF»
			les
		
	'''
	
	

	def generateSystemSpec() '''
		system
		instances
			player : «PLAYER_PROCESS_CLASS»()
			simulation : «SIMULATION_PROCESS_CLASS»()
		channels
			{player.port«signature.name», simulation.port«signature.name»}
	'''

	def generateUtilityClass() {
		quantifiersInMachines = getQuantifiersInStateMachines(behavior, behavior.machines);

		'''
			data class «UTILITY_DATA_CLASS» extends Object
			variables
			
			/* variables from the spec */
				«FOR v : behavior.vars»
					«VAR_NAME_PREFIX»«v.name» : «toPOOSLType(v.type)»
				«ENDFOR»
			
			/* variables for current state in machines */
				«FOR sm : behavior.machines»
					«sm.name» : String
				«ENDFOR»
			
			methods
			
			/* getters and setters for global variables */
				«FOR v : behavior.vars»
					get_«VAR_NAME_PREFIX»«v.name» : «toPOOSLType(v.type)»
						return «VAR_NAME_PREFIX»«v.name»
					
					set_«VAR_NAME_PREFIX»«v.name»(i : «toPOOSLType(v.type)») : «UTILITY_DATA_CLASS»
						«VAR_NAME_PREFIX»«v.name» := i;
						return self
					
				«ENDFOR»
			/* getters and setter for variables that hold current state */
				«FOR sm : behavior.machines»
					get_«sm.name» : String
						return «sm.name»
					
					set_«sm.name»(i : String) : «UTILITY_DATA_CLASS»
						«sm.name» := i;
						return self
					
				«ENDFOR»
				
			«IF quantifiersInMachines.size > 0»
				/* methods that implement quantifiers */
					«FOR quantifier : quantifiersInMachines»
						«generateQuantifierMethod(quantifier, quantifiersInMachines.indexOf(quantifier))»
					«ENDFOR»
			«ENDIF»
			
			/* init method */
				init() : «UTILITY_DATA_CLASS»
			
			/* initialization of global variables with default values for safety reasons */
					«FOR v : behavior.vars» 
					«VAR_NAME_PREFIX»«v.name» := «generateDefaultValue(v.type)»;
					«ENDFOR»
			
			/* initialization of global variables in model init section */
					«FOR a : behavior.initActions» 
						«generateAction(a)»;
					«ENDFOR»
				
				/* initilization of current state variables */
						«FOR sm : behavior.machines»
							«val initialstates = sm.states.filter(s | s.initial)»
							«IF !initialstates.empty»
								«sm.name» := "«sm.states.filter(s | s.initial).get(0).name»";
							«ENDIF»
						«ENDFOR»
						return self
		'''
	}

	/* new specializations of actions */
	def dispatch CharSequence generateAction(CommandReply a) 
	'''port«getInterfaceName(a)» ! reply(«IF a.parameters.size() > 0»«FOR p : a.parameters SEPARATOR ',' AFTER ''»«generateExpression(p)»«ENDFOR»«ELSE»nil«ENDIF»)'''

	def dispatch CharSequence generateAction(EventCall a) {
		val String intName = (a.event.eContainer as Signature).name
		'''
			«IF a.event instanceof Command»
			port«intName» ! «intName»_«a.event.name»«IF a.parameters.size() > 0»(«FOR p : a.parameters SEPARATOR ', '»«generateExpression(p)»«ENDFOR»)«ENDIF»;
			port«intName» ? reply(o)
			«ELSE»
			port«intName» ! «intName»_«a.event.name»«IF a.parameters.size() > 0»(«FOR p : a.parameters SEPARATOR ', '»«generateExpression(p)»«ENDFOR»)«ENDIF»
			«ENDIF»
		'''
	}

	def getInterfaceName(CommandReply c) {		
		val transition = EcoreUtil2.getContainerOfType(c, TriggeredTransition)		
		getInterface(transition).name
	}
	
    abstract def Signature getSignature()
}
