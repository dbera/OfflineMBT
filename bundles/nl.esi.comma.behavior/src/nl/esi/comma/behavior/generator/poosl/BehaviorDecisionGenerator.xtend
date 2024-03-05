package nl.esi.comma.behavior.generator.poosl;

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import nl.esi.comma.actions.actions.Action
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.ParallelComposition
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.Clause
import nl.esi.comma.behavior.behavior.NonTriggeredTransition
import nl.esi.comma.behavior.behavior.State
import nl.esi.comma.behavior.behavior.StateMachine
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import nl.esi.comma.behavior.utilities.StateMachineUtilities
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.DIRECTION
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.signature.interfaceSignature.Notification
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.signature.utilities.InterfaceUtilities
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess

import static extension nl.esi.comma.actions.utilities.ActionsUtilities.*
import java.util.LinkedList

abstract class BehaviorDecisionGenerator extends ConstraintRulesGenerator {
	
	protected static final String REPLY_SUFFIX = "_r"	
	protected MonitorGenerator monitorGenerator
	protected Map<InterfaceEvent, StateMachine> event2Machine
	protected Map<Clause, String> clause2Method
	protected Map<TriggeredTransition, String> transition2Method
	
	Map<StateMachine, List<InterfaceEvent>> eventPartitions

	new(String fileName, AbstractBehavior behavior, IFileSystemAccess fsa) {
		super(fileName, behavior, fsa)
	}

	def void doGenerate() {
		monitorGenerator = new MonitorGenerator("", fsa)
		eventPartitions = StateMachineUtilities::getEventPartitions(behavior, signature)
		event2Machine = new HashMap<InterfaceEvent, StateMachine>
		clause2Method = new HashMap<Clause, String>
		transition2Method = new HashMap<TriggeredTransition, String>

		for (ev : InterfaceUtilities::getAllInterfaceEvents(signature)) {
			for (sm : eventPartitions.keySet) {
				if (eventPartitions.get(sm).contains(ev)) {
					event2Machine.put(ev, sm)
				}
			}
		}
		generateFile(generatePOOSLContent(behavior))
	}

	def abstract List<PortEventPair> initEvents()

	// Main method for creating the POOSL code
	// TODO this method need to be refined for the cases of Interface and Component
	// When components are introduced, find the commonalities and differences
	def generatePOOSLContent(AbstractBehavior intdef) {
		var events = initEvents

		'''
			«generateInfrastructureImports»
			«generateInterfacesImports»
			
			/* utility data class that holds global variables */
			«generateUtilityClass(intdef, intdef.machines)»
			
			/* constraint rules */
			«generateConstraintRules(intdef)»
			
			«generateDecisionClass(intdef, intdef.machines, events)»
			
			«monitorGenerator.generateMonitor(generatePorts(intdef), StateMachineUtilities::getIncomingEvents(events), StateMachineUtilities::getOutgoingEvents(events))»
		'''
	}

	def generateInfrastructureImports() '''
		import "../api/"
	'''

	def generateInterfacesImports() '''
		import "records.poosl"
	'''

	// Method that creates POOSL decision class for a behavior spec, a collection of state machines
	// and a collection of pairs of interface events and ports
	def CharSequence generateDecisionClass(AbstractBehavior intdef, List<StateMachine> machines,
		List<PortEventPair> events) '''
		«val incomingEvents = StateMachineUtilities::getIncomingEvents(events)»
		«val incomingCommands = StateMachineUtilities::getIncomingCommands(events)»
		«val outgoingEvents = StateMachineUtilities::getOutgoingEvents(events)»
		«val size = determineMaxParamNumber(incomingEvents)»
		process class «decisionClassName(signature)» extends «decisionSuperClass»
		ports
		«generatePorts(intdef)»
		messages
			/* input messages for incoming events */
			«FOR ev : incomingEvents»
			«val parameters = ev.event.parameters.filter(p | p.direction != DIRECTION::OUT)»
			«ev.port.name» ? «ev.event.name»«IF ! parameters.empty»(«FOR p : parameters SEPARATOR ', '»«toPOOSLType(p.type)»«ENDFOR»)«ENDIF»
			«ENDFOR»
			
			/* input messages for outgoing events */
			«FOR ev : outgoingEvents»
			«ev.port.name» ? «ev.event.name»
			«ENDFOR»
			
			/* input messages for checking replies to commands on provided ports */
			«FOR ev : incomingCommands»
			«ev.port.name» ? «ev.event.name»«REPLY_SUFFIX»
			«ENDFOR»
		
		«generateVariablesSection(size)»
		
		«generateInitSection»
		
		«generateProcessInputMethod(events)»
		
		«FOR e : incomingEvents»
			«generateEventRootMethod(e, RootMethodKind::INCOMING)»
			
		«ENDFOR»
		«FOR e : outgoingEvents»
			«generateEventRootMethod(e, RootMethodKind::OUTGOING)»
			
		«ENDFOR»
		«FOR e : incomingCommands»
			«generateEventRootMethod(e, RootMethodKind::REPLY)»
			
		«ENDFOR»
		«generateClauseMethods(machines)»
		«generateIncomingEventMethodsInStates(machines, events)»
		«generateOutgoingEventMethodsInStates(machines, outgoingEvents)»
		«generateOutgoingEventMethodsInStates(machines, incomingCommands)»
	'''

