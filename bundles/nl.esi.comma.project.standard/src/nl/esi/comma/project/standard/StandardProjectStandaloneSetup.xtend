/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.project.standard


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class StandardProjectStandaloneSetup extends StandardProjectStandaloneSetupGenerated {

	def static void doSetup() {
		new StandardProjectStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}