package nl.esi.comma.types.generator

import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.util.CancelIndicator

class CmdLineContext implements IGeneratorContext {

	final static String context = "CMD_LINE"

	def String getContextString() {
		context
	}

	override getCancelIndicator() {
		CancelIndicator.NullImpl
	}
}
