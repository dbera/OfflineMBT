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

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.FilenameFilter
import java.io.InputStream
import java.io.InputStreamReader
import java.io.OutputStream
import java.nio.file.Files
import java.nio.file.LinkOption
import java.nio.file.Path
import java.nio.file.Paths
import java.text.MessageFormat
import java.util.ArrayList
import java.util.List
// import net.sourceforge.plantuml.SourceFileReader // Commented DB: 23.03.2025
import org.apache.commons.cli.DefaultParser
import org.apache.commons.cli.CommandLine
import org.apache.commons.cli.HelpFormatter
import org.apache.commons.cli.Options
import org.apache.commons.lang.SystemUtils
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.runtime.Status
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.generator.GeneratorDelegate
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import java.io.PrintStream
import java.util.Comparator
import org.eclipse.xtext.util.StringInputStream
import java.io.FileInputStream

class CommaMain {
	/*
	 * (C) Copyright 2018 TNO-ESI.
	 */
	static final String ERR_LOCATION_MISSING = 'Location is not provided as argument'
	static final String ERR_LOCATION_WRONG = 'Location could not be found. '
	
	final static String MON_ROTALUMIS = "rotalumis.exe"
	final static String MON_GEN_POOSL = "poosl" + File.separator
	final static String MON_SCENARIOPLAYER = "ScenarioPlayer.poosl"
	final static String MON_WORKING_DIR ="simulator"
	final static String MON_COMMAND = " --quiet --poosl "

	static final String INFO_GENERATION_FINISHED = 'Code generation finished.'
	static final String INFO_COMMA_FINISHED = 'All ComMA Tasks are finished.'
	static final String INFO_SEARCHING = 'Searching for {0} ({1}) files in {2}'
	static final String INFO_OUTPUT = 'Output set: '
	static final String INFO_STOP = 'Errors found, stopping generation.'
	static final String INFO_READING = '-> Reading '
	static final String INFO_EMPTY_LOCATION = 'Location contained no project files. '

	static final String OPT_HELP = 'help'
	static final String OPT_HELP_C = 'h'
	static final String OPT_HELP_DESCRIPTION = 'Show options.'

	static final String OPT_LOCATION = 'location'
	static final String OPT_LOCATION_C = 'l'
	static final String OPT_LOCATION_DESCRIPTION = 'Location of the file or directory (Required argument)'

	static final String OPT_VALIDATION = 'validation'
	static final String OPT_VALIDATION_C = 'v'
	static final String OPT_VALIDATION_DESCRIPTION = 'Turns OFF validation, validation is ON by default.'

	static final String OPT_OUTPUT = 'output'
	static final String OPT_OUTPUT_C = 'o'
	static final String OPT_OUTPUT_DESCRIPTION = 'Set output location of the generated files, the default is "src-gen" at the provided "location".'
	static final String DEFAULT_OUTPUT_DIR = 'src-gen'

	static final String OPT_CLEAN_C = 'c'
	static final String OPT_CLEAN_DESCRIPTION = 'Turns ON cleaning the output folder before generation, clean is OFF by default.'
	static final String OPT_CLEAN = 'clean'
	
	static final String OPT_MONITORING = 'monitoring'
	static final String OPT_MONITORING_C = 'm'
	static final String OPT_MONITORING_DESCRIPTION = 'Deprecated. If monitoring tasks are present all of them will be executed regardless the value of the -m argument.'	
	
	static final String OPT_TESTSPECIFICATION = 'testspecification'
	static final String OPT_TESTSPECIFICATION_C = 'ts'
	static final String OPT_TESTSPECIFICATION_DESCRIPTION = 'Location of Test Specification'
	
	static final String OPT_TESTSPECIFICATIONOUTPUT = 'TestspecOutput'
	static final String OPT_TESTSPECIFICATIONOUTPUT_C = 'tsOutput'
	static final String OPT_TESTSPECIFICATIONOUTPUT_DESCRIPTION = 'Output location of the Test Specification Product'
	
