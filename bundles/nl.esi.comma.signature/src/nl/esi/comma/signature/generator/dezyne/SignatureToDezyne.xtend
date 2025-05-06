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
package nl.esi.comma.signature.generator.dezyne

import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.DIRECTION
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.signature.interfaceSignature.Notification
import nl.esi.comma.signature.interfaceSignature.Signal
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.generator.dezyne.TypeToDezyneProjectMapping
import nl.esi.comma.types.generator.dezyne.TypesToDezyne

class SignatureToDezyne {

	final TypesToDezyne basicTypeGenerator = new TypesToDezyne
	final Signature signature
	final TypeToDezyneProjectMapping interfaceTypeMapping
	final TypeToDezyneProjectMapping globalTypeMapping

	new(Signature signature, TypeToDezyneProjectMapping interfaceTypeMapping,
		TypeToDezyneProjectMapping globalTypeMapping) {
		this.signature = signature
		this.interfaceTypeMapping = interfaceTypeMapping
		this.globalTypeMapping = globalTypeMapping
	}

	def dispatch CharSequence toDezyneEvent(InterfaceEvent infEvent) {
		toDezyneEvent(infEvent)
	}

	def dispatch CharSequence toDezyneEvent(Command infEvent) {
		var typeName = basicTypeGenerator.typeToDezyneSyntax(infEvent.type)
		var commandReturnTypeStruc = getDezyneReturnedType(typeName.toString, infEvent)
		var boolean isExternReturn = commandReturnTypeStruc.isExternDataType
		if (!isExternReturn)
			'''in «commandReturnTypeStruc.returnDataType» «toDezyneEventChars(infEvent)»'''
		else
			'''in «commandReturnTypeStruc.returnDataType» «toDezyneExternEventChars(infEvent, typeName)»'''
	}

	def dispatch CharSequence toDezyneEvent(Notification infEvent) '''
		out void «toDezyneEventChars(infEvent)»
	'''

	def dispatch CharSequence toDezyneEvent(Signal infEvent) '''
		in void «toDezyneEventChars(infEvent)»
	'''

	def getDezyneParameterType(CharSequence typeName) {
		var found = false;
		if (typeName.toString.contains("bool")) {
			return '''«TypesToDezyne.EXTERN_BOOL»'''
		}
		if (globalTypeMapping.emumTypeNames.contains(typeName)) {
			return '''«typeName»_E'''
		} else if (interfaceTypeMapping.emumTypeNames.contains(typeName)) {
			return '''«typeName»_E'''
		}
		if (interfaceTypeMapping.typeMappings.containsKey(typeName)) {
			return '''«interfaceTypeMapping.typeMappings.get(typeName).dezyneTypeName»'''
		}
		// If the type is definition is not found in the interface types then look for it in the global data types
		if (!found) {
			if (globalTypeMapping.typeMappings.containsKey(typeName)) {
				return '''«globalTypeMapping.typeMappings.get(typeName).dezyneTypeName»'''
			} else {
				return '''«typeName»'''
			}
		}
	}

	def CommandReturnedParameter getDezyneReturnedType(String typeName, Command c) {
		var p = new CommandReturnedParameter(c, typeName)
		if (typeName.contains("void")) {
			p.returnDataType = '''void'''
		} else if (typeName.contains("bool")) {
			p.returnDataType = '''bool'''
		} else if (globalTypeMapping.emumTypeNames.contains(typeName) ||
			interfaceTypeMapping.emumTypeNames.contains(typeName)) {
			p.returnDataType = typeName
		} else { // This is extern case
			p.returnDataType = '''void'''
			p.isExternDataType = true;
		}
		return p;
	}

	def CharSequence toDezyneEventChars(InterfaceEvent infEvent) '''
		«infEvent.name»(«FOR p : infEvent.parameters SEPARATOR ','»«if(p.direction != DIRECTION.IN) p.direction» «getDezyneParameterType(basicTypeGenerator.typeToDezyneSyntax(p.type))» «p.name»«ENDFOR»);
	'''

	def toDezyneExternEventChars(InterfaceEvent infEvent, CharSequence externType) '''
		«infEvent.name»(out «externType» returnedValue«IF !infEvent.parameters.empty», «ENDIF» «FOR p : infEvent.parameters SEPARATOR ','»«if(p.direction != DIRECTION.IN) p.direction» «getDezyneParameterType(basicTypeGenerator.typeToDezyneSyntax(p.type))» «p.name»«ENDFOR»);
	'''

	def CharSequence generateInterfaceSignature() '''
		«FOR c : signature.commands»
			«toDezyneEvent(c)»
		«ENDFOR»
		«FOR s : signature.signals»
			«toDezyneEvent(s)»
		«ENDFOR»
		
		«FOR n : signature.notifications»
			«toDezyneEvent(n)»
		«ENDFOR»
	'''
}
