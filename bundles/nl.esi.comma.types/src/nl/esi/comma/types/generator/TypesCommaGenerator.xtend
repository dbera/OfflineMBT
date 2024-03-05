package nl.esi.comma.types.generator

import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.utilities.TypeUtilities
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.MapTypeDecl

/*
 * This class provides methods that map ComMA types to their ComMA text representation
 * In principle, the corresponding text nodes can be used but sometimes fully qualified names 
 * should be given in places where short names are used in a source model.
 * 
 * This class is mostly used when .traces models are generated from scenarios
 */
 
 //TODO check if this functionality can be used in the capture to trace transformation
class TypesCommaGenerator {
	
	def dispatch CharSequence typeToComMASyntax(TypeReference t){
		typeToComMASyntax(t.type)
	}
	
	def dispatch CharSequence typeToComMASyntax(TypeDecl t){
		generateTypeName(t)
	}
	
	def dispatch CharSequence typeToComMASyntax(VectorTypeConstructor t){
		'''«typeToComMASyntax(t.type)»«FOR d : t.dimensions»[]«ENDFOR»'''
	}
	
	def dispatch CharSequence typeToComMASyntax(MapTypeConstructor t){
		'''map<«typeToComMASyntax(t.type)», «typeToComMASyntax(t.valueType)»>'''
	}
	
	//classes can override this method to prefix with, for example, interface name
	def CharSequence generateTypeName(TypeDecl t){
		t.name
	}
	
	def dispatch CharSequence generateDefaultValue(TypeReference t){
		generateDefaultValue(t.type)
	}
	
	def dispatch CharSequence generateDefaultValue(SimpleTypeDecl t){
		if(t.name.equals("int")) return '''0'''
		if(t.name.equals("real")) return '''0.0'''
		if(t.name.equals("bool")) return '''true'''
		if(t.name.equals("string")) return '''""'''
		
		""
	}
	
	def dispatch CharSequence generateDefaultValue(EnumTypeDecl t){
		typeToComMASyntax(t) + "::" + t.literals.get(0).name
	}
	
	def dispatch CharSequence generateDefaultValue(RecordTypeDecl  t){
		'''«typeToComMASyntax(t)»{«FOR f : TypeUtilities::getAllFields(t) SEPARATOR ', '»«f.name» = «generateDefaultValue(f.type)»«ENDFOR»}'''
	}
		
	def dispatch CharSequence generateDefaultValue(VectorTypeDecl t){
		'''<«typeToComMASyntax(t)»>[]'''
	}
	
	def dispatch CharSequence generateDefaultValue(VectorTypeConstructor t){
		'''<«typeToComMASyntax(t)»>[]'''
	}
	
	def dispatch CharSequence generateDefaultValue(MapTypeDecl t){
		'''<«typeToComMASyntax(t)»>{}'''
	}
	
	def dispatch CharSequence generateDefaultValue(MapTypeConstructor t){
		'''<«typeToComMASyntax(t)»>{}'''
	}
}