	static final String OPT_STEPSFILES = 'StepsFiles'
	static final String OPT_STEPSFILES_C = 'sl'
	static final String OPT_STEPSFILES_DESCRIPTION = 'Location of the Step Definitions'
	
	static final String OPT_CONTEXT = 'Context'
	static final String OPT_CONTEXT_C = 'ctx'
	static final String OPT_CONTEXT_DESCRIPTION = 'Test contexts in the Step Definition'
	
	static final String OPT_TESTCONFIGOUTPUT = 'testconfigOutput'
	static final String OPT_TESTCONFIGOUTPUT_C = 'to'
	static final String OPT_TESTCONFIGOUTPUT_DESCRIPTION = 'Output location of the generated test configuration files'
	
	static final String OPT_SPECDIFFOUTPUT = 'SpecDiff'
	static final String OPT_SPECDIFFOUTPUT_C = 'so'
	static final String OPT_SPECDIFFOUTPUT_DESCRIPTION = 'Output location of the SpecDiff dashboard'
	
	static final String OPT_ORIGINALFEATURES = 'OriginalFeature'
	static final String OPT_ORIGINALFEATURES_C = 'ofl'
	static final String OPT_ORIGINALFEATURES_DESCRIPTION = 'Location of the original Feature files'
	
	static final String OPT_UPDATEDFEATURES = 'UpdatedFeature'
	static final String OPT_UPDATEDFEATURES_C = 'ufl'
	static final String OPT_UPDATEDFEATURES_DESCRIPTION = 'Location of the updated Feature files'
	
	static final String OPT_ORIGINALTESTCONFIG = 'OriginalTestConfig'
	static final String OPT_ORIGINALTESTCONFIG_C = 'otl'
	static final String OPT_ORIGINALTESTCONFIG_DESCRIPTION = 'Location of the original Test Config'
	
	static final String OPT_UPDATEDTESTCONFIG = 'UpdatedTestConfig'
	static final String OPT_UPDATEDTESTCONFIG_C = 'utl'
	static final String OPT_UPDATEDTESTCONFIG_DESCRIPTION = 'Location of the updated Test Config'
	
	static final String OPT_ORIGINALSYSCONFIG = 'OriginalSystemConfig'
	static final String OPT_ORIGINALSYSCONFIG_C = 'osl'
	static final String OPT_ORIGINALSYSCONFIG_DESCRIPTION = 'Location of the original System Config'
	
	static final String OPT_UPDATEDSYSCONFIG = 'UpdatedSystemConfig'
	static final String OPT_UPDATEDSYSCONFIG_C = 'usl'
	static final String OPT_UPDATEDSYSCONFIG_DESCRIPTION = 'Location of the updated System Config'
	
	static final String OPT_SENSITIVITY = 'sensitivity'
	static final String OPT_SENSITIVITY_C = 's'
	static final String OPT_SENSITIVITY_DESCRIPTION = 'Sensitivity for selecting the tests based on name, Integer between 0 to 100'

    static final String OPT_IOVERLAP = 'ignoreOverlap'
    static final String OPT_IOVERLAP_C = 'io'
    static final String OPT_IOVERLAP_DESCRIPTION = 'Boolean to ignore step overlap'
    
    static final String OPT_ICONTEXT = 'ignoreContext'
    static final String OPT_ICONTEXT_C = 'ic'
    static final String OPT_ICONTEXT_DESCRIPTION = 'Boolean to ignore step context'
	
	static final String ERR_CONTEXT_MISSING = 'Test context is not provided as argument'
	
	@Inject Provider<ResourceSet> resourceSetProvider

	@Inject IResourceValidator validator

	@Inject GeneratorDelegate generator

	@Inject JavaIoFileSystemAccess fileAccess

	String[] args
	String description
	String language
	String ext

	def configure(String[] args, String description, String language, String ext) {
		this.args = args
		this.description = description
		this.language = language
		this.ext = ext
	}