	def CharSequence generateClauseMethods(StateMachine m) '''
		«FOR i : 0..< m.inAllStates.size»
			«generateClauseMethods(m, "block" + (i+1), m.inAllStates.get(i).transitions)»
		«ENDFOR»
		«FOR i : 0..< m.states.size»
			«generateClauseMethods(m, m.states.get(i).name, m.states.get(i).transitions)»
		«ENDFOR»
	'''

	def CharSequence generateClauseMethods(StateMachine m, String nameFragment, List<Transition> transitions) '''
		«FOR i : 0..< transitions.size»
			«FOR j : 0..< transitions.get(i).clauses.size»
				«val methodName = m.name + "_" + nameFragment + "_t" + (i + 1) + "_c" + (j + 1)»
				«generateClauseMethod(m, methodName, transitions.get(i), transitions.get(i).clauses.get(j))»
				
			«ENDFOR»
			«IF transitions.get(i) instanceof TriggeredTransition»
				«generateTriggeredTransitionMethod(m, m.name + "_" + nameFragment + "_t" + (i + 1), transitions.get(i) as TriggeredTransition)»
				
			«ENDIF»
		«ENDFOR»
	'''

	def CharSequence generateClauseMethods(List<StateMachine> machines) '''
		«FOR m : machines»
			«generateClauseMethods(m)»
		«ENDFOR»
	'''

	def CharSequence generateTriggeredTransitionMethod(StateMachine m, String methodName,
		TriggeredTransition transition) {
		transition2Method.put(transition, methodName)
		'''
			«methodName»(stateName : String, tIndex : Integer, result : Sequence«FOR p : transition.parameters», «TVAR_NAME_PREFIX»«p.name» : «toPOOSLType(p.type)»«ENDFOR»)()
				«IF transition.guard !== null»
					if «generateExpression(transition.guard)» then
						«FOR c : transition.clauses»
							«clause2Method.get(c)»(stateName, tIndex, result«FOR p : transition.parameters», «TVAR_NAME_PREFIX»«p.name»«IF TypeUtilities::isStructuredType(p.type)» deepCopy«ENDIF»«ENDFOR»)()«IF c !== transition.clauses.last»;«ENDIF»
						«ENDFOR»
					fi
				«ELSE»
					«FOR c : transition.clauses»
						«clause2Method.get(c)»(stateName, tIndex, result«FOR p : transition.parameters», «TVAR_NAME_PREFIX»«p.name»«IF TypeUtilities::isStructuredType(p.type)» deepCopy«ENDIF»«ENDFOR»)()«IF c !== transition.clauses.last»;«ENDIF»
					«ENDFOR»
				«ENDIF»
		'''
	}

