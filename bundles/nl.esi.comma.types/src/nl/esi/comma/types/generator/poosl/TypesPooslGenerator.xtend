package nl.esi.comma.types.generator.poosl

import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.types.generator.CommaGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import nl.esi.comma.types.types.RecordField

import static extension nl.esi.comma.types.utilities.TypeUtilities.*
import nl.esi.comma.types.types.MapTypeDecl
import nl.esi.comma.types.types.MapTypeConstructor

abstract class TypesPooslGenerator extends CommaGenerator {
		
	protected static final String RECORD_FIELD_NAME_PREFIX = "commaRF_"
	protected static final String COMMA_PREFIX = "C" //all POOSL class names start with C
	public static final String EXT = ".poosl"
	
	new(String fileName, IFileSystemAccess fsa) {
		super(fileName, fsa)
	}
	
	/*
	 * Default POOSL values per type
	 */
	def dispatch CharSequence generateDefaultValue(SimpleTypeDecl t){
		if(t.name.equals('int')) return '''0'''
		if(t.name.equals('bool')) return '''true'''
		if(t.name.equals('string')) return '''""'''
		if(t.name.equals('real')) return '''0.0f'''
		if(t.name.equals('bulkdata')) return '''new(«COMMA_PREFIX»BulkData) setSize(0)'''
		if(t.name.equals('id')) return '''""'''
		
		return '''nil'''
	}
	
	def dispatch CharSequence generateDefaultValue(EnumTypeDecl t)
	'''new(«COMMA_PREFIX»EnumerationValue) init setValue(0) setLiteral("«t.name»::«t.literals.get(0).name»")'''
	
	def dispatch CharSequence generateDefaultValue(TypeReference t)
	'''«generateDefaultValue(t.type)»'''
	
	def dispatch CharSequence generateDefaultValue(RecordTypeDecl t) 
	'''new(«determineRecordTypePrefix(t)»«t.name») «FOR f : t.getAllFields»set_«f.name»(«generateDefaultValue(f.type)») «ENDFOR»'''
	
	def dispatch CharSequence generateDefaultValue(VectorTypeDecl t) '''new(«COMMA_PREFIX»Vector) init'''
	
	def dispatch CharSequence generateDefaultValue(VectorTypeConstructor t) '''new(«COMMA_PREFIX»Vector) init'''
	
	def dispatch CharSequence generateDefaultValue(MapTypeDecl t) '''new(Map) clear'''
	
	def dispatch CharSequence generateDefaultValue(MapTypeConstructor t) '''new(Map) clear'''
	
	/*
	 * Mappings of ComMA types to POOSL types
	 */
	def dispatch CharSequence toPOOSLType(EnumTypeDecl t)
 	'''«COMMA_PREFIX»EnumerationValue'''	

	def dispatch CharSequence toPOOSLType(SimpleTypeDecl t){
		if(t.name.equals('int')) return '''Integer'''
		if(t.name.equals('bool')) return '''Boolean'''
		if(t.name.equals('string')) return '''String'''
		if(t.name.equals('real')) return '''Float'''
		if(t.name.equals('bulkdata')) return '''«COMMA_PREFIX»BulkData''' 
		if(t.name.equals('id')) return '''String'''
		
		return '''Object'''
	}
		
	def dispatch CharSequence toPOOSLType(TypeReference t)
	'''«toPOOSLType(t.type)»'''
	
	def dispatch CharSequence toPOOSLType(RecordTypeDecl t)'''«determineRecordTypePrefix(t)»«t.name»'''
	
	def dispatch CharSequence toPOOSLType(VectorTypeDecl t) '''«COMMA_PREFIX»Vector'''
	
	def dispatch CharSequence toPOOSLType(VectorTypeConstructor t) '''«COMMA_PREFIX»Vector'''
	
	def dispatch CharSequence toPOOSLType(MapTypeDecl t) '''Map'''
	
	def dispatch CharSequence toPOOSLType(MapTypeConstructor t) '''Map'''
	
	def determineRecordTypePrefix(RecordTypeDecl t){
		return ""
	}
	
	/*
	 * ComMA records are transformed to POOSL data classes
	 */
	def toRecordDataClass(RecordTypeDecl t) 
	'''
	«IF t.parent === null»
	data class «recordDataClassName(t)» 
	«ELSE»
	data class «recordDataClassName(t)» extends «recordDataClassName(t.parent)»
	«ENDIF»
	variables
		«FOR f : t.fields»
		«recordFieldVarName(f)» : «toPOOSLType(f.type)»
		«ENDFOR»
	methods
		«FOR f : t.fields»
		get_«f.name» : «toPOOSLType(f.type)»
			return «recordFieldVarName(f)»
		
		set_«f.name»(i : «toPOOSLType(f.type)») : «recordDataClassName(t)»
			«recordFieldVarName(f)» := i;
			return self
		
		«ENDFOR»
		match(o : Object) : Boolean
			if (o = nil) | (o isOfType("«recordDataClassName(t)»") not) then
				return false
			else
				return «FOR f : t.fields SEPARATOR ' & '»(«recordFieldVarName(f)» = o get_«f.name»)«ENDFOR»«IF t.parent !== null» & (self ^match(o))«ENDIF»
			fi
			
		«IF t.parent === null»
		= (o : Object) : Boolean
			return self match(o)
			
		«ENDIF»
	'''
	
	def recordDataClassName(RecordTypeDecl t)
	'''«determineRecordTypePrefix(t)»«t.name»'''	
	
	def recordFieldVarName(RecordField f)
	'''«RECORD_FIELD_NAME_PREFIX»«f.name»'''
}