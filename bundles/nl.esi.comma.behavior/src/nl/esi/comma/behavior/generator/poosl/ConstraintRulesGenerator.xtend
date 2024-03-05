package nl.esi.comma.behavior.generator.poosl

import java.util.ArrayList
import java.util.Collections
import java.util.List
import nl.esi.comma.actions.actions.AnyEvent
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EVENT_KIND
import nl.esi.comma.actions.actions.NotificationEvent
import nl.esi.comma.actions.actions.SignalEvent
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.BracketFormula
import nl.esi.comma.behavior.behavior.ConditionalFollow
import nl.esi.comma.behavior.behavior.ConditionedAbsenceOfEvent
import nl.esi.comma.behavior.behavior.ConditionedEvent
import nl.esi.comma.behavior.behavior.Conjunction
import nl.esi.comma.behavior.behavior.Connector
import nl.esi.comma.behavior.behavior.ConnectorOperator
import nl.esi.comma.behavior.behavior.ConstraintSequence
import nl.esi.comma.behavior.behavior.DataConstraint
import nl.esi.comma.behavior.behavior.DataConstraintUntilOperator
import nl.esi.comma.behavior.behavior.Disjunction
import nl.esi.comma.behavior.behavior.ESDisjunction
import nl.esi.comma.behavior.behavior.EventInterval
import nl.esi.comma.behavior.behavior.EventSelector
import nl.esi.comma.behavior.behavior.GenericConstraintsBlock
import nl.esi.comma.behavior.behavior.GroupTimeConstraint
import nl.esi.comma.behavior.behavior.Implication
import nl.esi.comma.behavior.behavior.NegationFormula
import nl.esi.comma.behavior.behavior.PeriodicEvent
import nl.esi.comma.behavior.behavior.Sequence
import nl.esi.comma.behavior.behavior.SingleTimeConstraint
import nl.esi.comma.behavior.behavior.TimeInterval
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionVariable
import org.eclipse.emf.common.util.TreeIterator
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.behavior.behavior.EventInState
import nl.esi.comma.behavior.behavior.DataConstraintEvent
import nl.esi.comma.types.types.NamedElement
import nl.esi.comma.behavior.behavior.TimeConstraint
import nl.esi.comma.behavior.behavior.GenericConstraint

abstract class ConstraintRulesGenerator extends PooslGenerator {
	
	public static final String OBSERVED_VAR_PREFIX = "observed_"
	
	protected final AbstractBehavior behavior	
	
	new (String fileName, AbstractBehavior behavior, IFileSystemAccess fsa) {
		super(fileName, fsa)
		this.behavior = behavior
	}
	
	def rulesClassName()
	'''«rulesClassPrefix»Rules'''
	
	abstract def CharSequence rulesClassPrefix()
	
	def ruleClassName(NamedElement rule){
		val ruleNameSuffix = 
			switch(rule){
				TimeConstraint : "TimeRule"
				DataConstraint : "DataRule"
				GenericConstraint : "Formula"
				default : "TimeRule"
			}
		'''«rulesClassPrefix»«rule.name»«ruleNameSuffix»'''
	}
	
	
	def protected generateConstraintRules(AbstractBehavior intdef) {
		'''
			data class «rulesClassName» extends Object
			variables
				rules : Sequence
			methods
				init : «rulesClassName» |r : «COMMA_PREFIX»Rule |
					rules := new(Sequence) clear;
					«IF intdef.timeConstraintsBlock !== null»
						«FOR r : intdef.timeConstraintsBlock.timeConstraints»
							«IF r instanceof SingleTimeConstraint»
								«IF !(r.constraint instanceof PeriodicEvent)»
									rules append(self getTimeRule_«r.name»);
								«ELSE»
									r := new(«ruleClassName(r)») init;
									rules append(r);
								«ENDIF»
							«ELSE»
								r := new(«ruleClassName(r)») init;
								rules append(r);
							«ENDIF»
						«ENDFOR»
					«ENDIF»
					«IF intdef.dataConstraintsBlock !== null»
						«FOR r : intdef.dataConstraintsBlock.dataConstraints»
							r := new(«ruleClassName(r)») init;
							rules append(r);
						«ENDFOR»
					«ENDIF»
					«IF intdef.genericConstraintsBlock !== null»
						«FOR r : intdef.genericConstraintsBlock.genericConstraints»
							r := new(«ruleClassName(r)») init;
							rules append(r);
						«ENDFOR»
					«ENDIF»
					return self
			
				«IF intdef.timeConstraintsBlock !== null»
					«FOR r : intdef.timeConstraintsBlock.timeConstraints»
						«IF r instanceof SingleTimeConstraint»
							«IF !(r.constraint instanceof PeriodicEvent)»
								«singleTimeConstraintToPoosl(r.constraint, r)»
							«ENDIF»
						«ENDIF»
					«ENDFOR»
				«ENDIF»
			
				getRules : Sequence
					return rules
			
				«generateTimeRules»
				«generateDataRules»
				«generateGenericRules»
		'''
	}
	