	def CharSequence generateClauseMethod(StateMachine m, String methodName, Transition transition, Clause clause) {
		clause2Method.put(clause, methodName)
		val parametersList = if (transition instanceof TriggeredTransition)
				'''«FOR p : transition.parameters», «TVAR_NAME_PREFIX»«p.name» : «toPOOSLType(p.type)»«ENDFOR»'''
			else
				''''''
		val eventName = getEventName(transition, clause)
		'''
			«methodName»(stateName : String, tIndex : Integer, result : Sequence«parametersList»)()
				|context : «COMMA_PREFIX»ExecutionContext, mp : «COMMA_PREFIX»MessagePattern, pc : CParallelCompositionPattern, clauseKey : String|
				clauseKey := stateName + " transition " + ((tIndex + 1) printString) + "«eventName»" + " clause «transition.clauses.indexOf(clause) + 1»";
				context := new(«COMMA_PREFIX»ExecutionContext) init;
				stateOfDecisionClass := lastReceivedState deepCopy;
				stateOfDecisionClass takeSnapshot;
				«IF clause.actions !== null»
					«FOR a : clause.actions.actions»
						«generateActionInContext(a, null)»;
					«ENDFOR»
				«ENDIF»
				//end of actions
				//check for runtime errors
				«IF transition instanceof TriggeredTransition»
					//checkTriggeredTransition(context)();
				«ELSE»
					//checkNonTriggeredTransition(context)();
				«ENDIF»
				stateOfDecisionClass set_«m.name»(«IF clause.target !== null»"«clause.target.name»"«ELSE»stateName«ENDIF»);
				updateState(stateOfDecisionClass, stateName, «IF clause.target !== null»"«clause.target.name»"«ELSE»stateName«ENDIF», clauseKey, context)();
				result append(context)
		'''
	}

	def CharSequence generateVariablesSection(int size) {
		'''
			variables
				«IF size > 0»
					/* Parameters for messages */
					«FOR i : 0..< size SEPARATOR ', '»p«i»«ENDFOR» : Object
				«ENDIF»
		'''
	}

	def CharSequence generateInitSection() '''
		init
			init()()
		methods
		
		/* initial method */
		init()()
			/* initialization of the state variable */ 
			stateOfDecisionClass := new(«utilityClassName(signature)») init();
			lastReceivedState := stateOfDecisionClass deepCopy;
			
			/* start processing */
			processInput()()
	'''

	def CharSequence generateProcessInputMethod(List<PortEventPair> events) '''
		/* main processing logic */
		processInput()()
			sel
				control ? setState(lastReceivedState);
				stateOfDecisionClass := lastReceivedState deepCopy;
				processInput()()
			or
				control ? reset;
				init()()
			«FOR c : StateMachineUtilities::getIncomingEvents(events)»
			or
				«val parameters = c.event.parameters.filter(p | p.direction != DIRECTION::OUT)»
				«c.port.name» ? «c.event.name»«IF !parameters.empty»(«FOR i : 0..< parameters.size SEPARATOR ', '»p«i»«ENDFOR»)«ENDIF»;
				«eventRootMethodName(c, RootMethodKind::INCOMING)»(«FOR i : 0..< c.event.parameters.size SEPARATOR ', '»«IF c.event.parameters.get(i).direction != DIRECTION::OUT»p«i»«ELSE»new(«COMMA_PREFIX»Any)«ENDIF»«ENDFOR»)()
			«ENDFOR»
			«FOR n : StateMachineUtilities::getOutgoingEvents(events)»
			or
				«n.port.name» ? «n.event.name»;
				«eventRootMethodName(n, RootMethodKind::OUTGOING)»()()
			«ENDFOR»
			«FOR c : StateMachineUtilities::getIncomingCommands(events)»
			or
				«c.port.name» ? «c.event.name»«REPLY_SUFFIX»;
				«eventRootMethodName(c, RootMethodKind::REPLY)»()()
			«ENDFOR»
			les
	'''