	def read() {

		val options = createOptions
		if (args.empty) {
			System::err.println(ERR_LOCATION_MISSING)
			showInfo(description, options)
			System.exit(1);
			return
		}

		val parser = new DefaultParser;
		val cmdLine = parser.parse(options, args);
		if (cmdLine.hasOption(OPT_HELP)) {
			showInfo(description, options)
		} else {
			if (cmdLine.hasOption(OPT_STEPSFILES)){
				stepsParserOPT(cmdLine, options)
			}
			
			if (cmdLine.hasOption(OPT_TESTSPECIFICATION)){
				testSpecificationOPT(cmdLine, options)
			}
			
			if (cmdLine.hasOption(OPT_ORIGINALFEATURES)
				&& cmdLine.hasOption(OPT_UPDATEDFEATURES)
			){
				specDiffOPT(cmdLine, options)
			}
			
			if (cmdLine.hasOption(OPT_LOCATION)){
				monitoringOPT(cmdLine, options)
			}
		}
	}
	
	def testSpecificationOPT(CommandLine cmdLine, Options options) {
		// var ResourceSet set
		val set = resourceSetProvider.get
		val tspecPath = getLocation(cmdLine, OPT_TESTSPECIFICATION)
		val outputdir = getOutputdir(cmdLine, tspecPath, OPT_TESTSPECIFICATIONOUTPUT)
		
		System.out.println(INFO_OUTPUT + outputdir)
		cleanOutput(cmdLine, outputdir)
		
		if (tspecPath === null) {
			System::err.println(ERR_LOCATION_MISSING)
			showInfo(description, options)
			System.exit(1)
			return
		}

        //if(tsModel.allContents.head instanceof TSMain) {
		set.createResource(URI.createURI("Example.prj")).load(new StringInputStream('''
		Project P1 {
			Generate test-documentation {
				demo {
					test-specification-file "«tspecPath.fileName.toString.replace("\\","\\\\")»"
				}
			}
		}
		'''), emptyMap)
		val resource = set.getResource(URI.createFileURI("Example.prj"), true)
		var cliContext = new TestSpecContext(tspecPath)

		// Configure and start the generator
		fileAccess.outputPath = outputdir.toString
		setCommaGen(fileAccess, outputdir.toString)
		
		generator.generate(resource, fileAccess, cliContext)
	}
	
	def specDiffOPT(CommandLine cmdLine, Options options) {
		val oriFeaturePath = getLocation(cmdLine, OPT_ORIGINALFEATURES)
		val updFeaturePath = getLocation(cmdLine, OPT_UPDATEDFEATURES)
		val oritcPath = getLocation(cmdLine, OPT_ORIGINALTESTCONFIG)
		val updtcPath = getLocation(cmdLine, OPT_UPDATEDTESTCONFIG)
		val oriscPath = getLocation(cmdLine, OPT_ORIGINALSYSCONFIG)
		val updscPath = getLocation(cmdLine, OPT_UPDATEDSYSCONFIG)
		val sensitivity = cmdLine.getOptionValue(OPT_SENSITIVITY)
		val outputdir = getOutputdir(cmdLine, oriFeaturePath, OPT_SPECDIFFOUTPUT) 
		
		System.out.println(INFO_OUTPUT + outputdir)
		cleanOutput(cmdLine, outputdir)
		if (oriFeaturePath === null
			|| updFeaturePath === null
		){
			System::err.println(ERR_LOCATION_MISSING)
			showInfo(description, options)
			System.exit(1)
			return
		}
		if (!Files.exists(oriFeaturePath, LinkOption.NOFOLLOW_LINKS)) {
			System.out.println(ERR_LOCATION_WRONG + oriFeaturePath.toString)
			System.exit(1)
			return
		}
		if (!Files.exists(updFeaturePath, LinkOption.NOFOLLOW_LINKS)) {
			System.out.println(ERR_LOCATION_WRONG + updFeaturePath.toString)
			System.exit(1)
			return
		}

        var ignoreOverlap = false
        var ignoreContext = false
        if (cmdLine.hasOption(OPT_IOVERLAP)) ignoreOverlap = true
        if (cmdLine.hasOption(OPT_ICONTEXT)) ignoreContext = true

		runSpecDiff(oriFeaturePath, updFeaturePath, oritcPath, updtcPath, oriscPath, updscPath, Integer.parseInt(sensitivity), outputdir.toString, ignoreOverlap, ignoreContext)
		System.out.println(INFO_GENERATION_FINISHED)
	}
	
