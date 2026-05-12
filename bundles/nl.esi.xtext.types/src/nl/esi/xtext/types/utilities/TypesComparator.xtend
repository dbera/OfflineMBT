/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.utilities

import java.util.List
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.TypeReference
import nl.esi.xtext.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.EObject
import nl.esi.xtext.types.types.MapTypeConstructor

class TypesComparator {
	
	def boolean sameAs(EObject o1, EObject o2){
		if(o1 === null && o2 === null) return true
		if(o1 !== null && o2 !== null) {
			if(o1.class === o2.class)
				return o1.compare(o2)
		}
		false
	}
	
	def boolean compareLists(List<? extends EObject> l1, List<? extends EObject> l2){
		if(l1.size != l2.size) return false
		for(i : 0..< l1.size){
			if(! l1.get(i).sameAs(l2.get(i))) return false
		}
		true
	}
	
	def boolean compareListsAsSets(List<? extends EObject> l1, List<? extends EObject> l2){
		l1.forall(itemL1 | l2.exists(itemL2 | itemL1.sameAs(itemL2))) &&
		l2.forall(itemL2 | l1.exists(itemL1 | itemL2.sameAs(itemL1)))
	}
	
	def dispatch boolean compare(TypeDecl td1, TypeDecl td2){
		td1 === td2
	}
	
	def dispatch boolean compare(TypeReference tr1, TypeReference tr2){
		tr1.type === tr2.type
		
	}
	
	def dispatch boolean compare(VectorTypeConstructor t1, VectorTypeConstructor t2){
		t1.type === t2.type && t1.dimensions.size == t2.dimensions.size
	}
	
	def dispatch boolean compare(MapTypeConstructor t1, MapTypeConstructor t2){
		t1.type === t2.type && compare(t1.valueType, t2.valueType)
	}
	
}