	/* Time Rules */
	
	def generateTimeRules() '''
		«IF behavior.timeConstraintsBlock !==null»
			
			«FOR r : behavior.timeConstraintsBlock.timeConstraints»
				«IF r instanceof SingleTimeConstraint»
					«IF r.constraint instanceof PeriodicEvent»
						«singleTimeConstraintToPoosl(r.constraint, r)»
					«ENDIF»
				«ELSE»
					«timeConstraintToPoosl(r)»
				«ENDIF»
			«ENDFOR»
		«ENDIF»
	'''

	def dispatch singleTimeConstraintToPoosl(EventInterval r, TimeConstraint rule) '''
		getTimeRule_«rule.name» : «COMMA_PREFIX»Rule
			|u : «COMMA_PREFIX»Until, e : «COMMA_PREFIX»MessagePattern, res : «COMMA_PREFIX»Rule|
			
			res := new(«COMMA_PREFIX»EventIntervalTimeRule) init;
			res setName("«rule.name»");
			res getEnvironment setInterval(«interval(r.interval)»);
			e := «generateEvent(r.condition.event)»;
			res getFormula getSequence getElements at(1) setEvent(e);
			u := res getFormula getSequence getElements at(2);
			e := «generateEvent(r.condition.event)»;
			u getBody setEvent(e);
			e := «generateEvent(r.event.event)»;
			u getStop setEvent(e);
			
			return res
		
	'''

	def dispatch singleTimeConstraintToPoosl(ConditionedAbsenceOfEvent r, TimeConstraint rule) '''
		getTimeRule_«rule.name» : «COMMA_PREFIX»Rule
			|u : «COMMA_PREFIX»Until, e : «COMMA_PREFIX»MessagePattern, res : «COMMA_PREFIX»Rule|
					
				res := new(«COMMA_PREFIX»ConditionedAbsenceOfEventTimeRule) init;
				res setName("«rule.name»");
				res getEnvironment setInterval(«interval(r.interval)») setIntervalEnd(«IF r.interval.end !== null»«generateExpression(r.interval.end)»«ELSE»-1«ENDIF»);
				e := «generateEvent(r.condition.event)»;
				res getFormula getFormula getElements at(1) setEvent(e);
				u := res getFormula getFormula getElements at(2);
				e := new(«COMMA_PREFIX»MessagePattern) init;
				u getBody setEvent(e);
				e := «generateEvent(r.event.event)»;
				u getStop setEvent(e);
				
				return res				
				
	'''

	def dispatch singleTimeConstraintToPoosl(ConditionedEvent r, TimeConstraint rule) '''
		getTimeRule_«rule.name» : «COMMA_PREFIX»ConditionedEventTimeRule
			|u : «COMMA_PREFIX»Until, e : «COMMA_PREFIX»MessagePattern, res : «COMMA_PREFIX»Rule|
				
				res := new(«COMMA_PREFIX»ConditionedEventTimeRule) init setName("«rule.name»");
				res getEnvironment setInterval(«interval(r.interval)») setIntervalEnd(«IF r.interval.end !== null»«generateExpression(r.interval.end)»«ELSE»-1«ENDIF»);
				e := «generateEvent(r.condition.event)»;
				res getFormula getLeft getElements at(1) setEvent(e);
				u := res getFormula getRight getElements at(1);
				e := «generateEvent(r.event.event)»;
				u getBody setEvent(e);
				e := «generateEvent(r.event.event)»;
				u getStop setEvent(e);
				
				return res
				
	'''

	def dispatch singleTimeConstraintToPoosl(PeriodicEvent r, TimeConstraint rule) '''
		data class «ruleClassName(rule)» extends «COMMA_PREFIX»PeriodicTimeRule
		variables
		methods
			init : «ruleClassName(rule)»
				|e : «COMMA_PREFIX»MessagePattern, u : «COMMA_PREFIX»Until|
						
				self ^init;
				name := "«rule.name»";
				env setVariableValue("period", «generateExpression(r.period)»);
				env setVariableValue("jitter", «generateExpression(r.jitter)»);
				e := «generateEvent(r.condition.event)»;
				formula getLeft getElements at(1) setEvent(e);
				u := formula getRight getElements at(1);
				//first disjunct
				e := «generateEvent(r.event)»;
				u getBody getSelectors at(1) setEvent(e);
				//second disjunct
				e := «generateEvent(r.event)»;
				u getBody getSelectors at(2) setEvent(e);
				//Stop condition
				«IF r.stopEvent !== null»
					e := «generateEvent(r.stopEvent.event)»;
					u getStop setEvent(e);
				«ELSE»
					e := new(«COMMA_PREFIX»MessagePattern) init;
					u getStop setEvent(e) setNegated();
				«ENDIF»
				return self
				
	'''

