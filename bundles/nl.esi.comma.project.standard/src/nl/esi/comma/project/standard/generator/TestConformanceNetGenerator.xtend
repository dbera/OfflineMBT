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
 
package nl.esi.comma.project.standard.generator

import java.io.File
import java.io.FilenameFilter
import java.util.ArrayList
import java.util.List
import nl.asml.matala.product.generator.ProductGenerationMode
import nl.asml.matala.product.generator.ProductGenerator
import nl.asml.matala.product.product.Product
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.generator.cpn.CPNTemplateGenerator
import nl.esi.comma.project.standard.standardProject.FilePath
import nl.esi.comma.project.standard.standardProject.Project
import nl.esi.comma.project.standard.standardProject.TestConformanceBlock
import nl.esi.comma.testspecification.testspecification.TSMain
import org.eclipse.core.resources.IResource
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*
import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*

class TestConformanceNetGenerator  extends AbstractGenerator {
    static val CONFORMANCE_SUMMARY_SCRIPT = '''
    import json
    import sys
    
    summary_path = sys.argv[1]
    pairs = sys.argv[2:]
    results = []
    for i in range(0, len(pairs), 2):
        constraint = pairs[i]
        verdict_path = pairs[i + 1]
        with open(verdict_path, "r", encoding="utf-8") as reader:
            verdict = json.load(reader)
        results.append({
            "constraint": constraint,
            "accepted": verdict.get("accepted"),
            "explanation": None
        })
    
    with open(summary_path, "w", encoding="utf-8") as writer:
        json.dump({"results": results}, writer, indent=2)
    '''
    var Resource resource
     