	def stepsParserOPT(CommandLine cmdLine, Options options) {
		val stepPath = getLocation(cmdLine, OPT_STEPSFILES)
		if (stepPath === null) {
			System::err.println(ERR_LOCATION_MISSING)
			showInfo(description, options)
			System.exit(1)
			return
		}
		if (!Files.exists(stepPath, LinkOption.NOFOLLOW_LINKS)) {
			System.out.println(ERR_LOCATION_WRONG + stepPath.toString)
			System.exit(1)
			return
		}
		val context = cmdLine.getOptionValue(OPT_CONTEXT)
		if (context === null) {
			System::err.println(ERR_CONTEXT_MISSING)
			System.exit(1)
			return
		}
		val outputdir = Paths.get(cmdLine.getOptionValue(OPT_TESTCONFIGOUTPUT))
		System.out.println(INFO_OUTPUT + outputdir)
		cleanOutput(cmdLine, outputdir)
		
		if (Files.isDirectory(stepPath, LinkOption.NOFOLLOW_LINKS)) {
			println(MessageFormat.format(INFO_SEARCHING, "StepDefinition", ".cs", stepPath.toString))
			val dir = new File(stepPath.toString)
			val stepFiles = dir.listFiles(createFileFilter(".cs"));
			if (stepFiles.empty) {
				System.out.println(INFO_EMPTY_LOCATION + stepPath.toString)
			}
		}
		runParser(stepPath, context, outputdir.toString)
		System.out.println("Output to: " + outputdir.toString)
		System.out.println(INFO_GENERATION_FINISHED)
	}
	
	def monitoringOPT(CommandLine cmdLine, Options options) {
		val locationPath = getLocation(cmdLine, OPT_LOCATION)
		if (locationPath === null) {
			System::err.println(ERR_LOCATION_MISSING)
			showInfo(description, options)
			System.exit(1)
			return
		}
		if (!Files.exists(locationPath, LinkOption.NOFOLLOW_LINKS)) {
			System.out.println(ERR_LOCATION_WRONG + locationPath.toString)
			System.exit(1)
			return
		}

		val validation = cmdLine.getOptionValue(OPT_VALIDATION) === null
		val outputdir = getOutputdir(cmdLine, locationPath, OPT_OUTPUT)
		System.out.println(INFO_OUTPUT + outputdir)
		cleanOutput(cmdLine, outputdir)

		if (Files.isDirectory(locationPath, LinkOption.NOFOLLOW_LINKS)) {
			println(MessageFormat.format(INFO_SEARCHING, language, ext, locationPath.toString))
			val dir = new File(locationPath.toString)
			val prjFiles = dir.listFiles(createFileFilter(ext));
			for (file : prjFiles) {
				runGeneration(file.absolutePath, outputdir.toString, validation)
			}
			if (prjFiles.empty) {
				System.out.println(INFO_EMPTY_LOCATION + locationPath.toString)
			}

		} else {
			runGeneration(locationPath.toString, outputdir.toString, validation)
		}
		System.out.println(INFO_GENERATION_FINISHED)
		runMonitoring(outputdir)
		
		System.out.println("")
		System.out.println(INFO_COMMA_FINISHED)	
	}

