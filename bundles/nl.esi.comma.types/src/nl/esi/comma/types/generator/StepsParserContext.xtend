package nl.esi.comma.types.generator

import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.util.CancelIndicator
import java.util.List

class StepsParserContext implements IGeneratorContext {
	
	public String stepsFilePath
	public List<String> testContext
	public String output
	
	new(String stepsFilePath, List<String> testContext, String output) {
		this.stepsFilePath = stepsFilePath
		this.testContext = testContext
		this.output = output
	}
	
	override getCancelIndicator() {
		CancelIndicator.NullImpl
	}
	
}