/*
 * generated by Xtext 2.19.0
 */
package nl.esi.comma.constraints


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class ConstraintsStandaloneSetup extends ConstraintsStandaloneSetupGenerated {

	def static void doSetup() {
		new ConstraintsStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
