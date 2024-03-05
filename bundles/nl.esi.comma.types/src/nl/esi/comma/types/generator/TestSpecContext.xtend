package nl.esi.comma.types.generator

import org.eclipse.xtext.generator.IGeneratorContext
import java.nio.file.Path

class TestSpecContext implements IGeneratorContext {
	
	public Path tspecPath
	
	new(Path tspecPath){
		this.tspecPath = tspecPath
	}
	
	override getCancelIndicator() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}