/*
 * generated by Xtext 2.10.0
 */
package nl.esi.comma.expressions.scoping

import java.util.ArrayList
import java.util.List
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.Field
import nl.esi.comma.expressions.validation.ExpressionValidator
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.utilities.TypeUtilities
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference

import static org.eclipse.xtext.scoping.Scopes.*
import nl.esi.comma.types.utilities.CommaUtilities

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class ExpressionScopeProvider extends AbstractExpressionScopeProvider {
	
	override getScope(EObject context, EReference reference){
		if(context instanceof ExpressionEnumLiteral && reference == ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__LITERAL) 
			return scope_ExpressionEnumLiteral_literal(context as ExpressionEnumLiteral, reference)
				
		if(context instanceof Field && reference == ExpressionPackage.Literals.FIELD__RECORD_FIELD)
			return scope_Field_recordField(context as Field, reference)
			
		if(context instanceof ExpressionRecordAccess && reference == ExpressionPackage.Literals.EXPRESSION_RECORD_ACCESS__FIELD)
			return scope_ExpressionRecordAccess_field(context as ExpressionRecordAccess, reference)
			
		if (reference.name.equals("type")) {
			val interfaces = context.eClass.EAllReferences.filter(sf|sf.name.equals("interface"))
			if (!interfaces.empty) {
				val EReference iRef = interfaces.get(0)
				val Signature i = context.eGet(iRef) as Signature
				return scope_forType(context, i, reference)
			}
		}
			
		return super.getScope(context, reference);
	}
	
	
	def scope_ExpressionEnumLiteral_literal(ExpressionEnumLiteral context, EReference ref){      
       return scopeFor(context.type.literals)
	}
	
	def scope_Field_recordField(Field context, EReference ref){
		return scopeFor(TypeUtilities::getAllFields((context.eContainer as ExpressionRecord).type))
	}
	
	def scope_ExpressionRecordAccess_field(ExpressionRecordAccess context, EReference ref){
		var validator = new ExpressionValidator()
		var TypeObject recordType = validator.typeOf(context.record)
		
		if(recordType instanceof RecordTypeDecl){
			return scopeFor(TypeUtilities::getAllFields(recordType))
		}
		else{
			//This leads to a non-resolved reference that will be detected by the validator
			super.getScope(context, ref)
		}	
	}
	
	def scope_forType(EObject context, Signature i, EReference ref){
		if(i !== null) return scopeFor(i.types)
		var List<TypeDecl> types = new ArrayList<TypeDecl>
				
		for(i1 : findVisibleInterfaces(context)) {
			types.addAll(i1.types);
		}
		return scopeFor(types, super.getScope(context, ref))
	}
	
	def List<Signature> findVisibleInterfaces(EObject context){
		CommaUtilities::resolveProxy(context,
			getScope(context, ExpressionPackage.Literals.INTERFACE_AWARE_TYPE__INTERFACE).allElements)
	}
}