    var TestConformanceBlock task
    List<Constraints> constraints

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        res.contents.filter(Project).flatMap[testConformanceBlocks].forEach[doGenerate(fsa, ctx)]
    }

    def void doGenerate(TestConformanceBlock task, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        this.task = task
        this.resource = task.eResource
        setConstraints

        if(task.tspecFile !== null) {
            var tspecResource = EcoreUtil2.getResource(resource, task.tspecFile)
            if(tspecResource === null) {
                throw new Exception(task.tspecFile + " Could not be resolved.")
            }
            var tspec = tspecResource.allContents.head
            if(tspec !== null && tspec instanceof TSMain) {
                val generatedConstraints = (new CPNTemplateGenerator).generatePSpec(
                    resource, fsa, constraints, tspec as TSMain
                )
//          generating the reachability graph from pspec    
            val verdicts = new ArrayList<Pair<String, URI>>
            for (generatedConstraint : generatedConstraints) {
                val constraintFsa =  fsa.createFolderAccess(generatedConstraint.getConstraintFolderName())
                val pspecURI = constraintFsa.getURI(generatedConstraint.getPspecFileName())
                val pspecResource = resource.resourceSet.getResource(pspecURI,true)
                
                val product = pspecResource.contents
                    .filter(Product)
                    .findFirst[specification !== null]
            
                if (product === null) {
                    throw new Exception(
                        "No product found in generated PS resource: "
                        + generatedConstraint.getPspecFileName()
                    )
                }
            
                (new ProductGenerator(ProductGenerationMode.CHECK_TEST_CONFORMANCE))
                    .doGenerate(pspecResource, fsa, ctx)
                val specName = product.specification.name

                val petriNetURI = fsa.getURI('''CPNServer/«specName»/«specName».py''')

                (new PetriNetToAbstractTspecGenerator(task.pythonExe)) 
                    .doGenerate(
                        resource.resourceSet,
                        petriNetURI,
                        constraintFsa,
                        ctx
                    )
                 
                val acceptancePyUri = constraintFsa.getURI(generatedConstraint.getAcceptancePythonFileName())
                val acceptanceJsonUri = constraintFsa.getURI(generatedConstraint.getAcceptanceJsonFileName())
                val rgJsonUri = constraintFsa.getURI("plantuml/rg.json")
                val verdictUri = constraintFsa.getURI("conformance.verdict.json")
                runAcceptanceEvaluation(acceptancePyUri, acceptanceJsonUri, rgJsonUri, verdictUri)
                verdicts.add(generatedConstraint.getConstraintFolderName() -> verdictUri)
             }
            writeConformanceSummary(fsa, verdicts)
            }
        }
    }

    // reads each constraint's verdict and writes one aggregate summary outside the per-constraint folders
    def private writeConformanceSummary(IFileSystemAccess2 fsa, List<Pair<String, URI>> verdicts) {
        fsa.generateFile("build_conformance_summary.py", CONFORMANCE_SUMMARY_SCRIPT)
        val scriptUri = fsa.getURI("build_conformance_summary.py")
        val summaryUri = fsa.getURI("conformance.summary.json")
        val pythonExe = task.pythonExe ?: 'python.exe'

        val args = new ArrayList<String>
        args.add(pythonExe)
        args.add(scriptUri.toPath)
        args.add(summaryUri.toPath)
        for (verdict : verdicts) {
            args.add(verdict.key)
            args.add(verdict.value.toPath)
        }

        val process = new ProcessBuilder(args).start()
        if (process.waitFor != 0) {
            throw new RuntimeException('Conformance summary generation failed.')
        }
    }    
    // runs the generated acceptance script and writes the verdict
    def private runAcceptanceEvaluation(URI acceptancePyUri, URI acceptanceJsonUri, URI rgJsonUri, URI verdictUri) {
        val pythonExe = task.pythonExe ?: 'python.exe'
        val process = Runtime.getRuntime().exec(#[
            pythonExe,
            acceptancePyUri.toPath,
            acceptanceJsonUri.toPath,
            rgJsonUri.toPath,
            verdictUri.toPath
        ])
        val errorOutput = new String(process.errorStream.readAllBytes())
        if (process.waitFor != 0) {
            throw new RuntimeException('Acceptance evaluation failed, see console output.'+errorOutput)
        }
    }
    def private setConstraints() {
        constraints = new ArrayList<Constraints>
        for (sourcePath : task.constraintsFiles) {
            var constrResource = getConstraintsResource(sourcePath)
            if (constrResource !== null){
                constraints.add(constrResource)
            } else {
                throw new Exception("[Test-Conformance-Task] Could not find file: " + NodeModelUtils.getNode(constrResource).text + "\n\n")
            }
        }
        getConstraintsResourcesFromDirs(task.constraintsDirs).forEach[addConstraints]
    }

    def private getConstraintsResourcesFromDirs(EList<FilePath> directories) {
        val resources = new ArrayList<Resource>
        for (location : directories) {
            var uri = resource.resolveUri(location.path)
            if(uri.isPlatform) {
                val platform = uri.toPlatformString(true)
                val IResource eclipseResource = ResourcesPlugin.workspace.root.findMember(platform)
                uri =  URI.createFileURI(eclipseResource.rawLocation.toOSString);       
            }

            val traceFiler = new FilenameFilter() {
                override accept(File dir, String name) {
                    (name.endsWith(".constraints"))
                }
            }

            val dir = new File(uri.toFileString)
            if (dir.exists && dir.isDirectory) {
                for (file : dir.listFiles(traceFiler)) {
                    val res = resource.resourceSet.getResource(URI.createFileURI(file.path), true)              
                    if(res !== null) {
                        resources.add(res)
                    } else { 
//                      errors.add("Constraints resource could not be loaded: " + file.path +".")
                    }
                }
            } else {
//              errors.add("Constraints dir did not exist or is not a directory. " + dir.path)
            }
        }
        resources
    }

    def private addConstraints(Resource res) {
        val head = res.allContents.head
        if(head instanceof Constraints) {
            constraints.add(head);
        } else {
            throw new Exception("[Test-Conformance-Task] File did not contain the Constraints syntax" + res.URI + "\n\n")             
        }
    }

    def private getConstraintsResource(String path) {
        val constraintResource = EcoreUtil2.getResource(resource, path)
        if(constraintResource === null){
            throw new Exception(constraintResource + "Constraints File Could not be resolved.")
        }
        val head = constraintResource.allContents.head
        if(head instanceof Constraints){
            return head
        } else {
            throw new Exception(constraintResource + " Did not contain the expected 'Constraints' model.")
        }
    }
}