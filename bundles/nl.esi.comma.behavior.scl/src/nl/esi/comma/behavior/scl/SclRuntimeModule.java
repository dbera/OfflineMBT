/*
 * generated by Xtext 2.25.0
 */
package nl.esi.comma.behavior.scl;

import org.eclipse.xtext.scoping.IGlobalScopeProvider;

import nl.esi.comma.types.scoping.TypesImportUriGlobalScopeProvider;

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
public class SclRuntimeModule extends AbstractSclRuntimeModule {
	@Override
	public Class<? extends IGlobalScopeProvider> bindIGlobalScopeProvider() {		
		return TypesImportUriGlobalScopeProvider.class;
	}
}