/*
 * generated by Xtext 2.12.0
 */
package nl.esi.comma.inputspecification.validation

import java.util.ArrayList
import java.util.HashMap
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
//import nl.esi.comma.behavior.interfaces.interfaceDefinition.InterfaceDefinition
import nl.esi.comma.behavior.utilities.StateMachineUtilities
//import nl.esi.comma.inputspecification.inputSpecification.Body
//import nl.esi.comma.inputspecification.inputSpecification.EventData
import nl.esi.comma.inputspecification.inputSpecification.InputSpecificationPackage
import nl.esi.comma.inputspecification.inputSpecification.Main
import nl.esi.comma.signature.interfaceSignature.Command
import nl.esi.comma.signature.interfaceSignature.DIRECTION
import nl.esi.comma.signature.interfaceSignature.InterfaceEvent
import nl.esi.comma.signature.interfaceSignature.Signal
import nl.esi.comma.types.types.Import
import nl.esi.comma.types.types.TypesPackage
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.validation.Check
//import nl.esi.comma.systemconfig.configuration.FeatureDefinition

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class InputSpecificationValidator extends AbstractInputSpecificationValidator {
	
	@Check
	override checkImportForValidity(Import imp){
		if(! EcoreUtil2.isValidUri(imp, URI.createURI(imp.importURI)))
			error("Invalid resource", imp, TypesPackage.eINSTANCE.import_ImportURI)
		else{
			/*val Resource r = EcoreUtil2.getResource(imp.eResource, imp.importURI)
			if(! (r.allContents.head instanceof InterfaceDefinition ||
				r.allContents.head instanceof FeatureDefinition
			))
				error("The imported resource is not an interface definition or a feature definition.", imp, TypesPackage.eINSTANCE.import_ImportURI)
		}*/
		
		}
	}
}