	def CharSequence generateEventRootMethod(PortEventPair ev, RootMethodKind methodKind) {
		val stateMachine = event2Machine.get(ev.event)
		val Map<State, Boolean> stateStatus = new HashMap<State, Boolean>
		for (s : stateMachine.states) {
			if(emptyTransitionsInState(ev, s, methodKind)) stateStatus.put(s, false) else stateStatus.put(s, true)
		}
		val positiveStates = stateStatus.filter[s, v|v]

		'''
			/* method for handling «IF methodKind == RootMethodKind::REPLY»reply to «ENDIF»event «ev.event.name» on port «ev.port.name» */
			«eventRootMethodName(ev, methodKind)»(«IF methodKind == RootMethodKind::INCOMING»«FOR p : ev.event.parameters SEPARATOR ', '»«TVAR_NAME_PREFIX»«p.name» : «toPOOSLType(p.type)»«ENDFOR»«ENDIF»)()
				«IF positiveStates.empty»
					control ! noTransitions;
					processInput()()
				«ELSE»
					«IF positiveStates.size == 1»
						«val state = positiveStates.entrySet.get(0).key»
						if stateOfDecisionClass get_«stateMachine.name» = "«state.name»" then
							«eventMethodInStateName(state, ev, methodKind)»(«IF methodKind == RootMethodKind::INCOMING»«FOR p : ev.event.parameters SEPARATOR ', '»«TVAR_NAME_PREFIX»«p.name»«ENDFOR»«ENDIF»)()
						else
							control ! noTransitions; //No transitions for this event are defined in this state
							processInput()()	
						fi
					«ELSE»
						sel
						«FOR i : 0..< stateMachine.states.size»
							«val s = stateMachine.states.get(i)»
							«IF i !== 0»or«ENDIF»
								[stateOfDecisionClass get_«stateMachine.name» = "«s.name»"]
								«IF ! stateStatus.get(s)»
									control ! noTransitions; //No transitions for this event are defined in this state
									processInput()()	
								«ELSE»
								«eventMethodInStateName(s, ev, methodKind)»(«IF methodKind == RootMethodKind::INCOMING»«FOR p : ev.event.parameters SEPARATOR ', '»«TVAR_NAME_PREFIX»«p.name»«ENDFOR»«ENDIF»)()
							«ENDIF»
						«ENDFOR»
						les
					«ENDIF»
				«ENDIF»
		'''
	}

	// Methods that implement the logic for every triggered transition across all states and machines
	def CharSequence generateIncomingEventMethodsInStates(List<StateMachine> machines, List<PortEventPair> events) '''
		«FOR sm : machines»
			«FOR state : sm.states»
				«FOR ev : StateMachineUtilities::getIncomingEvents(events)»
					«val transitions = getTriggeredTransitionsInState(ev, state)»
					«IF ! transitions.empty»
						«generateTriggeredTransitionMethodInState(ev, transitions, state)»
						
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
		«ENDFOR»
	'''

	def CharSequence generateOutgoingEventMethodsInStates(List<StateMachine> machines,
		Iterable<PortEventPair> events) '''
		«FOR sm : machines»
			«FOR state : sm.states»
				«FOR n : events»
					«val transitions = getNonTriggeredTransitionsInState(n, state)»
					«IF ! transitions.empty»
						«generateNonTriggeredTransitionMethodInState(n, transitions, state)»
						
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
		«ENDFOR»
	'''

	def CharSequence generateTriggeredTransitionMethodInState(PortEventPair ev, List<TriggeredTransition> transitions,
		State s) {
		'''
			«eventMethodInStateName(s, ev, RootMethodKind::INCOMING)»(«FOR p : 0..< ev.event.parameters.size SEPARATOR ', '»«VAR_NAME_PREFIX»p«p» : Object«ENDFOR»)()
				|result : Sequence|
				result := new(Sequence) clear;
				«FOR t : transitions»
					«val int transitionIndex = StateMachineUtilities::transitionsForState(s).indexOf(t)»
					«IF transitions.indexOf(t) > 0»
					stateOfDecisionClass := lastReceivedState deepCopy;
					«ENDIF»
					«transition2Method.get(t)»("«s.name»", «transitionIndex», result«FOR p : 0..< ev.event.parameters.size», «VAR_NAME_PREFIX»p«p»«IF TypeUtilities::isStructuredType(ev.event.parameters.get(p).type)» deepCopy«ENDIF»«ENDFOR»)();
				«ENDFOR»
				checkTransitionsResult(result)()
		'''
	}

