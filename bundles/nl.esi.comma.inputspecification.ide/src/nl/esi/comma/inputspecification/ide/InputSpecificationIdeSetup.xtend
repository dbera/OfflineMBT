/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.inputspecification.ide

import com.google.inject.Guice
import nl.esi.comma.inputspecification.InputSpecificationRuntimeModule
import nl.esi.comma.inputspecification.InputSpecificationStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class InputSpecificationIdeSetup extends InputSpecificationStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new InputSpecificationRuntimeModule, new InputSpecificationIdeModule))
	}
	
}