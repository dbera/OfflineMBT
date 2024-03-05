package nl.esi.comma.actions.generator.plantuml

import nl.esi.comma.actions.actions.AnyEvent
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.actions.actions.CommandEvent
import nl.esi.comma.actions.actions.CommandReply
import nl.esi.comma.actions.actions.EVENT_KIND
import nl.esi.comma.actions.actions.EventCall
import nl.esi.comma.actions.actions.IfAction
import nl.esi.comma.actions.actions.NotificationEvent
import nl.esi.comma.actions.actions.RecordFieldAssignmentAction
import nl.esi.comma.actions.actions.SignalEvent
import nl.esi.comma.expressions.generator.plantuml.ExpressionsUmlGenerator
import nl.esi.comma.signature.interfaceSignature.Signature
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.actions.actions.ParallelComposition
import nl.esi.comma.actions.utilities.ActionsUtilities
import nl.esi.comma.actions.utilities.EventPatternMultiplicity
import nl.esi.comma.actions.actions.PCFragmentReference
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator

class ActionsUmlGenerator extends ExpressionsCommaGenerator { //ExpressionsUmlGenerator {
	
	/*new(String fileName, IFileSystemAccess fsa) {
		//super(fileName, fsa)
	}*/
		
	def dispatch CharSequence generateAction(AssignmentAction a)
	'''«a.assignment.name» := «exprToComMASyntax(a.exp)» '''
	
	def dispatch CharSequence generateAction(RecordFieldAssignmentAction a)
	'''«exprToComMASyntax(a.fieldAccess)» := «exprToComMASyntax(a.exp)» '''
	
	def dispatch CharSequence generateAction(IfAction a)
	'''if «exprToComMASyntax(a.guard)» then «FOR act : a.thenList.actions»«generateAction(act)»«ENDFOR»«IF a.elseList !== null» else «FOR act : a.elseList.actions»«generateAction(act)» «ENDFOR»«ENDIF»fi '''
	
	def dispatch CharSequence generateAction(CommandReply a)
	'''reply«IF a.parameters.size() > 0»(«exprToComMASyntax(a.parameters.get(0))»)«ENDIF» '''
	
	def dispatch CharSequence generateAction(EventCall a)
	'''«(a.event.eContainer as Signature).name»::«a.event.name»«IF a.parameters.size() > 0»(«FOR p : a.parameters SEPARATOR ', '»«exprToComMASyntax(p)»«ENDFOR»)«printMultiplicity(ActionsUtilities::getNormalizedMultiplicity(a))»«ENDIF» '''
	
	def dispatch CharSequence generateAction(PCFragmentReference a)
	'''fragment «a.fragment.name»'''
	
	def dispatch CharSequence generateAction(ParallelComposition a)
	'''any order(«FOR c : a.components SEPARATOR ', '»«generateAction(c)»«ENDFOR») '''
	
	def printMultiplicity(EventPatternMultiplicity m){
		if(m.lower == m.upper) return (if (m.lower == 1)'''''' else'''[«m.lower»]''')
		if(m.upper == -1){
			if(m.lower == 0) return '''[*]'''
			if(m.lower == 1) return '''[+]'''
			else return '''[«m.lower»-*]'''
		}else{
			if(m.lower == 0 && m.upper == 1) return '''[?]'''
			else return '''[«m.lower»-«m.upper»]'''
		}
	}
	
	def dispatch eventToUML(CommandEvent e, boolean expected)'''
						Client ->«IF ! expected»x«ENDIF» Server: command «(e.event.eContainer as Signature).name»_«e.event.name»«IF e.parameters.size() >0 »(«FOR p : e.parameters SEPARATOR ', '»«exprToComMASyntax(p)»«ENDFOR»)«ENDIF»
					'''
	def dispatch eventToUML(SignalEvent e, boolean expected)'''
						Client ->>«IF ! expected»x«ENDIF» Server: signal «(e.event.eContainer as Signature).name»_«e.event.name»«IF e.parameters.size() >0 »(«FOR p : e.parameters SEPARATOR ', '»«exprToComMASyntax(p)»«ENDFOR»)«ENDIF»
					'''
	
	def dispatch eventToUML(CommandReply e, boolean expected)'''
						Server -->«IF ! expected»x«ENDIF» Client: reply «IF e.parameters.size() > 0»(«exprToComMASyntax(e.parameters.get(0))»)«ENDIF»«IF e.command !== null» to command «(e.command.event.eContainer as Signature).name»_«e.command.event.name»«IF e.command.parameters.size() >0 »(«FOR p : e.command.parameters SEPARATOR ', '»«exprToComMASyntax(p)»«ENDFOR»)«ENDIF»«ENDIF»
					'''
	
	def dispatch eventToUML(NotificationEvent e, boolean expected)'''
						Client «IF ! expected»x«ENDIF»//- Server: notification «(e.event.eContainer as Signature).name»_«e.event.name»«IF e.parameters.size() >0 »(«FOR p : e.parameters SEPARATOR ', '»«exprToComMASyntax(p)»«ENDFOR»)«ENDIF»
					'''
	
	def dispatch eventToUML(AnyEvent e, boolean expected)'''
						«IF e.kind == EVENT_KIND::CALL»Client ->«IF ! expected»x«ENDIF» Server: any command«ENDIF»
						«IF e.kind == EVENT_KIND::SIGNAL»Client ->>«IF ! expected»x«ENDIF» Server: any signal«ENDIF»
						«IF e.kind == EVENT_KIND::NOTIFICATION»Client «IF ! expected»x«ENDIF»//- Server: any notification«ENDIF»
						«IF e.kind == EVENT_KIND::EVENT»Client <->«IF ! expected»x«ENDIF» Server: any event«ENDIF»
					'''
}