	def Options createOptions() {
		val options = new Options
		options.addOption(OPT_LOCATION_C, OPT_LOCATION, true, OPT_LOCATION_DESCRIPTION);
		options.addOption(OPT_OUTPUT_C, OPT_OUTPUT, true, OPT_OUTPUT_DESCRIPTION)
		options.addOption(OPT_HELP_C, OPT_HELP, false, OPT_HELP_DESCRIPTION)
		options.addOption(OPT_VALIDATION_C, OPT_VALIDATION, false, OPT_VALIDATION_DESCRIPTION)
		options.addOption(OPT_CLEAN_C, OPT_CLEAN, false, OPT_CLEAN_DESCRIPTION)
		options.addOption(OPT_MONITORING_C, OPT_MONITORING, true, OPT_MONITORING_DESCRIPTION)
		options.addOption(OPT_STEPSFILES_C, OPT_STEPSFILES, true, OPT_STEPSFILES_DESCRIPTION)
		options.addOption(OPT_CONTEXT_C, OPT_CONTEXT, true, OPT_CONTEXT_DESCRIPTION)
		options.addOption(OPT_TESTCONFIGOUTPUT_C, OPT_TESTCONFIGOUTPUT, true, OPT_TESTCONFIGOUTPUT_DESCRIPTION)
		options.addOption(OPT_ORIGINALFEATURES_C, OPT_ORIGINALFEATURES, true, OPT_ORIGINALFEATURES_DESCRIPTION)
		options.addOption(OPT_UPDATEDFEATURES_C, OPT_UPDATEDFEATURES, true, OPT_UPDATEDFEATURES_DESCRIPTION)
		options.addOption(OPT_ORIGINALTESTCONFIG_C, OPT_ORIGINALTESTCONFIG, true, OPT_ORIGINALTESTCONFIG_DESCRIPTION)
		options.addOption(OPT_UPDATEDTESTCONFIG_C, OPT_UPDATEDTESTCONFIG, true, OPT_UPDATEDTESTCONFIG_DESCRIPTION)
		options.addOption(OPT_ORIGINALSYSCONFIG_C, OPT_ORIGINALSYSCONFIG, true, OPT_ORIGINALSYSCONFIG_DESCRIPTION)
		options.addOption(OPT_UPDATEDSYSCONFIG_C, OPT_UPDATEDSYSCONFIG, true, OPT_UPDATEDSYSCONFIG_DESCRIPTION)
		options.addOption(OPT_SENSITIVITY_C, OPT_SENSITIVITY, true, OPT_SENSITIVITY_DESCRIPTION)
		options.addOption(OPT_IOVERLAP_C, OPT_IOVERLAP, false, OPT_IOVERLAP_DESCRIPTION)
		options.addOption(OPT_ICONTEXT_C, OPT_ICONTEXT, false, OPT_ICONTEXT_DESCRIPTION)
		options.addOption(OPT_SPECDIFFOUTPUT_C, OPT_SPECDIFFOUTPUT, true, OPT_SPECDIFFOUTPUT_DESCRIPTION)
		// Added
		options.addOption(OPT_TESTSPECIFICATION_C, OPT_TESTSPECIFICATION, true, OPT_TESTSPECIFICATION_DESCRIPTION)
	}

	def showInfo(String description, Options options) {
		val formatter = new HelpFormatter();
		formatter.printHelp(description, options);
	}

	def createFileFilter(String ext) {
		return new FilenameFilter() {
			override accept(File dir, String name) {
				(name.endsWith(ext))
			}
		}
	}

	def Path getLocation(CommandLine cmdLine, String loc) {
		val location = cmdLine.getOptionValue(loc);
		if (location !== null) {
			val locationPath = Paths.get(location)
			if (locationPath.isAbsolute) {
				return locationPath
			} else {
				val current = Paths.get("").toAbsolutePath()
				return current.resolve(locationPath)
			}
		}
		return null
	}

	def getOutputdir(CommandLine cmdLine, Path location, String output) {
		if (cmdLine.hasOption(output)) {
			val outputPath = Paths.get(cmdLine.getOptionValue(output)).resolve(DEFAULT_OUTPUT_DIR)
			if (outputPath.isAbsolute) {
				return outputPath
			} else {
				if (Files.isDirectory(location, LinkOption.NOFOLLOW_LINKS)) {
					return location.resolve(outputPath).normalize
				} else {
					val dirLocation = Paths.get(
						location.toString.substring(0, location.toString.lastIndexOf(File.separator)))
					return dirLocation.resolve(outputPath)
				}
			}
		} else {
			if (Files.isDirectory(location, LinkOption.NOFOLLOW_LINKS)) {
				return location.resolve(DEFAULT_OUTPUT_DIR).normalize
			} else {
				val dirLocation = Paths.get(
					location.toString.substring(0, location.toString.lastIndexOf(File.separator)))
				return dirLocation.resolve(DEFAULT_OUTPUT_DIR)
			}
		}
	}
	
