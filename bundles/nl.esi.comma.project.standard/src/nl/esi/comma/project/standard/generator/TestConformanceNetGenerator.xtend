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

import org.eclipse.emf.ecore.resource.Resource
import java.util.List
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.project.standard.standardProject.TestConformanceBlock
import org.eclipse.xtext.generator.IGeneratorContext
import nl.esi.comma.project.standard.standardProject.Project
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.AbstractGenerator
import java.util.ArrayList
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.emf.common.util.EList
import nl.esi.comma.project.standard.standardProject.FilePath
import org.eclipse.core.resources.IResource
import org.eclipse.core.resources.ResourcesPlugin
import java.io.FilenameFilter
import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.EcoreUtil2

import static extension nl.esi.xtext.common.lang.utilities.EcoreUtil3.*
import nl.esi.comma.constraints.generator.ConstraintsAnalysisAndGeneration
import nl.esi.comma.testspecification.testspecification.TSMain

class TestConformanceNetGenerator  extends AbstractGenerator {
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
                (new ConstraintsAnalysisAndGeneration).generatePSpec(
                    resource, fsa, constraints, tspec as TSMain
                )
            }
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