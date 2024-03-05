package nl.esi.comma.types.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

abstract class CommaGenerator extends AbstractGenerator{
	
	final protected String fileName;	
	final protected IFileSystemAccess fsa;

	new(String fileName, IFileSystemAccess fsa) {
		this.fileName = fileName
		this.fsa = fsa
	}
	
	def generateFile(CharSequence content) {
		fsa.generateFile(fileName, content)
	}
	
	def generate() {
		fsa.generateFile(fileName, content)
	}
	
	def CharSequence getContent() {
		//do nothing
	}
	
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		//do nothing
	}
	
}