	def runSpecDiff(Path oriFeature, Path updFeature, Path oriTC, Path updTC, Path oriSC, Path updSC, int sensitivity, String outputdir, boolean ignoreOverlap, boolean ignoreContext){
		// Load the resource
		System.out.println(INFO_READING)
		
		System.out.println(oriFeature.toString.replace("\\","\\\\"))
		System.out.println(updFeature.toString.replace("\\","\\\\"))
		var oriTCPath = ""
		var oriSCPath = ""
		var updTCPath = ""
		var updSCPath = ""
		val set = resourceSetProvider.get
		if (!oriTC.isNullOrEmpty){
			oriTCPath = oriTC.toString
		}
		if (!oriSCPath.isNullOrEmpty){
			oriSCPath = oriSC.toString
		}
		if (!updTC.isNullOrEmpty){
			updTCPath = updTC.toString
		}
		if (!updSC.isNullOrEmpty){
			updSCPath = updSC.toString
		}

		set.createResource(URI.createURI("Example.prj")).load(new StringInputStream('''
		Project NewProject {
			Generate SpecDiff-Dashboard {
				SpecDiffCmd {
					Original {
						«IF !oriTCPath.isNullOrEmpty»test-configuration directories "«oriTCPath.replace("\\","\\\\")»"«ENDIF»
						«IF !oriSCPath.isNullOrEmpty»system-configuration directories "«oriSCPath.replace("\\","\\\\")»"«ENDIF»
						specflow feature-directories "«oriFeature.toString.replace("\\","\\\\")»"
					}
					
					Updated {
						«IF !updTCPath.isNullOrEmpty»test-configuration directories "«updTCPath.replace("\\","\\\\")»"«ENDIF»
						«IF !updSCPath.isNullOrEmpty»system-configuration directories "«updSCPath.replace("\\","\\\\")»"«ENDIF»
						specflow feature-directories "«updFeature.toString.replace("\\","\\\\")»"
					}
					visualize-diff-graph
					sensitivity(0-100): «sensitivity»
					«IF ignoreOverlap»ignore-overlap«ENDIF»
					«IF ignoreContext»ignore-step-context«ENDIF»
				}
			}
		}
		'''), emptyMap)
		val resource = set.getResource(URI.createFileURI("Example.prj"), true)
		var cliContext = new SpecDiffContext(oriFeature.toString, updFeature.toString, sensitivity)

		// Configure and start the generator
		fileAccess.outputPath = outputdir
		setCommaGen(fileAccess, outputdir)
		
		generator.generate(resource, fileAccess, cliContext)
	}
	
	def runParser(Path stepsPath, String context, String outputdir){
		// Load the resource
		System.out.println(INFO_READING + stepsPath)
		
		val set = resourceSetProvider.get
		set.createResource(URI.createURI("Example.prj")).load(new StringInputStream('''
		Project NewProject {
			
		}
		'''), emptyMap)
		val resource = set.getResource(URI.createFileURI("Example.prj"), true)
		
		var contexts = context.split(' ')
		var cliContext = new StepsParserContext(stepsPath.toString, contexts, outputdir)
		// Configure and start the generator
		fileAccess.outputPath = outputdir
		setCommaGen(fileAccess, outputdir)
		
		generator.generate(resource, fileAccess, cliContext)
	}

