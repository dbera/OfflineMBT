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
package nl.esi.comma.types.generator

import java.util.HashMap
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.generator.AbstractFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.core.runtime.IPath
import org.eclipse.core.runtime.Path

class CommaFileSystemAccess implements IFileSystemAccess {

	final public static String STATISTICS_FOLDER = "statistics"
	final public static String FOLDER_UP = "../"
	
	final IFileSystemAccess2 fileSystemAccess	
	public String outputConfiguration = DEFAULT_OUTPUT
	String generationFolder	
	
	final public static String COMMA_OUTPUT_ID = "outputCommaGen"
	final public static String COMMA_OUTPUT_FOLDER = "./comma-gen"
	public static val OutputConfiguration COMMA_OUTPUT_CONF = {
		val config = new OutputConfiguration(COMMA_OUTPUT_ID)
		config.outputDirectory = COMMA_OUTPUT_FOLDER
		config.description = COMMA_OUTPUT_FOLDER
		config.createOutputDirectory = true
		config.canClearOutputDirectory = true
		config.cleanUpDerivedResources = true
		return config
	}

	new(String generationFolder, IFileSystemAccess2 fsa) {
		this.fileSystemAccess = fsa
		this.generationFolder = generationFolder		
	}

	new(String generationFolder, CommaFileSystemAccess commaFileSystemAccess) {
		this.fileSystemAccess = commaFileSystemAccess.IFileSystemAccess
		this.generationFolder = commaFileSystemAccess.getGenerationFolder + generationFolder
	}

	new(IFileSystemAccess2 fsa) {
		this.fileSystemAccess = fsa
		this.generationFolder = ""
	}
	
	new(String generationFolder, IFileSystemAccess2 fsa, boolean commaGen) {
		this.fileSystemAccess = fsa		
		this.generationFolder = generationFolder
		if(commaGen) {			
			setOutPutCommaGen			
		}	
	}

	override deleteFile(String fileName) {
		fileSystemAccess.deleteFile(generationFolder + fileName, outputConfiguration)
	}

	override generateFile(String fileName, CharSequence contents) {
		generateFile(fileName, outputConfiguration, contents)
	}

	override generateFile(String fileName, String outputConfigurationName, CharSequence contents) {
		fileSystemAccess.generateFile(generationFolder + fileName, outputConfigurationName, contents)
	}

	def String generateFileLocation(String fileName, CharSequence contents) {
		generateFile(fileName, contents)
		return generationFolder + fileName
	}

	def getIFileSystemAccess() {
		fileSystemAccess
	}

	def getGenerationFolder() {
		generationFolder
	}

	def addFolder(String additionalFolder) {
		val path =  if(!additionalFolder.endsWith("/")) additionalFolder + "/" else additionalFolder		
		new CommaFileSystemAccess(path, this)
	}	

	def getRootPrefix() {
		val sb = new StringBuilder();
		for (var i = 0; i < URI.createFileURI(generationFolder).segments.size - 1; i++) {
			sb.append(FOLDER_UP)
		}
		return sb.toString
	}
	
	def setOutPutCommaGen() {
		if (fileSystemAccess instanceof AbstractFileSystemAccess) {
			outputConfiguration = COMMA_OUTPUT_ID
			val configurations = fileSystemAccess.outputConfigurations
			if (!configurations.containsKey(COMMA_OUTPUT_ID)) {
				val newConfigurations = new HashMap(configurations)
				newConfigurations.put(COMMA_OUTPUT_ID, COMMA_OUTPUT_CONF)
				fileSystemAccess.outputConfigurations = newConfigurations
			}
		} else {
			generationFolder = FOLDER_UP + "comma-gen/" + generationFolder
		}
	}

}
