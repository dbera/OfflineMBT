package nl.esi.comma.constraints.ui

import com.google.inject.Inject
import com.google.inject.Provider
import java.io.File
import java.util.Map
import java.util.Set
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.RefStep
import nl.esi.comma.constraints.constraints.Templates
import nl.esi.comma.steps.step.StepAction
import nl.esi.comma.steps.step.Steps
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider

class StepsEObjectHoverProvider extends DefaultEObjectHoverProvider {
	@Inject extension Provider<ResourceSet> resourceSetProvider
	protected override String getFirstLine(EObject o) {
		if (o instanceof StepAction){
			var info = getStepUsage(o)
			return info
		}
		return super.getFirstLine(o);
	}
	
	def getStepUsage(StepAction step) {
		var info = "StepAction <b>" + step.name + "</b><br>"
		var constraintIDs = getUsageForStep(step)
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
	
	def getUsageForStep(StepAction action) {
		var Map<String, Set<String>> constraintIDs = newHashMap
		var models = newHashSet
		if (action.eContainer.eContainer instanceof Steps){
			var root = action.eContainer.eContainer as Steps
			models = getAllRootModelFromProject(root)
		} else {
			var root = action.eContainer.eContainer.eContainer as Steps
			models = getAllRootModelFromProject(root)
		} 
		for (constraints : models){
			var refStep = EcoreUtil2.getAllContentsOfType(constraints, RefStep)
			for (ref : refStep) {
				if (ref.step.name.equals(action.name)){
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
		return constraintIDs
	}
	
	def getAllRootModelFromProject(Steps context) {
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