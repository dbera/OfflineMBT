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

import java.util.ArrayList
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.EcoreUtil2

class XPlusUtilities {
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