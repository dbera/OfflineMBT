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
import nl.esi.comma.constraints.constraints.ActSequenceDef
import nl.esi.comma.constraints.constraints.Action
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.RefActSequence
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.RefStepSequence
import nl.esi.comma.constraints.constraints.StepSequenceDef
import nl.esi.comma.constraints.constraints.Templates
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider

class ConstraintsEObjectHoverProvider extends DefaultEObjectHoverProvider {
	@Inject extension Provider<ResourceSet> resourceSetProvider
	protected override String getFirstLine(EObject o) {
		if (o instanceof Action) {
			var info = getActionWithData(o)
			return info
		}
		if (o instanceof StepSequenceDef) {
			var info = getSseqUsage(o)
			return info
		}
		if (o instanceof ActSequenceDef) {
			var info = getAseqUsage(o)
			return info
		}
		return super.getFirstLine(o);
	}
	
	def getAseqUsage(ActSequenceDef aseq) {
		var info = "ActSequenceDef <b>" + aseq.name + "</b><br>"
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
	
	def getSseqUsage(StepSequenceDef sseq){
		var info = "StepSequenceDef <b>" + sseq.name + "</b><br>"
		var constraintIDs = getUsageForSseqDef(sseq)
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
	
	def getActionWithData(Action o){
		var info = "Action <b>" + o.name + "</b><br>"
		if (o.data.size !== 0) {
			var index = 0
			info += "Data<br>"
			var heading = o.data.get(0).heading
			info += "  <b>"
			for(cell : heading.cells){
				info += cell.value
			}
			info += "|</b><br>"
			for(row : o.data.get(0).rows){
				info += "|" + index
				for(cell : row.cells){
					info += cell.value
				}
				info += "|<br>"
				index++
			}
		}
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
	
	def getUsageForAseqDef(ActSequenceDef aseq){
		var Map<String, Set<String>> constraintIDs = newHashMap
		var root = aseq.eContainer as Constraints
		var models = getRelatedModelsFromProject(root)
		for (constraints : models){
			var refAseq = EcoreUtil2.getAllContentsOfType(constraints, RefActSequence)
			for (ref : refAseq) {
				if (ref.seq.name !== null) {
					if (ref.seq.name.equals(aseq.name)){
						var template = ref.eContainer.eContainer.eContainer as Templates
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
	
	def getUsageForSseqDef(StepSequenceDef sseq){
		var Map<String, Set<String>> constraintIDs = newHashMap
		var root = sseq.eContainer as Constraints
		var models = getRelatedModelsFromProject(root)
		for (constraints : models){
			var refSseq = EcoreUtil2.getAllContentsOfType(constraints, RefStepSequence)
			for (ref : refSseq) {
				if (ref.seq.name !== null) {
					if (ref.seq.name.equals(sseq.name)){
						var template = ref.eContainer.eContainer.eContainer as Templates
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
	
	def getUsageForAction(Action action) {
		var Map<String, Set<String>> constraintIDs = newHashMap
		var root = action.eContainer.eContainer as Constraints
		var models = getRelatedModelsFromProject(root)
		for (constraints : models){
			var refAct = EcoreUtil2.getAllContentsOfType(constraints, RefAction)
			for (ref : refAct) {
				if (ref.act.act.name !== null){
					if (ref.act.act.name.equals(action.name)){
						var template = ref.eContainer.eContainer.eContainer as Templates
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