	def dispatch groupTimeConstraintToPoosl(ConditionedAbsenceOfEvent first, GroupTimeConstraint tc) '''
		data class «rulesClassPrefix»«tc.name»TimeRuleEnvironment extends «COMMA_PREFIX»Environment
			variables
				t1, t2, t3, t, «FOR i : 0..< (tc.followups.length) SEPARATOR ', '»t«4 + i»«ENDFOR» : Float
				i1, «FOR i : 0..< (tc.followups.length) SEPARATOR ', '»i«2 + i»«ENDFOR» : «COMMA_PREFIX»Interval
							
			methods
				init : «COMMA_PREFIX»Environment
					i1 := «interval(first.interval)»;
					«FOR i : 0..< (tc.followups.length)»
						i«2 + i» := «interval(tc.followups.get(i).interval)»;
					«ENDFOR»
					return self
								
				setVariableValue(name : String, value : Object) : «COMMA_PREFIX»Environment
					if name = "t1" then t1 := value fi;
					if name = "t2" then t2 := value fi;
					if name = "t3" then t3 := value fi;
					if name = "t" then t := value fi;
					«FOR i : 0..< (tc.followups.length)»
						if name = "t«4 + i»" then t«4 + i» := value fi;
					«ENDFOR»
					return self
								
				checkCondition(index : Integer, message : CObservedMessage) : Boolean
					| result : Boolean |
					result := true;
					if index = 1 then result := «IF first.interval.end === null»true«ELSE»(t2 - t1) <= («generateExpression(first.interval.end)»)«ENDIF» fi;
					if index = 2 then result := i1 isIn (t3 - t1) fi;
					if index = 3 then result := «IF tc.followups.get(0).interval.end === null»true«ELSE»(t - t1  - «generateExpression(first.interval.end)») <= («generateExpression(tc.followups.get(0).interval.end)»)«ENDIF» fi;
					if index = 4 then result := i2 isIn (t4 - t1 - «generateExpression(first.interval.end)») fi;
					«FOR i : 1..< (tc.followups.length)»
						if index = «4 + (2*i -1)» then result := «IF tc.followups.get(i).interval.end === null»true«ELSE»(t - t«4 + (i-1)») <= («generateExpression(tc.followups.get(i).interval.end)»)«ENDIF» fi;
						if index = «4 + 2*i» then result := i«2 + i» isIn (t«4 + i» - t«4 + (i-1)») fi;
					«ENDFOR»			
					return result
				
			data class «ruleClassName(tc)» extends «COMMA_PREFIX»TimeRule
			variables
			methods
				init : «ruleClassName(tc)»
					|env : «rulesClassPrefix»«tc.name»TimeRuleEnvironment|
					self ^init;
					name := "«tc.name»";
					errorMessage := "Event is not received in the expected interval.";
					env := new(«rulesClassPrefix»«tc.name»TimeRuleEnvironment) init;
					
					formula := new(«COMMA_PREFIX»Implication) init 
					           setLeft(new(«COMMA_PREFIX»Negation) init
					                   setFormula(new(«COMMA_PREFIX»ConditionalFollow) init 
					                              setLeft(new(«COMMA_PREFIX»Sequence) init 
					                                      addElement(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t1")
					                                                 setEvent(«generateEvent(first.condition.event)»)
					                                                 setEnvironment(env))
					                                      setEnvironment(env))
					                              setRight(new(«COMMA_PREFIX»Sequence) init
					                                       addElement(new(«COMMA_PREFIX»Until) init
					                                                  setBody(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t2")
					                                                          setEvent(«generateEvent(first.event.event)») 
					                                                          setEnvironment(env) setNegated setConditionIndex(1))
					                                                  setStop(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t3") 
					                                                          setEvent(«generateEvent(first.event.event)»)
					                                                          setEnvironment(env) setConditionIndex(2))
					                                                  setEnvironment(env))
					                                       setEnvironment(env))))
					           setRight(new(«COMMA_PREFIX»ConditionalFollow) init 
					                    setLeft(new(«COMMA_PREFIX»Sequence) init 
					                            addElement(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t1")
					                                       setEvent(«generateEvent(first.condition.event)»)
					                                       setEnvironment(env)) 
					                            setEnvironment(env))
					                    setRight(new(«COMMA_PREFIX»Sequence) init 
					                             addElement(new(«COMMA_PREFIX»Until) init 
					                                        setBody(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t")
					                                                setEvent(«generateEvent(tc.followups.get(0).event.event)») 
					                                                setEnvironment(env) setNegated setConditionIndex(3))
					                                        setStop(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t4")
					                                                setEvent(«generateEvent(tc.followups.get(0).event.event)»)
					                                                setEnvironment(env) setConditionIndex(4))
					                                        setEnvironment(env))
					                             //More followups if any
					                             «FOR i : 1..< (tc.followups.length)»
					                             addElement(new(«COMMA_PREFIX»Until) init 
					                                        setBody(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") 
					                                                setEvent(«generateEvent(tc.followups.get(i).event.event)»)
					                                                setEnvironment(env) setNegated setConditionIndex(«4 + (2*i-1)»))
					                                        setStop(new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t«4 + i»")
					                                                setEvent(«generateEvent(tc.followups.get(i).event.event)»)
					                                                setEnvironment(env) setConditionIndex(«4 + 2*i»))
					                                        setEnvironment(env)
					                             «ENDFOR»
					                             setEnvironment(env)));
					return self
	'''
	def dispatch groupTimeConstraintToPoosl(EventInterval first, GroupTimeConstraint tc) '''
		data class «rulesClassPrefix»«tc.name»TimeRuleEnvironment extends «COMMA_PREFIX»Environment
			variables
				t, t1, t2, «FOR i : 0..< (tc.followups.length) SEPARATOR ', '»t«3 + i»«ENDFOR» : Float
				i1, «FOR i : 0..< (tc.followups.length) SEPARATOR ', '»i«2 + i»«ENDFOR» : «COMMA_PREFIX»Interval
								
			methods
				init : «COMMA_PREFIX»Environment
					i1 := «interval(first.interval)»;
					«FOR i : 0..< (tc.followups.length)»
						i«2 + i» := «interval(tc.followups.get(i).interval)»;
					«ENDFOR»
					return self
									
				setVariableValue(name : String, value : Object) : «COMMA_PREFIX»Environment
					if name = "t" then t := value fi;
					if name = "t1" then t1 := value fi;
					if name = "t2" then t2 := value fi;
					«FOR i : 0..< (tc.followups.length)»
						if name = "t«3 + i»" then t«3 + i» := value fi;
					«ENDFOR»
					return self
									
				checkCondition(index : Integer, message : CObservedMessage) : Boolean
					|result : Boolean|
					result := true;
					if index = 2 then result := i1 isIn (t2 - t1) fi;
					«FOR i : 0..< (tc.followups.length)»
						if index = «4 + (2*i -1)» then result := «IF tc.followups.get(i).interval.end === null»true«ELSE»(t - t«3 + (i-1)») <= («generateExpression(tc.followups.get(i).interval.end)»)«ENDIF» fi;
						if index = «4 + 2*i» then result := i«2 + i» isIn (t«3 + i» - t«3 + (i-1)») fi;
					«ENDFOR»			
					return result
				
			data class «ruleClassName(tc)» extends «COMMA_PREFIX»TimeRule
			variables
			methods
				init : «ruleClassName(tc)»
					|env : «rulesClassPrefix»«tc.name»TimeRuleEnvironment,
					s : «COMMA_PREFIX»Sequence, u : «COMMA_PREFIX»Until,
					e : «COMMA_PREFIX»MessagePattern, es : «COMMA_PREFIX»EventSelector|
								
					self ^init;
					name := "«tc.name»";
					errorMessage := "Event is not received in the expected interval.";
								
					env := new(«rulesClassPrefix»«tc.name»TimeRuleEnvironment) init;
					e := «generateEvent(first.condition.event)»;
					es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t1") setEvent(e) setEnvironment(env);
					s := new(«COMMA_PREFIX»Sequence) init addElement(es) setEnvironment(env);
					e := «generateEvent(first.event.event)»;
					es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEvent(e) setEnvironment(env) setNegated;
					u := new(«COMMA_PREFIX»Until) init setBody(es) setEnvironment(env);
					e := «generateEvent(first.event.event)»;
					es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t2") setEvent(e) setEnvironment(env) setConditionIndex(2);
					u setStop(es);
					s addElement(u);
					formula := new(«COMMA_PREFIX»ConditionalFollow) init setLeft(s);
					s := new(«COMMA_PREFIX»Sequence) init setEnvironment(env);
					//Followups
					«FOR i : 0..< (tc.followups.length)»
						e := «generateEvent(tc.followups.get(i).event.event)»;
						es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEvent(e) setEnvironment(env) setNegated setConditionIndex(«3 + (2*i)»);
						u := new(«COMMA_PREFIX»Until) init setBody(es) setEnvironment(env);
						e := «generateEvent(tc.followups.get(i).event.event)»;
						es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t«3 + i»") setEvent(e) setEnvironment(env) setConditionIndex(«4 + 2*i»);
						u setStop(es);
						s addElement(u);
					«ENDFOR»
					formula setRight(s);
					return self
						
	'''


