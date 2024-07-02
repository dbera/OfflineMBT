package nl.esi.comma.constraints.ui

import java.util.HashSet
import nl.esi.comma.constraints.constraints.Constraints
import java.io.File
import org.eclipse.emf.ecore.resource.Resource
import java.io.FilenameFilter
import java.io.FileFilter
import org.eclipse.emf.common.util.URI

class ConstraintsUtilities {
	def static HashSet<Constraints> getConstraintModelFromDir(File dir, Resource context){
		var constraintsModel = new HashSet<Constraints>
		val filter = new FilenameFilter() {
			override accept(File dir, String name) {
				(name.endsWith(".constraints"))
			}
		}
		var dirfilter = new FileFilter(){
			override accept(File file) {
				var isFile = file.isFile
				if (isFile) {
					return false
				} else {
					return true
				}
			}
		}
		for (file : dir.listFiles(filter)) {
			val res = context.resourceSet.getResource(URI.createFileURI(file.path), true)
			if(res !== null) {
				constraintsModel.add(res.allContents.head as Constraints)
			}
		}
		//search nested dir, recursively
		for (file : dir.listFiles(dirfilter)) {
			constraintsModel.addAll(getConstraintModelFromDir(file, context))
		}
		return constraintsModel
	}
}