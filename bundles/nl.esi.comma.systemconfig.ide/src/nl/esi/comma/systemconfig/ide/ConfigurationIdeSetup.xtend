/*
 * generated by Xtext 2.19.0
 */
package nl.esi.comma.systemconfig.ide

import com.google.inject.Guice
import nl.esi.comma.systemconfig.ConfigurationRuntimeModule
import nl.esi.comma.systemconfig.ConfigurationStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class ConfigurationIdeSetup extends ConfigurationStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new ConfigurationRuntimeModule, new ConfigurationIdeModule))
	}
	
}