	def interval(
		TimeInterval i) '''new(«COMMA_PREFIX»Interval) init «IF i.begin !== null»setBegin(«generateExpression(i.begin)») «ENDIF» «IF i.end !== null»setEnd(«generateExpression(i.end)») «ENDIF»'''

	def dispatch timeConstraintToPoosl(SingleTimeConstraint tc) {
		singleTimeConstraintToPoosl(tc.constraint, tc)
	}

	def dispatch timeConstraintToPoosl(GroupTimeConstraint tc) '''
		«groupTimeConstraintToPoosl(tc.first, tc)»
	'''


	def dispatch groupTimeConstraintToPoosl(ConditionedEvent first, GroupTimeConstraint tc) '''
		data class «rulesClassPrefix»«tc.name»TimeRuleEnvironment extends «COMMA_PREFIX»Environment
			variables
				t, t1, t2, «FOR i : 0..< (tc.followups.length) SEPARATOR ', '»t«3 + i»«ENDFOR» : Float
				i1, «FOR i : 0..< (tc.followups.length) SEPARATOR ', '»i«2 + i»«ENDFOR» : «COMMA_PREFIX»Interval
								
			methods
				init : «COMMA_PREFIX»Environment
					i1 := «interval(first.interval)»;
					«FOR i : 0..< (tc.followups.length)»
						i«2 + i» := «interval(tc.followups.get(i).interval)»;
					«ENDFOR»
					return self
									
				setVariableValue(name : String, value : Object) : «COMMA_PREFIX»Environment
					if name = "t" then t := value fi;
					if name = "t1" then t1 := value fi;
					if name = "t2" then t2 := value fi;
					«FOR i : 0..< (tc.followups.length)»
						if name = "t«3 + i»" then t«3 + i» := value fi;
					«ENDFOR»
					return self
									
				checkCondition(index : Integer, message : CObservedMessage) : Boolean
					| result : Boolean |
					result := true;
					if index = 1 then result := «IF first.interval.end === null»true«ELSE»(t - t1) <= («generateExpression(first.interval.end)»)«ENDIF» fi;
					if index = 2 then result := i1 isIn (t2 - t1) fi;
					«FOR i : 0..< (tc.followups.length)»
						if index = «4 + (2*i -1)» then result := «IF tc.followups.get(i).interval.end === null»true«ELSE»(t - t«3 + (i-1)») <= («generateExpression(tc.followups.get(i).interval.end)»)«ENDIF» fi;
						if index = «4 + 2*i» then result := i«2 + i» isIn (t«3 + i» - t«3 + (i-1)») fi;
					«ENDFOR»			
					return result
				
			data class «ruleClassName(tc)» extends «COMMA_PREFIX»TimeRule
			variables
			methods
				init : «ruleClassName(tc)»
					|env : «rulesClassPrefix»«tc.name»TimeRuleEnvironment,
					s : «COMMA_PREFIX»Sequence, u : «COMMA_PREFIX»Until,
					e : «COMMA_PREFIX»MessagePattern, es : «COMMA_PREFIX»EventSelector, post : «COMMA_PREFIX»Formula|
								
					self ^init;
					name := "«tc.name»";
					errorMessage := "Event is not received in the expected interval.";
								
					env := new(«rulesClassPrefix»«tc.name»TimeRuleEnvironment) init;
					e := «generateEvent(first.condition.event)»;
					es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t1") setEvent(e) setEnvironment(env);
					s := new(«COMMA_PREFIX»Sequence) init addElement(es) setEnvironment(env);
					formula := new(«COMMA_PREFIX»ConditionalFollow) init setLeft(s);
					//Consequence
					e := «generateEvent(first.event.event)»;
					es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEvent(e) setEnvironment(env) setNegated setConditionIndex(1);
					u := new(«COMMA_PREFIX»Until) init setBody(es) setEnvironment(env);
					e := «generateEvent(first.event.event)»;
					es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t2") setEvent(e) setEnvironment(env) setConditionIndex(2);
					u setStop(es);
					s := new(«COMMA_PREFIX»Sequence) init addElement(u) setEnvironment(env);
					//Followups
					«FOR i : 0..< (tc.followups.length)»
						e := «generateEvent(tc.followups.get(i).event.event)»;
						es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEvent(e) setEnvironment(env) setNegated setConditionIndex(«3 + (2*i)»);
						u := new(«COMMA_PREFIX»Until) init setBody(es) setEnvironment(env);
						e := «generateEvent(tc.followups.get(i).event.event)»;
						es := new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t«3 + i»") setEvent(e) setEnvironment(env) setConditionIndex(«4 + 2*i»);
						u setStop(es);
						s addElement(u);
					«ENDFOR»
					formula setRight(s);
					return self
						
	'''