	def CharSequence generateNonTriggeredTransitionMethodInState(PortEventPair ev,
		List<NonTriggeredTransition> transitions, State s) {
		val methodName = if(StateMachineUtilities::isIncomingCommand(ev)) eventMethodInStateName(s, ev,
				RootMethodKind::REPLY) else eventMethodInStateName(s, ev, RootMethodKind::OUTGOING)
		'''
			«methodName»()()
				|result : Sequence|
				result := new(Sequence) clear;
				«FOR t : transitions»
					«val int transitionIndex = StateMachineUtilities::transitionsForState(s).indexOf(t)»
					//begin transition
					«IF transitions.indexOf(t) > 0»
					stateOfDecisionClass := lastReceivedState deepCopy;
					«ENDIF»
					«IF t.guard !== null»
						if «generateExpression(t.guard)» then
							«generateNonTriggeredTransitionBody(t, s, ev, transitionIndex)»
						fi;
					«ELSE»
						«generateNonTriggeredTransitionBody(t, s, ev, transitionIndex)»;
					«ENDIF»
					//end of transition
				«ENDFOR»
				checkTransitionsResult(result)()
		'''
	}

	def CharSequence generateNonTriggeredTransitionBody(NonTriggeredTransition t, State s, PortEventPair ev,
		int transitionIndex) {
		val clauses = getClausesForOutgoingEvent(t, ev)
		'''
		«FOR c : clauses»
		«clause2Method.get(c)»("«s.name»", «transitionIndex», result)()«IF clauses.last !== c»;«ENDIF»«ENDFOR»'''
	}

	def dispatch CharSequence generateActionInContext(AssignmentAction a, PortEventPair ev) {
		generateAction(a)
	}

	def dispatch CharSequence generateActionInContext(IfAction ifact, PortEventPair ev) '''
	if «generateExpression(ifact.guard)» then
		«FOR a : ifact.thenList.actions SEPARATOR ';'»
			«generateActionInContext(a, ev)»
		«ENDFOR»
	«IF ifact.elseList !== null »
		else
			«FOR a : ifact.elseList.actions SEPARATOR ';'»
				«generateActionInContext(a, ev)»
			«ENDFOR»
	«ENDIF»
	fi'''

	def dispatch CharSequence generateActionInContext(RecordFieldAssignmentAction a, PortEventPair ev) {
		generateAction(a)
	}

	def dispatch CharSequence generateActionInContext(CommandReply a, PortEventPair ev) {
		'''
		«messagePatternFromAction(a, ev)»
		context addToExpectedMessages(new(CMessageMultiplicityPattern) init setMessagePattern(mp))'''
	}

	// Assumption: EventCall is not outgoing call (this is not supported yet)
	def dispatch CharSequence generateActionInContext(EventCall a, PortEventPair ev) '''
	«messagePatternFromAction(a, ev)»
	context addToExpectedMessages(new(CMessageMultiplicityPattern) init setMessagePattern(mp) setLower(«a.normalizedMultiplicity.lower») setUpper(«a.normalizedMultiplicity.upper»))'''
	
	def dispatch CharSequence generateActionInContext(ParallelComposition pc, PortEventPair ev) '''
	pc := new(CParallelCompositionPattern) init;
	«FOR c : pc.flatten»
	«messagePatternFromAction(c, ev)»
	pc addElement(new(CMessageMultiplicityPattern) init setMessagePattern(mp) «IF c instanceof EventCall»setLower(«c.normalizedMultiplicity.lower») setUpper(«c.normalizedMultiplicity.upper»)«ENDIF»);
	«ENDFOR»
	context addToExpectedMessages(pc)'''
	
	def dispatch messagePatternFromAction(EventCall a, PortEventPair ev) '''
	«IF a.event instanceof Notification»mp := new(«COMMA_PREFIX»NotificationPattern)«ELSE»mp := new(«COMMA_PREFIX»SignalPattern)«ENDIF» init setName("«a.event.name»");
	«FOR p : a.parameters»
	mp addParameter(«generateExpression(p)»);
	«ENDFOR»'''
	
	def dispatch messagePatternFromAction(CommandReply a, PortEventPair ev){
		var String commandName = ""
		if (ev !== null && ev.event instanceof Command) {
			commandName = ev.event.name
		} else if (a.command !== null) {
			commandName = a.command.event.name
		} else {
			val parentTransition = EcoreUtil2::getContainerOfType(a, TriggeredTransition)
			if(parentTransition !== null) commandName = parentTransition.trigger.name
		}
		'''
		mp := new(«COMMA_PREFIX»ReplyPattern) init «IF commandName !== null»setName("«commandName»")«ENDIF»;
		«IF a.parameters.size() > 0»
		mp«FOR p : a.parameters» addParameter(«generateExpression(p)»)«ENDFOR»;
		«ENDIF»'''
	}
	