	def runGeneration(String string, String outputdir, Boolean validation) {

		// Load the resource
		System.out.println(INFO_READING + string)

		val set = resourceSetProvider.get
		val resource = set.getResource(URI.createFileURI(string), true)

		// Validate the resource
		if (validation) {
			val issues = validator.validate(resource, CheckMode.ALL, CancelIndicator.NullImpl)
			if (!issues.empty) {
				issues.forEach[System.err.println(it)]
			}

			val errors = issues.filter[it.severity == Severity.ERROR]
			if (!errors.empty) {
				System.out.println(INFO_STOP)
				System.exit(1)
				return;
			}
		}
		// Configure and start the generator
		fileAccess.outputPath = outputdir
		setCommaGen(fileAccess, outputdir)
		
		generator.generate(resource, fileAccess, new CmdLineContext)
	}

	def cleanOutput(CommandLine cmdLine, Path outputdir) {
		if (cmdLine.hasOption(OPT_CLEAN)) {
			println("Start cleaning output directory.")
			val commagendir = outputdir.parent.resolve(CommaFileSystemAccess.COMMA_OUTPUT_CONF.outputDirectory).normalize
			//clean src-gen
			if(new File(outputdir.toString).exists){
				Files.walk(outputdir)
				.sorted(Comparator.reverseOrder())
				.forEach[Files::delete(it)]
			}
			//clean comma-gen
			if(new File(commagendir.toString).exists){
				Files.walk(commagendir)
				.sorted(Comparator.reverseOrder())
				.forEach[Files::delete(it)]
			}
			println("Clean finished.")
		}
	}

	def setCommaGen(JavaIoFileSystemAccess fileAccess, String outputdir) {
		val commaConf = CommaFileSystemAccess.COMMA_OUTPUT_CONF
		commaConf.outputDirectory = Paths.get(outputdir).parent.toString + commaConf.outputDirectory
		fileAccess.outputConfigurations.put(CommaFileSystemAccess.COMMA_OUTPUT_ID, commaConf)
	}
	
	def getCommaGen() {
		val commaGen = fileAccess.outputConfigurations.get(CommaFileSystemAccess.COMMA_OUTPUT_ID)		
		commaGen.outputDirectory
	}
	
	/**
	 * Runs the monitoring for the provided tasks.
	 */
	def runMonitoring(Path outputPath) {
		val pooslPath = outputPath.resolve(MON_GEN_POOSL)
		val tasks = pooslPath.toFile.listFiles
		//In order to run monitoring at least 1 task dir and 1 api dir has to be present.
		if(tasks !== null && tasks.size >= 2) {
			println("Monitoring tasks found.")
			val rotalumisPath = getJarDir + File.separator + MON_ROTALUMIS
			extractingRotalumis(rotalumisPath)		
			runRotalumis(rotalumisPath, pooslPath)
			convertPlantUml()
		}
	}
	
	def convertPlantUml() {
		val plantumlFiles = new ArrayList<File>
		findPlantUmlFiles(new File(getCommaGen()), plantumlFiles)
		if (!plantumlFiles.isEmpty) {
			println("Monitoring errors found, converting plantuml files to images.")

			for (plantFile : plantumlFiles) {
				println("--> " + plantFile.name)
					
//				val reader = new SourceFileReader(plantFile);
//				if (!reader.generatedImages.isEmpty) {
//					reader.getGeneratedImages().get(0);
//				}
			}
		}
	}
	
	def void findPlantUmlFiles(File dir, List<File> plantuml) {
		for (file : dir.listFiles) {
			if(file.name.endsWith(".plantuml")) {
				plantuml.add(file)
			}
			if(file.isDirectory) {
				findPlantUmlFiles(file, plantuml)
			}
		}
	}
	
	/**
	 * Running rotalumis with the scenarioplayer located in the generated task folder
	 * Example commandline "C:\rotalumis.exe --poosl C:\src-gen\poosl\task\ScenerioPlayer.poosl" 
	 */    
	
