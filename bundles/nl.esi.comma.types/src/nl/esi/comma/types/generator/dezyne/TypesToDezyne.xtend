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

import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import org.eclipse.emf.ecore.util.EcoreUtil

class TypesToDezyne {
	public final static String EXTERN_BOOL = "dezyne_BOOL"

	def dispatch CharSequence typeToDezyneSyntax(TypeReference t){
		var type = t.type
		if(type.eIsProxy) {
			type = EcoreUtil.resolve(type, t) as TypeDecl
		}
		typeToDezyneSyntax(type)
	}
	
	def dispatch CharSequence typeToDezyneSyntax(TypeDecl t){
		generateDezyneType(t)
	}
	
	def dispatch CharSequence typeToDezyneSyntax(VectorTypeConstructor t){
		'''«typeToDezyneSyntax(t.type)»'''
	}
	
	def dispatch CharSequence generateDezyneType(EnumTypeDecl t){
		return t.name
	}
	
	//Simple types will be generated as extern data
	//Looking in the mapping of the project for the generated data.
	def dispatch CharSequence generateDezyneType(SimpleTypeDecl t){
		return t.name		
	}
		
	def dispatch CharSequence generateDezyneType(RecordTypeDecl t){
		return t.name
	}
	
	def dispatch CharSequence generateDezyneType(VectorTypeDecl t){
		return t.name
	}

	
	def dispatch CharSequence generateDefaultValue(TypeReference t){
		generateDefaultValue(t.type)
	}
	
	def dispatch CharSequence generateDefaultValue(SimpleTypeDecl t){
		if(t.name.equals("int")) return '''0'''
		if(t.name.equals("real")) return '''0.0'''
		if(t.name.equals("bool")) return '''true'''
		if(t.name.equals("string")) return '''""'''
		""
	}
	
	def dispatch CharSequence generateDefaultValue(EnumTypeDecl t){
		typeToDezyneSyntax(t) + "." + t.literals.get(0).name + ";"
	}
	
	
	def dispatch CharSequence generateDefaultValue(RecordTypeDecl  t){
		'''«t.name»'''
	}
	
	
	def dispatch CharSequence generateDefaultValue(VectorTypeDecl t){
		'''«t.name»'''
	}
	
	def dispatch CharSequence generateDefaultValue(VectorTypeConstructor t){
		''''''
	}
	
	
}
