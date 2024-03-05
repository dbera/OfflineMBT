package nl.esi.comma.behavior.generator.poosl

import java.util.ArrayList
import java.util.List
import nl.esi.comma.actions.actions.VariableDeclBlock
import nl.esi.comma.actions.generator.poosl.ActionsPooslGenerator
import nl.esi.comma.behavior.behavior.AbstractBehavior
import nl.esi.comma.behavior.behavior.StateMachine
import nl.esi.comma.behavior.behavior.Transition
import nl.esi.comma.behavior.behavior.TriggeredTransition
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.QUANTIFIER
import nl.esi.comma.expressions.utilities.ExpressionsUtilities
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.types.RecordTypeDecl
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.expressions.generator.poosl.CommaScope

abstract class PooslGenerator extends ActionsPooslGenerator {
	
	protected List<ExpressionQuantifier> quantifiersInMachines
	
	new(String fileName, IFileSystemAccess fsa) {
		super(fileName, fsa)
	}
	
	override determineRecordTypePrefix(RecordTypeDecl t){
		if(t.eContainer !== null && (t.eContainer instanceof Signature)){
			return '''«(t.eContainer as Signature).name»_'''
		}
		
		return ""
	}
	
	//Some variables are defined and kept in State or Env class
	//We call them global
	//Examples: global variables in interface specs
	//          variables in constraint blocks
	//          variables that are iterators in quantifiers
	//
	//Other variables are defined locally
	//Examples: variables in triggers of transitions
	//          
	//Global variables used in expressions in the following context, are just referred by NAME
	//      - init section of interface spec
	//      - init section in functional constraints blocks
	//      - conditions used in data and generic constraints
	//      - conditions in quantifiers
	//
	//Global variables used in expressions in the following contexts are accessed via the State class
	//      - Transitions in interface and component state machines
	//      - Transitions in component functional constraints
	//
	//Local variables are always referred to by names
	//
	//Quantifiers are mapped to methods in a State or Env class
	//
	//Quantifiers are called by a simple name in the context of the defining class if they are used in
	//      - init section of interface and component specs
	//      - init section of functional constraint block
	//      - conditions data and generic blocks
	//      - conditions in quantifiers
	//
	//Quantifiers are called via the State class if used in:
	//      - Transitions in any state based behavior
	
	
	override CommaScope getCommaScope(EObject o) {
		var EObject container = o.eContainer();
	
		while (! isVariableScope(container)) 
			container = container.eContainer();
		if(container instanceof VariableDeclBlock) return CommaScope::GLOBAL
		if(container instanceof ExpressionQuantifier) return CommaScope::QUANTIFIER	
		return CommaScope::TRANSITION
	}
	
	def boolean isVariableScope(EObject o){
		(o instanceof VariableDeclBlock) ||
		(o instanceof Transition) ||
		(o instanceof ExpressionQuantifier)
	}
	
	def List<ExpressionQuantifier> getQuantifiersInContainer(EObject cont){
		EcoreUtil2::getAllContentsOfType(cont, ExpressionQuantifier)
	}
	
	def List<ExpressionQuantifier> getQuantifiersInStateMachines(AbstractBehavior behavior, List<StateMachine> machines){
		var List<ExpressionQuantifier> result = new ArrayList<ExpressionQuantifier>();
		
		for(m : machines){
			result.addAll(getQuantifiersInContainer(m))
		}
		
		for(ia : behavior.initActions){
			result.addAll(getQuantifiersInContainer(ia))
		}
		
		return result
	}
	
	
	def filterQuantifierVariables(ExpressionQuantifier quantifier){
		return 
		ExpressionsUtilities::getReferredVariablesInQuantifier(quantifier).filter(p | !(p.eContainer instanceof VariableDeclBlock))
	}
	
