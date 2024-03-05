package nl.esi.comma.behavior.generator.poosl

import nl.esi.comma.behavior.behavior.Port
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent

class PortEventPair {
	public Port port
	public InterfaceEvent event
	
	new(Port p, InterfaceEvent ev){
		port = p
		event = ev
	}
}