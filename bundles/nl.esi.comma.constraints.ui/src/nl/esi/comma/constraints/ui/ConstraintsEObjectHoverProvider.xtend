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
package nl.esi.comma.constraints.ui

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.File
import java.util.Map
import java.util.Set
// import nl.esi.comma.constraints.constraints.Action
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.RefSequence
import nl.esi.comma.constraints.constraints.Sequence
import nl.esi.comma.constraints.constraints.Template
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import nl.esi.comma.constraints.constraints.Act

class ConstraintsEObjectHoverProvider extends DefaultEObjectHoverProvider {
	@Inject extension Provider<ResourceSet> resourceSetProvider
	protected override String getFirstLine(EObject o) {
		if (o instanceof Act) {
			var info = getActionWithData(o)
			return info
		}
		if (o instanceof Sequence) {
			var info = getAseqUsage(o)
			return info
		}
		return super.getFirstLine(o);
	}
	
	def getAseqUsage(Sequence aseq) {
		var info = "Sequence <b>" + aseq.name + "</b><br>"
		var constraintIDs = getUsageForAseqDef(aseq)
		if (constraintIDs.keySet.size > 0){
			info += "used in<br>"
			for (file : constraintIDs.keySet) {
				info += file + "<br>"
				info += "<ul>"
				for (id : constraintIDs.get(file)){
					info += "<li>Constraint Id: " + id + "</li>"
				}
				info += "</ul>"
			}
		}
		return info
	}
	
	def getActionWithData(Act o){
		var info = "Action <b>" + o.name + "</b><br>"
		var constraintIDs = getUsageForAction(o)
		if (constraintIDs.keySet.size > 0){
			info += "used in<br>"
			for (file : constraintIDs.keySet) {
				info += file + "<br>"
				info += "<ul>"
				for (id : constraintIDs.get(file)){
					info += "<li>Constraint Id: " + id + "</li>"
				}
				info += "</ul>"
			}
		}
		return info
	}
	
	def getUsageForAseqDef(Sequence aseq){
		var Map<String, Set<String>> constraintIDs = newHashMap
		var root = aseq.eContainer as Constraints
		var models = getRelatedModelsFromProject(root)
		for (constraints : models){
			var refAseq = EcoreUtil2.getAllContentsOfType(constraints, RefSequence)
			for (ref : refAseq) {
				if (ref.sequence.name !== null) {
					if (ref.sequence.name.equals(aseq.name)){
						var template = ref.eContainer.eContainer.eContainer as Template
						var URI targetURI = EcoreUtil2.getPlatformResourceOrNormalizedURI(template)
						var fileName = targetURI.lastSegment
						if (constraintIDs.get(fileName) === null){
							constraintIDs.put(fileName, newHashSet)
						}
						constraintIDs.get(fileName).add(template.name)
					}
				}
			}
		}
		return constraintIDs
	}
	
	def getUsageForAction(Act action) {
		var Map<String, Set<String>> constraintIDs = newHashMap
		var root = action.eContainer.eContainer as Constraints
		var models = getRelatedModelsFromProject(root)
		for (constraints : models){
			var refAct = EcoreUtil2.getAllContentsOfType(constraints, RefAction)
			for (ref : refAct) {
				if (ref.action.name !== null){
					if (ref.action.name.equals(action.name)){
						var template = ref.eContainer.eContainer.eContainer as Template
						var URI targetURI = EcoreUtil2.getPlatformResourceOrNormalizedURI(template)
						var fileName = targetURI.lastSegment
						if (constraintIDs.get(fileName) === null){
							constraintIDs.put(fileName, newHashSet)
						}
						constraintIDs.get(fileName).add(template.name)
					}
				}
			}
		}
		return constraintIDs
	}
	
	def getRelatedModelsFromProject(Constraints context) {
		var constraintsModel = newHashSet
		//add itself to the set
		constraintsModel.add(context)
		val platformString = context.eResource.URI.toPlatformString(true);
		val file = ResourcesPlugin.workspace.root.findMember(platformString) as IFile
		val project = file.project
		val constraintsName = context.eResource.URI.toPlatformString(true).split("/").last
		
		for (member : project.members) {
			var ext = member.getFileExtension
			if ( ext !== null && ext.equals("constraints")){
				var path = member.getLocation().toString();
				var uri = URI.createFileURI(path)
				val res = resourceSetProvider.get.getResource(uri, true)
				var model = res.allContents.head
				if (res !== null && model instanceof Constraints) {
					//consider imports
					for (imp : (model as Constraints).imports){
						var fileName = imp.importURI.split("/").last
						if (fileName.equals(constraintsName)){
							constraintsModel.add(res.allContents.head as Constraints)
						}
					}
				}
			}
			if (ext === null) {
				var uri = member.locationURI
				var dir = new File(uri)
				if (dir.exists && dir.isDirectory) {
					constraintsModel.addAll(ConstraintsUtilities.getConstraintModelFromDir(dir, context.eResource))
				}
			}
		}
		return constraintsModel
	}
	
	def getAllRootModelFromProject(Constraints context) {
		var constraintsModel = newHashSet
		val platformString = context.eResource.URI.toPlatformString(true);
		val file = ResourcesPlugin.workspace.root.findMember(platformString) as IFile
		val project = file.project

		for (member : project.members) {
			var ext = member.getFileExtension
			if ( ext !== null && ext.equals("constraints")){
				var path = member.getLocation().toString();
				var uri = URI.createFileURI(path)
				val res = resourceSetProvider.get.getResource(uri, true)
				if (res !== null && res.allContents.head instanceof Constraints) {
					constraintsModel.add(res.allContents.head as Constraints)
				}
			}
			if (ext === null) {
				var uri = member.locationURI
				var dir = new File(uri)
				if (dir.exists && dir.isDirectory) {
					constraintsModel.addAll(ConstraintsUtilities.getConstraintModelFromDir(dir, context.eResource))
				}
			}
		}
		return constraintsModel
	}
}