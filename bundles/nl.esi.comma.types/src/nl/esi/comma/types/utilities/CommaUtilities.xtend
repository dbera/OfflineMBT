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
package nl.esi.comma.types.utilities

import java.util.ArrayList
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.EcoreUtil2

class CommaUtilities {
	static def <T extends EObject> List<T> resolveProxy(EObject context, Iterable<IEObjectDescription> elements) {
		var List<T> result = new ArrayList<T>
		for (descr : elements) {
			var object = descr.EObjectOrProxy
			if (object.eIsProxy) {
				object = EcoreUtil2.resolve(object, context)
			}
			result.add(object as T)
		}
		result
	}
	
	static def commaVersion(){
		"4.0.0"
	}
	
}