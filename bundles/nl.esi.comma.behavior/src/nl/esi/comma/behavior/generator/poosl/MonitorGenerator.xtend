package nl.esi.comma.behavior.generator.poosl

import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.DIRECTION
import nl.esi.comma.signature.interfaceSignature.Signal
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.generator.poosl.TypesPooslGenerator
import nl.esi.comma.types.types.RecordTypeDecl
import org.eclipse.xtext.generator.IFileSystemAccess

//fix the naming of Rules class
//We need to inherit from SignaturePoosl (does not exist yet!) to avoid record type prefix duplication!
class MonitorGenerator extends TypesPooslGenerator {
	
	public static final String EXT = ".poosl"		
	static final String STATISTICS_FILE_PREFIX = "statistics"
	static final String STATISTICS_EXT = ".statistics"
	static final String TIME_STATISTICS_FILE_PREFIX = "Time"
	static final String DATA_STATISTICS_FILE_PREFIX = "Data"
	
	new(String fileName, IFileSystemAccess fsa) {
		super(fileName, fsa)				
	}	
	
	static def String getTimeStaticsFileName(String server) {
		'''«STATISTICS_FILE_PREFIX»«TIME_STATISTICS_FILE_PREFIX»«server»«STATISTICS_EXT»'''
	}
	
	static def String getDataStaticsFileName(String server) {
		'''«STATISTICS_FILE_PREFIX»«DATA_STATISTICS_FILE_PREFIX»«server»«STATISTICS_EXT»'''
	}
	
	def generateMonitor(CharSequence ports, Iterable<PortEventPair> incoming, Iterable<PortEventPair> outgoing) '''
	process class «monitorProcessClass(incoming.get(0).event.eContainer as Signature)» extends «COMMA_PREFIX»AbstractMonitor
		ports
			«ports»
		messages
		«generateMessages(incoming, outgoing)»
			
		variables
		init
			init()()
		methods
		
		initRules()()
			|observerTR, observerDR : «COMMA_PREFIX»RuleObserver, i : Integer|
			
			listOfConstraintRules := new(«(incoming.get(0).event.eContainer as Signature).name»Rules) init getRules;
			observerTR := new(«COMMA_PREFIX»TimeRuleObserver) init(monitoringContext taskPath + "/statistics/«getTimeStaticsFileName('''" + (monitoringContext reportFilePrefix) + "''')»", "time");
			observerDR := new(«COMMA_PREFIX»DataRuleObserver) init(monitoringContext taskPath + "/statistics/«getDataStaticsFileName('''" + (monitoringContext reportFilePrefix) + "''')»", "data");
			i := 1;
			while i <= (listOfConstraintRules size) do
				listOfConstraintRules at(i) registerObserver(observerTR) registerObserver(observerDR);
				i := i + 1
			od
	
		«generateMessageSenders(incoming, outgoing)»
	'''	
	
	def generateMessages(Iterable<PortEventPair> incoming, Iterable<PortEventPair> outgoing) '''
	/* output messages for incoming events */
		«FOR e : incoming»
		«val parameters = e.event.parameters.filter(p | p.direction != DIRECTION::OUT)»
		«e.port.name» ! «e.event.name»«IF parameters.size() > 0»(«FOR pt : parameters SEPARATOR ', '»«toPOOSLType(pt.type)»«ENDFOR»)«ENDIF»
		«ENDFOR»
		
	/* output messages for outgoing events */
		«FOR e : outgoing»
		«e.port.name» ! «e.event.name»
		«ENDFOR»
		
	/* output messages for replies to commands */
		«FOR e : incoming»
		«IF e.event instanceof Command»
		«e.port.name» ! «e.event.name»_r
		«ENDIF»
		«ENDFOR»	
	'''
	
	def generateMessageSenders(Iterable<PortEventPair> incoming, Iterable<PortEventPair> outgoing) 
	'''
	«val commands = incoming.filter(e | e.event instanceof Command)»
	«val signals = incoming.filter(e | e.event instanceof Signal)»
	sendEvent(m : «COMMA_PREFIX»ObservedMessage)()
		sel
		«IF !commands.empty»
			[m isOfType("«COMMA_PREFIX»ObservedCommand")]
			sel
			«FOR c : commands SEPARATOR '
or'»
				[m getName = "«c.event.name»"]
				«val parameters = c.event.parameters.filter(p | p.direction != DIRECTION::OUT)»
				«c.port.name» ! «c.event.name»«IF parameters.size() > 0»(«FOR ii : 0..< parameters.size() SEPARATOR ', '»m getParameters at(«ii + 1»)«ENDFOR»)«ENDIF»
			«ENDFOR»
			les
		or
			[m isOfType("«COMMA_PREFIX»ObservedReply")]
			sel
			«FOR c : commands SEPARATOR '
			or'»
				[m getCommand getName = "«c.event.name»"]
				«c.port.name» ! «c.event.name»_r
			«ENDFOR»
			les
		«ENDIF»
		«IF !signals.empty»
		«IF !commands.empty»
		or
		«ENDIF»
			[m isOfType("«COMMA_PREFIX»ObservedSignal")]
			sel
			«FOR c : signals SEPARATOR '
			or'»
				[m getName = "«c.event.name»"]
				«c.port.name» ! «c.event.name»«IF c.event.parameters.size() > 0»(«FOR ii : 0..< c.event.parameters.size() SEPARATOR ', '»m getParameters at(«ii + 1»)«ENDFOR»)«ENDIF»
			«ENDFOR»
			les
		«ENDIF»
		«IF !outgoing.empty»
		«IF !incoming.empty»
		or
		«ENDIF»
			[m isOfType("«COMMA_PREFIX»ObservedNotification")]
			sel
			«FOR n : outgoing SEPARATOR '
			or'»
				[m getName = "«n.event.name»"]
				«n.port.name» ! «n.event.name»
			«ENDFOR»
			les
		«ENDIF»
		les
	'''
	
	static def monitorProcessClass(Signature s)
	'''«s.name»Monitor'''
	
	override determineRecordTypePrefix(RecordTypeDecl t){
		if(t.eContainer !== null && (t.eContainer instanceof Signature)){
			return '''«(t.eContainer as Signature).name»_'''
		}
		
		return ""
	}
	
}