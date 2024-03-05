package nl.esi.comma.types.generator

import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.util.CancelIndicator

class SpecDiffContext implements IGeneratorContext {
	
	public String oriFeaturePath
	public String updFeaturePath
	public int sensitivity
	
	new(String oriFeaturePath, String updFeaturePath, int sensitivity){
		this.oriFeaturePath = oriFeaturePath
		this.updFeaturePath = updFeaturePath
		this.sensitivity = sensitivity
	}
	
	override getCancelIndicator() {
		CancelIndicator.NullImpl
	}
	
}