	def CharSequence generateQuantifierMethod(ExpressionQuantifier quantifier, int index)
	{
		var parameters = filterQuantifierVariables(quantifier)
		val returnType = quantifierType(quantifier)
				
		'''
		evalQuantifier«index»(«FOR p : parameters SEPARATOR ', '»«IF p.getCommaScope == CommaScope::TRANSITION»«TVAR_NAME_PREFIX»«ELSE»«QVAR_NAME_PREFIX»«ENDIF»«p.name» : «toPOOSLType(p.type)»«ENDFOR») : «returnType»
			|commaIteratorResult : «returnType», commaCollection : «COMMA_PREFIX»Vector, commaIndex : Integer, «QVAR_NAME_PREFIX»«quantifier.iterator.name» : «toPOOSLType(quantifier.iterator.type)»|
			«IF quantifier.quantifier == QUANTIFIER::EXISTS»
			«generateQuantifierBodyForExists(quantifier)»
			«ELSE»
			«IF quantifier.quantifier == QUANTIFIER::DELETE»
			«generateQuantifierBodyForDelete(quantifier)»
			«ELSE»
			«generateQuantifierBodyForForAll(quantifier)»
			«ENDIF»
			«ENDIF»
			return commaIteratorResult
			
		'''
	}
	
	def quantifierType(ExpressionQuantifier exp){
		if(exp.quantifier == QUANTIFIER::DELETE){
			'''«COMMA_PREFIX»Vector'''
		}
		else{
			'''Boolean'''
		}
	}
	
	def CharSequence generateQuantifierBodyForExists(ExpressionQuantifier quantifier)
		'''
		commaIteratorResult := false;
		commaCollection := «generateExpression(quantifier.collection)»; 
		commaIndex := 1;
		while commaIndex <= commaCollection size do
			«QVAR_NAME_PREFIX»«quantifier.iterator.name» := commaCollection get(commaIndex);
			if («generateExpression(quantifier.condition)») then
				commaIteratorResult := true
			fi;
			commaIndex := commaIndex + 1
		od;
		'''
		
	def CharSequence generateQuantifierBodyForForAll(ExpressionQuantifier quantifier)
		'''
		commaIteratorResult := true;
		commaCollection := «generateExpression(quantifier.collection)»;
		commaIndex := 1;
		while commaIndex <= commaCollection size do
			«QVAR_NAME_PREFIX»«quantifier.iterator.name» := commaCollection get(commaIndex);
			if («generateExpression(quantifier.condition)») not then
				commaIteratorResult := false
			fi;
			commaIndex := commaIndex + 1
		od;
		'''
		
	def CharSequence generateQuantifierBodyForDelete(ExpressionQuantifier quantifier)
		'''
		commaIteratorResult := new(«COMMA_PREFIX»Vector) init;
		commaCollection := «generateExpression(quantifier.collection)»;
		commaIndex := 1;
		while commaIndex <= commaCollection size do
			«QVAR_NAME_PREFIX»«quantifier.iterator.name» := commaCollection get(commaIndex);
			if («generateExpression(quantifier.condition)») not then
				commaIteratorResult := commaIteratorResult add(«QVAR_NAME_PREFIX»«quantifier.iterator.name»)
			fi;
			commaIndex := commaIndex + 1
		od;
		'''
	
	def generateImportsForInterfaces(){
		'''import "records.poosl"'''
	}
	
	def Signature getInterface(TriggeredTransition t) {
		if(t !== null) t.trigger.eContainer as Signature else null		
	}
	
	def dispatch CharSequence generateExpression(ExpressionQuantifier expr){
		var parameters = filterQuantifierVariables(expr)
		'''«IF getCommaScope(expr) != CommaScope::TRANSITION»self «ELSE»stateOfDecisionClass «ENDIF»evalQuantifier«quantifiersInMachines.indexOf(expr)»(«FOR p : parameters SEPARATOR ', '»«IF getCommaScope(p) == CommaScope::QUANTIFIER»«QVAR_NAME_PREFIX»«ELSE»«TVAR_NAME_PREFIX»«ENDIF»«p.name»«ENDFOR»)'''
    }
    
}

