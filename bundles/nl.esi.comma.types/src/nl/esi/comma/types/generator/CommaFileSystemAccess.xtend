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
	
	// static helpers

	static def rootPrefix(IFileSystemAccess fileSystemAccess) {
		if (fileSystemAccess instanceof CommaFileSystemAccess) {
			(fileSystemAccess as CommaFileSystemAccess).rootPrefix
		} else {
			""
		}
	}

	static def rootPrefixCommaGen(IFileSystemAccess fileSystemAccess) {
		val root = if (fileSystemAccess instanceof CommaFileSystemAccess) {
				(fileSystemAccess as CommaFileSystemAccess).rootPrefix
			} else {
				""
			}
		root + FOLDER_UP + "comma-gen/"
	}

	static def getGenerationFolder(IFileSystemAccess fileSystemAccess) {
		if (fileSystemAccess instanceof CommaFileSystemAccess) {
			(fileSystemAccess as CommaFileSystemAccess).generationFolder
		} else {
			""
		}
	}

	// Poosl generated monitoring and statistics
	
	static def getTraceMonitorPath(String traceFileName) {
		traceFileName + "/"
	}	

	static def getRelativeMonitorResult(IFileSystemAccess fsa) {
		//fsa has a path ending with the task name
		var monitorResultFolder = ""
		if(fsa instanceof CommaFileSystemAccess){
			val uri = URI.createFileURI(fsa.generationFolder)
			monitorResultFolder = uri.segments.get(1) + "/" + uri.segments.get(2) + "/"
		}
		rootPrefixCommaGen(fsa)  + monitorResultFolder
	}

	static def getRelativeStatistics(IFileSystemAccess fsa) {
		val uri = URI.createFileURI((fsa as CommaFileSystemAccess).generationFolder)
		rootPrefixCommaGen(fsa) + uri.segments.get(1) + "/" + STATISTICS_FOLDER + "/"
	}
	
	static def getBasicFSA(IFileSystemAccess2 fsa) {
		if (fsa instanceof CommaFileSystemAccess) {
			return (fsa as CommaFileSystemAccess).fileSystemAccess
		} 
		return fsa
	}

	static def getStatisticsFSA(IFileSystemAccess2 fsa, String taskName) {
		new CommaFileSystemAccess(taskName + "/" + STATISTICS_FOLDER + "/", getBasicFSA(fsa), true)
	}

	static def getMonitorResultFSA(IFileSystemAccess2 fsa, String taskName, String traceFileName) {
		new CommaFileSystemAccess(getTraceMonitorPath(taskName + "/" + traceFileName), getBasicFSA(fsa), true)
	}

	static def getCommaGenFSA(IFileSystemAccess2 fsa) {
		new CommaFileSystemAccess("", getBasicFSA(fsa), true)
	}
	
	 def getOutputConfiguration() {
		var IPath path = null
		if(fileSystemAccess instanceof AbstractFileSystemAccess) {
			path = getOutputPath(fileSystemAccess as AbstractFileSystemAccess)
			path = path.append(generationFolder)
		} else {
			path = new Path("src-gen/")
		}
		return URI.createFileURI(path.toString)
	}
	
	def private getOutputPath(AbstractFileSystemAccess access) {
		val configs = access.outputConfigurations
		if (!configs.isEmpty) {
			var IPath path = new Path(configs.get(DEFAULT_OUTPUT).outputDirectory)
			return if(!path.hasTrailingSeparator) path.addTrailingSeparator else path
		}
		return new Path("src-gen/")
	}

}