	def protected generateUtilityClass(AbstractBehavior intdef, List<StateMachine> machines) {
		quantifiersInMachines = getQuantifiersInStateMachines(intdef, machines);
		'''
			data class «utilityClassName(signature)» extends «COMMA_PREFIX»State
			variables
			
			/* global variables from the spec */
				«FOR v : intdef.vars»
					«VAR_NAME_PREFIX»«v.name» : «toPOOSLType(v.type)»
				«ENDFOR»
			
			/* variables for current state in machines */
				«FOR sm : machines»
					«sm.name» : String
				«ENDFOR»
			
			methods
			
			/* getters and setters for global variables */
				«FOR v : intdef.vars»
					get_«VAR_NAME_PREFIX»«v.name» : «toPOOSLType(v.type)»
						return «VAR_NAME_PREFIX»«v.name»
					
					set_«VAR_NAME_PREFIX»«v.name»(i : «toPOOSLType(v.type)») : «utilityClassName(signature)»
						«VAR_NAME_PREFIX»«v.name» := i;
						return self
					
				«ENDFOR»
			/* getters and setter for variables that hold current state */
				«FOR sm : machines»
					get_«sm.name» : String
						return «sm.name»
					
					set_«sm.name»(i : String) : «utilityClassName(signature)»
						if «sm.name» != i then
							activeStates remove(«sm.name») add(i)
						fi;
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
				init() : «utilityClassName(signature)»
					/* Initialization of the set with active states of the state machines */
					activeStates := new(Set) clear;
					activeStates«FOR s : machines.map[states].flatten.filter(s | s.initial)» add("«s.name»")«ENDFOR»;
					
					/* initialization of global variables with default values for safety reasons */
					«FOR v : intdef.vars» 
						«VAR_NAME_PREFIX»«v.name» := «generateDefaultValue(v.type)»;
					«ENDFOR»
			
					/* initialization of global variables in model init section */
					«FOR a : intdef.initActions» 
						«generateAction(a)»;
					«ENDFOR»
			
					/* initilization of current state variables */
					«FOR sm : machines»
						«sm.name» := "«sm.states.filter(s | s.initial).get(0).name»";
					«ENDFOR»
					
					/* initialization of the last execution state */
					executionState := "";
					
					/* initialization of coverage info */
					clauseMap := new(Map);
					stateMap := new(Map);
					
					«FOR m : machines»
						«FOR s : m.states»
							stateMap putAt("«s.name»", «IF s.initial»1«ELSE»0«ENDIF»);
							«val allTransitionInState = StateMachineUtilities::transitionsForState(s)»
							«FOR ti : 0..< allTransitionInState.size»
								«FOR ci : 0..< allTransitionInState.get(ti).clauses.size»
									clauseMap putAt("«s.name» transition «ti + 1»«getEventName(allTransitionInState.get(ti), allTransitionInState.get(ti).clauses.get(ci))» clause «ci + 1»", 0);
								«ENDFOR»
							«ENDFOR»
						«ENDFOR»
					«ENDFOR»
			
					return self
			
			/* print method */
				print : String
					|result : String|
					result := "";
					result := result + "Values of global variables and current machine states:" + "\n\n";
					«IF ! intdef.vars.isEmpty»
						«FOR v : intdef.vars» 
							result := result + "«v.name» = " + «VAR_NAME_PREFIX»«v.name» printString + "\n";
						«ENDFOR»
					«ELSE»
						result := result + "No global variables" + "\n";
					«ENDIF»
					«FOR m : machines» 
						result := result + "Machine «m.name» in state " + «m.name» + "\n";
					«ENDFOR»
					
					return result
		'''
	}

	

	override determineRecordTypePrefix(RecordTypeDecl t) {
		if (t.eContainer !== null && (t.eContainer instanceof Signature)) {
			return '''«(t.eContainer as Signature).name»_'''
		}

		return ""
	}

	abstract def Signature getSignature()