	/* Data Rules */
	
	def generateDataRules() {
		if(behavior.dataConstraintsBlock !== null){
			quantifiersInMachines = getQuantifiersInContainer(behavior.dataConstraintsBlock);
		}
		
	'''
	«IF behavior.dataConstraintsBlock !== null»
	
	data class «rulesClassPrefix»DataRulesEnvironment extends «COMMA_PREFIX»Environment
	variables
		t : Float
		«FOR v : behavior.dataConstraintsBlock.vars»
		«VAR_NAME_PREFIX»«v.name» : «toPOOSLType(v.type)»
		«ENDFOR»
	
	methods
		init : «COMMA_PREFIX»Environment
			return self
						
		setVariableValue(name : String, value : Object) : «COMMA_PREFIX»Environment
			if name = "t" then t := value fi;
			«FOR v : behavior.dataConstraintsBlock.vars»
			if name = "«v.name»" then «VAR_NAME_PREFIX»«v.name» := value fi;
			«ENDFOR»
			return self
			
		«IF quantifiersInMachines.size > 0»
		«FOR quantifier : quantifiersInMachines»
		«generateQuantifierMethod(quantifier, quantifiersInMachines.indexOf(quantifier))»
		«ENDFOR»
		«ENDIF»
						
		checkCondition(index : Integer, message : CObservedMessage) : Boolean
			|result : Boolean|
			result := true;
			«FOR i : 0..< behavior.dataConstraintsBlock.dataConstraints.size»
			if index = «i + 1» then
				result := «generateExpression(behavior.dataConstraintsBlock.dataConstraints.get(i).condition)»
			fi;
			«ENDFOR»
			return result
		
		«FOR rule : behavior.dataConstraintsBlock.dataConstraints»
		«IF ! rule.observedValues.empty»
		observedValuesFor«rule.name» : Map
			|map : Map|
			map := new(Map);
			«FOR observedValue : rule.observedValues»
			map putAt("«rule.name»_«observedValue.name»", «generateExpression(observedValue.value)»);
			«ENDFOR»
			return map

		«ENDIF»
		«ENDFOR»
	«FOR dr : behavior.dataConstraintsBlock.dataConstraints»
	data class «ruleClassName(dr)» extends «COMMA_PREFIX»DataRule
	variables
		env : «rulesClassPrefix»DataRulesEnvironment
	methods
		init : «ruleClassName(dr)»
			self ^init;
			name := "«dr.name»";
			errorMessage := "Data constraint is violated."; 
			env := new(«rulesClassPrefix»DataRulesEnvironment) init;
			
			formula := 
				new(«COMMA_PREFIX»ConstraintSequence) init 
				setConditionIndex(«behavior.dataConstraintsBlock.dataConstraints.indexOf(dr) + 1»)
				setSequence(
					new(«COMMA_PREFIX»Sequence) init setEnvironment(env)
					«dataConstraintToPoosl(dr)»);
					
			return self
	
		observedValues : Map
			«IF ! dr.observedValues.empty»
			return env observedValuesFor«dr.name»
			«ELSE»
			return nil
			«ENDIF»

	«ENDFOR»
	«ENDIF»
	'''
	}
	