	def runRotalumis(String rotalumisPath, Path pooslPath) {
		
		
		try {
			println("--> Monitoring started")
			val scenarioPlayer = pooslPath.resolve(MON_SCENARIOPLAYER)
			println("--> " + scenarioPlayer)
			if (scenarioPlayer.toFile.exists) {
				var scenarioPlayerStr = scenarioPlayer.toString
				if(scenarioPlayerStr.contains(" ")){
					scenarioPlayerStr = "\"" + scenarioPlayerStr + "\""
				}
				val cmd = rotalumisPath + MON_COMMAND + scenarioPlayerStr;
				println("cmd: " + cmd)
				
				val workingDir = pooslPath.resolve(MON_WORKING_DIR).toFile
				workingDir.mkdirs

				val rt = Runtime.runtime				
				println("With working dir: " + workingDir.path)
				val process = rt.exec(cmd, #[], workingDir);

				var String line = null
				val reader = new BufferedReader(new InputStreamReader(process.inputStream), 1);
				while ((line = reader.readLine) !== null) {
					System.out.println(line);
				}
				
				val error = process.getErrorStream();
				if(error.available() > 0){
					System.out.println;
					System.out.println("Errors during the execution of the monitoring program.")
					System.out.println("Rotalumis error report:")
					val errorReader = new BufferedReader(new InputStreamReader(error), 1);
					while ((line = errorReader.readLine) !== null) {
						System.out.println(line);
					}
				}
				
				val outputStream = process.getOutputStream();
				val printStream = new PrintStream(outputStream);
				printStream.println();
				printStream.flush();
				printStream.close();				
				
				reader.close();
				process.waitFor
				println("Monitoring finished")
			} else {
				println("!! Monitoring Failed to run. " + scenarioPlayer + " could not be found.")
			}
		} catch (Exception e) {
			System.out.println(e.message)
			System.out.println(e)
		}
	}

	/**
	 * Extracting 32 or 64 bit Rotalumis
	 */
	def extractingRotalumis(String path) {
		val extracted = new File(path)
		if (extracted.exists) {
			if(!extracted.delete){
				println("The existing rotalumis.exe could not be deleted, no new file could be created. " + extracted.absolutePath)
				return null
			}
		}

		if (!extracted.createNewFile) {
			println("Rotalumis could not be extracted, no new file could be created. " + extracted.absolutePath)
			return null
		}

		var InputStream is = null
		var OutputStream os = null
		try {
			is = new BufferedInputStream(CommaMain.getResourceAsStream(platformVersion)); // rotalumisVersion
			os = new BufferedOutputStream(new FileOutputStream(extracted))
			 
			System.out.println("Extracting Rotalumis to " + extracted.absolutePath);
			var bytesRead = 0
			val buf = newByteArrayOfSize(1024);

			while ((bytesRead = is.read(buf)) > 0) {
				System.out.print("-");
				os.write(buf, 0, bytesRead);
			}
			System.out.println("Done");
			extracted.setExecutable(true, false)			
		} catch(Exception e) {
			System.out.println(e.message)
			System.out.println(e)
		} finally {
			is?.close
			os?.close
		}
	}

	def getPlatformVersion() {

		val stringBuilder = new StringBuilder();
		if (SystemUtils.IS_OS_WINDOWS) {
			stringBuilder.append("/windows/");
		} else {
			val status = new Status(Status.ERROR, "",
				"There is no support for your operating system. " + SystemUtils.OS_NAME, null);
			throw new CoreException(status);
		}
		if (SystemUtils.OS_ARCH.equals("x86") || "i386".equals(SystemUtils.OS_ARCH)) {
			stringBuilder.append("32bit/");
		} else if (SystemUtils.OS_ARCH.equals("x86_64")) {
			stringBuilder.append("64bit/");
		} else if ("amd64".equals(SystemUtils.OS_ARCH)) {
			// For some reason the constant for Platform.ARCH_amd64 is
			// deprecated
			stringBuilder.append("64bit/");
		} else {
			val status = new Status(Status.ERROR, "",
				"There is no support for your architecture. (" + SystemUtils.OS_ARCH + ")", null);
			throw new CoreException(status);
		}
		stringBuilder.append(MON_ROTALUMIS).toString
	}

	def getJarDir() {		
		Paths.get("").toAbsolutePath()
		val dir = Paths.get("").toAbsolutePath().toFile
		println("Current directory: " + dir.toPath.toString)
		return dir		
	}

}