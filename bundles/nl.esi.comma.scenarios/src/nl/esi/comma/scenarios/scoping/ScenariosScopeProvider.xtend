/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.scenarios.scoping

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import nl.esi.comma.scenarios.scenarios.Scenario
import nl.esi.comma.scenarios.scenarios.ScenariosPackage
import nl.esi.comma.types.utilities.CommaUtilities
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.signature.utilities.InterfaceUtilities
import static org.eclipse.xtext.scoping.Scopes.*
/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class ScenariosScopeProvider extends AbstractScenariosScopeProvider {
	// Added DB: 16.10.2018
	override getScope(EObject context, EReference reference){	
		if(context instanceof Scenario && reference == ScenariosPackage.Literals.SCENARIO__EVENTS) {
			return scope_Event(context as Scenario, reference)
		}
				
		return super.getScope(context, reference);
	}
	
	def scope_Event(Scenario scn, EReference reference) {
		val intf = CommaUtilities::resolveProxy(scn, 
			getScope(scn, ExpressionPackage.Literals.INTERFACE_AWARE_TYPE__INTERFACE).getAllElements)
		return scopeFor(InterfaceUtilities::getAllInterfaceEvents(intf.head)
		)
	}
	
}