	def dataConstraintToPoosl(DataConstraint dc)
	'''
	«FOR step : dc.steps»
	«dataSequenceStepToPoosl(step)»
	«ENDFOR»
	'''
	
	def dispatch dataSequenceStepToPoosl(DataConstraintEvent s)
	'''
	addElement(
		new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEnvironment(env)«IF s.negated !== null» setNegated«ENDIF»
		setEvent(«generateEvent(s.event.event)»))
	'''
	
	def dispatch dataSequenceStepToPoosl(DataConstraintUntilOperator s)
	'''
	addElement(
		new(«COMMA_PREFIX»Until) init setEnvironment(env)
		setBody(
			new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEnvironment(env)«IF s.body.negated !== null» setNegated«ENDIF»
			setEvent(«generateEvent(s.body.event.event)»))
		setStop(
			new(«COMMA_PREFIX»EventSelector) init setTimeVariable("t") setEnvironment(env)«IF s.stop.negated !== null» setNegated«ENDIF»
			setEvent(«generateEvent(s.stop.event.event)»)))
	'''
	
	/* Generic rule generator */
	
	def generateGenericRules() {
		var List<Expression> conditions
		if (behavior.genericConstraintsBlock !== null) {
			conditions = collectConditions(behavior.genericConstraintsBlock)
			quantifiersInMachines = getQuantifiersInContainer(behavior.genericConstraintsBlock);
		} else {
			conditions = Collections.emptyList;
		}
		'''
			«IF behavior.genericConstraintsBlock !== null»
				
				data class «rulesClassPrefix»GenericRulesEnvironment extends «COMMA_PREFIX»Environment
				variables
					«FOR v : behavior.genericConstraintsBlock.vars»
						«VAR_NAME_PREFIX»«v.name» : «toPOOSLType(v.type)»
					«ENDFOR»
				
				methods
					init : «COMMA_PREFIX»Environment
						return self
									
					setVariableValue(name : String, value : Object) : «COMMA_PREFIX»Environment
						«FOR v : behavior.genericConstraintsBlock.vars»
							if name = "«v.name»" then «VAR_NAME_PREFIX»«v.name» := value fi;
						«ENDFOR»
						return self
						
					«IF quantifiersInMachines.size > 0»
						«FOR quantifier : quantifiersInMachines»
							«generateQuantifierMethod(quantifier, quantifiersInMachines.indexOf(quantifier))»
						«ENDFOR»
					«ENDIF»
					
					checkCondition(index : Integer, message : CObservedMessage) : Boolean
						|result : Boolean|
						result := true;
						
						«FOR condition : conditions»
							if index = «conditions.indexOf(condition) + 1» then
								result := «generateExpression(condition)»
							fi;
						«ENDFOR»
						return result
				
				«FOR f : behavior.genericConstraintsBlock.genericConstraints»
					data class «ruleClassName(f)» extends «COMMA_PREFIX»GenericRule
					variables
					methods
						init : «ruleClassName(f)»
							|env : «rulesClassPrefix»GenericRulesEnvironment|
							self ^init;
							name := "«f.name»";
							errorMessage := "Generic constraint is violated.";
							env := new(«rulesClassPrefix»GenericRulesEnvironment) init;
							formula :=
							«formulaToPoosl(f.formula, conditions)»;
							
							return self
					
				«ENDFOR»
			«ENDIF»
		'''
	}
	
