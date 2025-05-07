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
package nl.esi.comma.signature.generator.poosl

import java.util.List
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.generator.poosl.TypesPooslGenerator
import nl.esi.comma.types.types.RecordTypeDecl
import org.eclipse.xtext.generator.IFileSystemAccess
//import nl.esi.comma.poosl.api.util.POOSLApiLoader

class RecordsGenerator extends TypesPooslGenerator {
	public static final String RECORDS_FILE = "records.poosl"
	
	new(IFileSystemAccess fsa) {
		super(RECORDS_FILE, fsa)
	}

	def doGenerate(List<RecordTypeDecl> recordTypes) {
		generateFile(content(recordTypes))			
	}

	def content(List<RecordTypeDecl> rt) 
	'''
	«pooslImports»
	
	«IF rt.empty»
	//No records available for this project
	«ELSE»
	«FOR t : rt»
	«toRecordDataClass(t)»
	«ENDFOR»
	«ENDIF»
	'''
	
	def pooslImports()
	'''import "../api/"''' //«POOSLApiLoader.EXPRESSIONS»
	
	override determineRecordTypePrefix(RecordTypeDecl t) {
		if (t.eContainer !== null && (t.eContainer instanceof Signature)) {
			return '''«(t.eContainer as Signature).name»_'''
		}
		return ""
	}
}
