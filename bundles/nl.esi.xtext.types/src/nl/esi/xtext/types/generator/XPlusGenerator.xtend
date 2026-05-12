/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

abstract class XPlusGenerator extends AbstractGenerator{
	
	final protected String fileName;	
	final protected IFileSystemAccess fsa;

	new(String fileName, IFileSystemAccess fsa) {
		this.fileName = fileName
		this.fsa = fsa
	}
	
	def generateFile(CharSequence content) {
		fsa.generateFile(fileName, content)
	}
	
	def generate() {
		fsa.generateFile(fileName, content)
	}
	
	def CharSequence getContent() {
		//do nothing
	}
	
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		//do nothing
	}
	
}