	/** stepToPoosl(Step, List<Expression>) */

	def dispatch CharSequence stepToPoosl(EventSelector s, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»EventSelector) init setTimeVariable("«s.timestamp.variable.name»") setEnvironment(env«IF s.counter !== null» setVariableValue("«s.counter.variable.name»", 0)«ENDIF»)
	setEvent(«generateEvent(s.event.event)») «IF s.counter !== null»setOccurenceVariable("«s.counter.variable.name»") «ENDIF»«IF s.negated !== null»setNegated «ENDIF»«IF s.condition !== null»setConditionIndex(«conditions.indexOf(s.condition) + 1»)«ENDIF»'''

	def dispatch CharSequence stepToPoosl(Connector c, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»Until) init setEnvironment(env)«IF c.conOperator == ConnectorOperator::WU» setWeak«ENDIF»
		setStop(
			«stepToPoosl(c.right, conditions)»)
		setBody(
			«stepToPoosl(c.left, conditions)»)'''

	def dispatch CharSequence stepToPoosl(ESDisjunction s, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»ORStep) init 
		addSelector(
			«stepToPoosl(s.left, conditions)»)
		addSelector(
			«stepToPoosl(s.right, conditions)»)'''
	
	/** formulaToPoosl(Formula, List<Expression>) */
	
	def dispatch CharSequence formulaToPoosl(NegationFormula f, List<Expression> conditions)
	'''
	new(«COMMA_PREFIX»Negation) init setFormula(
		«formulaToPoosl(f.sub, conditions)»)'''
	
	def dispatch CharSequence formulaToPoosl(BracketFormula f, List<Expression> conditions) 
	'''
	«formulaToPoosl(f.sub, conditions)»'''

	def dispatch CharSequence formulaToPoosl(Sequence f, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»Sequence) init setEnvironment(env)«IF f.condition !== null» setConditionIndex(«conditions.indexOf(f.condition) + 1»)«ENDIF»
	«FOR step : f.steps»
		addElement(
			«stepToPoosl(step, conditions)»)
	«ENDFOR»
	'''

	def dispatch CharSequence formulaToPoosl(Conjunction f, List<Expression> conditions)
	'''
	new(«COMMA_PREFIX»Conjunction) init 
		setLeft(
			«formulaToPoosl(f.left, conditions)»)
		setRight(
			«formulaToPoosl(f.right, conditions)»)'''

	def dispatch CharSequence formulaToPoosl(Disjunction f, List<Expression> conditions)
	'''
	new(«COMMA_PREFIX»Disjunction) init 
		setLeft(
			«formulaToPoosl(f.left, conditions)»)
		setRight(
			«formulaToPoosl(f.right, conditions)»)'''