	// Interfaces and Components provide specific implementation
	// Interfaces use a single port (in)
	// Components use the set of provided and required ports
	abstract def CharSequence generatePorts(AbstractBehavior behavior)

	abstract def CharSequence decisionSuperClass()

	abstract def CharSequence eventMethodInStateName(State s, PortEventPair p, RootMethodKind kind)

	abstract def CharSequence eventRootMethodName(PortEventPair event, RootMethodKind kind)

	abstract def boolean validHandler(TriggeredTransition t, PortEventPair ev)

	abstract def boolean validAction(Action a, PortEventPair p)

	abstract def String getPortForAction(Action a)

	def int determineMaxParamNumber(Iterable<PortEventPair> events) {
		var int max = 0
		for (pair : events) {
			val size = pair.event.parameters.filter(p | p.direction != DIRECTION::OUT).size
			if(max < size) max = size
		}
		max
	}

	def boolean emptyTransitionsInState(PortEventPair ev, State s, RootMethodKind kind) {
		if(kind == RootMethodKind::INCOMING) getTriggeredTransitionsInState(ev, s).
			empty else getNonTriggeredTransitionsInState(ev, s).empty
	}

	def List<TriggeredTransition> getTriggeredTransitionsInState(PortEventPair ev, State s) {
		var result = new ArrayList<TriggeredTransition>()
		val allTriggeredTransitions = StateMachineUtilities::getTriggeredTransitions(s.eContainer as StateMachine, s)
		result.addAll(allTriggeredTransitions.filter(t|validHandler(t, ev)))
		result
	}

	//TODO clean the selection 
	def List<NonTriggeredTransition> getNonTriggeredTransitionsInState(PortEventPair ev, State s) {
		val transitions = StateMachineUtilities::getNonTriggeredTransitions(s.eContainer as StateMachine, s)
		var transitionsForEvent = new ArrayList<NonTriggeredTransition>()
		for (t : transitions) {
			var isReply = false
			val clazz = if(StateMachineUtilities::isIncomingCommand(ev)) {isReply = true CommandReply} else EventCall
			val actions = new LinkedList<Action>
			for(a : EcoreUtil2::getAllContentsOfType(t, clazz).filter(e|validAction(e as Action, ev))){
				actions.add(a as Action)
			}
			for(pc : EcoreUtil2::getAllContentsOfType(t, ParallelComposition)){
				for(a : pc.flatten){
					if((isReply && a instanceof CommandReply) || (!isReply && a instanceof EventCall)){
						if(validAction(a as Action, ev)) actions.add(a)
					}
				}
			}
			if (!actions.empty) {
				transitionsForEvent.add(t as NonTriggeredTransition)
			}
		}
		transitionsForEvent
	}

	def getClausesForOutgoingEvent(NonTriggeredTransition t, PortEventPair ev) {
		var result = new ArrayList<Clause>
		for (c : t.clauses) {
			var isReply = false
			val clazz = (if(StateMachineUtilities::isIncomingCommand(ev)) {isReply = true CommandReply} else EventCall)
			val actions = new LinkedList<Action>
			for(a : EcoreUtil2::getAllContentsOfType(t, clazz).filter(e|validAction(e as Action, ev))){
				actions.add(a as Action)
			}
			for(pc : EcoreUtil2::getAllContentsOfType(t, ParallelComposition)){
				for(a : pc.flatten){
					if((isReply && a instanceof CommandReply) || (!isReply && a instanceof EventCall)){
						if(validAction(a as Action, ev)) actions.add(a)
					}
				}
			}
			if (!actions.empty) {
				result.add(c)
			}
		}
		result
	}

	def CharSequence getEventName(Transition t, Clause c) {
		if (t instanceof TriggeredTransition) {
			''' «t.trigger.name»'''
		} else {
			val eventCalls = EcoreUtil2::getAllContentsOfType(c, EventCall) //TODO change this to take into account the fragments
			if (eventCalls.empty) '''''' else ''' «eventCalls.get(0).event.name»'''
		}
	}
	
	static def decisionClassFile(Signature s)
	'''«s.name»DecisionClass.poosl'''

	static def decisionClassName(Signature s)
	'''«s.name»DecisionClass'''
	
	static def utilityClassName(Signature s)
	'''«s.name»Utility'''
}
