package nl.esi.comma.signature.utilities

import java.util.ArrayList
import java.util.List
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.types.RecordTypeDecl

import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import nl.esi.comma.signature.interfaceSignature.Command

class InterfaceUtilities {
	/*
	 * Returns the record type declarations in the given Signature
	 */
	 def static List<RecordTypeDecl> getRecordTypes(Signature s){
	 	val recordTypes = new ArrayList<RecordTypeDecl>
		recordTypes.addAll(s.types.filter(RecordTypeDecl))
		recordTypes			
	 }
	 
	 /*
	  * Returns all events in the given signature
	  */
	 def static List<InterfaceEvent> getAllInterfaceEvents(Signature s){
	 	var List<InterfaceEvent> events = new ArrayList<InterfaceEvent>();
		events.addAll(s.commands);
		events.addAll(s.notifications);
		events.addAll(s.signals);
		events
	 }
	 
	 def static InterfaceEvent getInterfaceEventByName(String name, Signature s){
	 	for(e : getAllInterfaceEvents(s)){
	 		if(e.name.equals(name)) return e
	 	}
	 	return null
	 }
	 
	/*
	 * Returns all commands and signals for a signature
	 */
	def static List<InterfaceEvent> getCommandsAndSignals(Signature s){
		var result = new ArrayList<InterfaceEvent>()
		result.addAll(s.commands)
		result.addAll(s.signals)
		result
	}
	
	def static boolean usesMaps(Signature s){
		s.allInterfaceEvents.exists(e | e.usesMaps)
	}
	
	def static boolean usesMaps(InterfaceEvent e){
		e.parameters.map[type].exists(t | t.usesMaps) ||
		if(e instanceof Command){e.type.usesMaps}else{false}
	}
}
