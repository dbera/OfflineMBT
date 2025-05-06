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
package nl.esi.comma.types.generator.dezyne

import java.util.ArrayList
import java.util.List
import java.util.Map
import java.util.Map.Entry
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.VectorTypeDecl

class TypeToDezyneProjectMapping extends TypesToDezyne {	
	
	Map<String, DezyneTargetTypeSpec> typeMappings
	List<String> parameterTypes
	List<String> emumTypeNames = new ArrayList
	List<TypeDecl> globalTypes = new ArrayList<TypeDecl>
	
	new(Map<String, DezyneTargetTypeSpec> typeMappings) {	
		this.typeMappings = typeMappings
		this.globalTypes = new ArrayList<TypeDecl>	
		setDefaultMappings()
	}
	
	def getParameterTypes() {
		parameterTypes
	}
	
	def setParameterTypes(List<String> parameterTypes) {
		this.parameterTypes = parameterTypes
	}
	
	def getEmumTypeNames() {
		emumTypeNames
	}
	
	def setEmumTypeNames(List<String> emumTypeNames) {
		this.emumTypeNames = emumTypeNames
	}
	
	def getTypeMappings() {
		typeMappings
	}
	
	/**
	 * Needed to check if the emum is used in the parameter list or not
	 */
	override dispatch CharSequence generateDezyneType(EnumTypeDecl t) {
		emumTypeNames.add(t.name)
		'''		
			enum «t.name»
			{
				«FOR v : t.literals SEPARATOR ','»
					«v.name»
				«ENDFOR»
			};
			«IF (parameterTypes.contains(t.name))»
				extern «t.name»_E $«t.name»$;
			«ENDIF»
		'''
	}
	
	override dispatch CharSequence generateDezyneType(RecordTypeDecl t) '''
		extern «t.name» $«t.name»$;
	'''
	
	// TODO Solution for this - could be extern 
	override dispatch CharSequence generateDezyneType(VectorTypeDecl t) '''
		extern «t.name» $«t.name»$;
	'''
	
	override dispatch CharSequence generateDezyneType(SimpleTypeDecl t) {
		// Looking for t in typeMappings 
		if (typeMappings.containsKey(t.name)) {
			if (typeMappings.get(t.name).isTypeDef) {
				typeMappings.get(t.name).dezyneTypeName = typeMappings.get(t.name).targetTypeName;
				return '''extern «typeMappings.get(t.name).targetTypeName» $«t.name»$;'''
			} else {
				typeMappings.get(t.name).dezyneTypeName = t.name;
				return '''extern «t.name» $«typeMappings.get(t.name).targetTypeName»$;'''

			}
		}

	}
	
	/**
	 * Generate the type mappings not present in the type declaration list. Including the default mapping
	 */
	def generateTypeMappings(List<TypeDecl> types)'''
		«FOR mapping: typeMappings.entrySet»
			«IF !types.exists[t | t.name == mapping.key]»
				«generateTypeMappingToDezyne(mapping)»
			«ENDIF»
		«ENDFOR»
	'''
	
	def CharSequence generateTypeMappingToDezyne(Entry<String, DezyneTargetTypeSpec> mapping){
		if(mapping.value.isTypeDef){
			mapping.value.dezyneTypeName = mapping.value.targetTypeName
			if(!mapping.key.contains("void") ){
				return '''extern «mapping.value.dezyneTypeName» $«mapping.key»$;'''
			}
		}
		else{
			mapping.value.dezyneTypeName = mapping.key
			if(!mapping.key.contains("void") ){
				return'''extern «mapping.key» $«mapping.value.targetTypeName»$;'''	
			}
		}
		
	}

	def setDefaultMappings(){
		if(!typeMappings.containsKey("real")){} typeMappings.put("real", new DezyneTargetTypeSpec("float", false, null))
		if(!typeMappings.containsKey("int")) typeMappings.put("int", new DezyneTargetTypeSpec("int", false, null, "int"))
		if(!typeMappings.containsKey("bool")) typeMappings.put(EXTERN_BOOL, new DezyneTargetTypeSpec("bool", false, null, EXTERN_BOOL))
		if(!typeMappings.containsKey("string")) typeMappings.put("string", new DezyneTargetTypeSpec("reftype(std::string)",false,  null, "string"))
		if(!typeMappings.containsKey("void")) typeMappings.put("void", new DezyneTargetTypeSpec("void", false, null, "void"))
	}
	
	def addTypeDeclaration(Iterable<TypeDecl> decls) {
		globalTypes.addAll(decls)
	}
	
	def globalTypesToDezyne() '''
					«FOR type : globalTypes»
						«typeToDezyneSyntax(type)»
					«ENDFOR»
					«generateTypeMappings(globalTypes)»
				'''
	
}
			