	def dispatch CharSequence formulaToPoosl(Implication f, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»Implication) init 
		setLeft(
			«formulaToPoosl(f.left, conditions)»)
		setRight(
			«formulaToPoosl(f.right, conditions)»)'''

	def dispatch CharSequence formulaToPoosl(ConditionalFollow f, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»ConditionalFollow) init 
		setLeft(
			«formulaToPoosl(f.left, conditions)»)
		setRight(
			«formulaToPoosl(f.right, conditions)»)'''

	def dispatch CharSequence formulaToPoosl(ConstraintSequence f, List<Expression> conditions) 
	'''
	new(«COMMA_PREFIX»ConstraintSequence) init setConditionIndex(«conditions.indexOf(f.cond) + 1»)
		setSequence(
			«formulaToPoosl(f.left, conditions)»)'''

	def List<Expression> collectConditions(GenericConstraintsBlock block) {
		var result = new ArrayList<Expression>();
		var TreeIterator<EObject> iter;
		var EObject o;

		iter = block.eAllContents();
		while (iter.hasNext()) {
			o = iter.next();
			if (o instanceof ConstraintSequence) {
				result.add(o.cond);
			}
			if (o instanceof Sequence) {
				if (o.condition !== null) {
					result.add(o.condition);
				}
			}
			if (o instanceof EventSelector) {
				if (o.condition !== null) {
					result.add(o.condition);
				}
			}

		}
		return result
	}
	
	/** generateEvent(CommunicationEvent) */
		
	def dispatch CharSequence generateEvent(AnyEvent e){		
		'''«IF e.kind == EVENT_KIND::EVENT»new(«COMMA_PREFIX»MessagePattern) init«ENDIF»«IF e.kind == EVENT_KIND::CALL»new(«COMMA_PREFIX»CommandPattern) init setName("*")«ENDIF»«IF e.kind == EVENT_KIND::SIGNAL»new(«COMMA_PREFIX»SignalPattern) init setName("*")«ENDIF»«IF e.kind == EVENT_KIND::NOTIFICATION»new(«COMMA_PREFIX»NotificationPattern) init setName("*")«ENDIF»'''
	}
	
	def dispatch CharSequence generateEvent(CommandEvent e){
		var EventInState parent = null
		if(e.eContainer instanceof EventInState) parent = e.eContainer as EventInState
		'''new(«COMMA_PREFIX»CommandPattern) init setName("«e.event.name»") «FOR p : e.parameters»addParameter(«IF p instanceof ExpressionVariable»new(«COMMA_PREFIX»Variable) setName("«p.variable.name»") setType("«toPOOSLType(p.variable.type)»")«ELSE»«generateExpression(p)»«ENDIF») «ENDFOR» «IF parent !== null»«FOR s : parent.state»addState("«s.name»") «ENDFOR»«ENDIF»'''
	}	

	def dispatch CharSequence generateEvent(CommandReply e){
		var EventInState parent = null
		if(e.eContainer instanceof EventInState) parent = e.eContainer as EventInState
		'''new(«COMMA_PREFIX»ReplyPattern) init «FOR p : e.parameters»addParameter(«IF p instanceof ExpressionVariable»new(«COMMA_PREFIX»Variable) setName("«p.variable.name»") setType("«toPOOSLType(p.variable.type)»")«ELSE»«generateExpression(p)»«ENDIF») «ENDFOR» «IF parent !== null»«FOR s : parent.state»addState("«s.name»") «ENDFOR»«ENDIF» «IF e.command !== null»setCommand(«generateEvent(e.command)»)«ENDIF»'''
	}
	
	def dispatch CharSequence generateEvent(NotificationEvent e){
		var EventInState parent = null
		if(e.eContainer instanceof EventInState) parent = e.eContainer as EventInState
		'''new(«COMMA_PREFIX»NotificationPattern) init setName("«e.event.name»") «FOR p : e.parameters»addParameter(«IF p instanceof ExpressionVariable»new(«COMMA_PREFIX»Variable) setName("«p.variable.name»") setType("«toPOOSLType(p.variable.type)»")«ELSE»«generateExpression(p)»«ENDIF») «ENDFOR» «IF parent !== null»«FOR s : parent.state»addState("«s.name»") «ENDFOR»«ENDIF»'''
	}
	
	
	def dispatch CharSequence generateEvent(SignalEvent e){
		var EventInState parent = null
		if(e.eContainer instanceof EventInState) parent = e.eContainer as EventInState
		'''new(«COMMA_PREFIX»SignalPattern) init setName("«e.event.name»") «FOR p : e.parameters»addParameter(«IF p instanceof ExpressionVariable»new(«COMMA_PREFIX»Variable) setName("«p.variable.name»") setType("«toPOOSLType(p.variable.type)»")«ELSE»«generateExpression(p)»«ENDIF») «ENDFOR» «IF parent !== null»«FOR s : parent.state»addState("«s.name»") «ENDFOR»«ENDIF»'''
	}
}