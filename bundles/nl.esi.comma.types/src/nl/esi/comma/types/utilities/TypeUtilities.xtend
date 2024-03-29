package nl.esi.comma.types.utilities

import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.VectorTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import java.util.List
import java.util.ArrayList
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.RecordField
import nl.esi.comma.types.types.EnumElement
import nl.esi.comma.types.types.MapTypeDecl
import nl.esi.comma.types.types.MapTypeConstructor

class TypeUtilities {
	/*
	 * Methods for getting the type object from a type. 
	 * Type is either a reference to a type declaration or an inline type constructor
	 */
	def static TypeObject getTypeObject(Type t) {
		if(t instanceof TypeReference){
			t.type
		}else{
			t as TypeObject
		}
	}
	
	/*
	 * Some useful predicates
	 */
	def static boolean isVectorType(Type t){
		return t.getTypeObject.isVectorType
	}
	
	def static boolean isVectorType(TypeObject t){
		t instanceof VectorTypeConstructor || t instanceof VectorTypeDecl
	}
	
	def static boolean isRecordType(Type t){
		t.getTypeObject instanceof RecordTypeDecl
	}
	
	def static boolean isStructuredType(Type t){
		val to = t.getTypeObject
		to instanceof VectorTypeConstructor || 
		to instanceof VectorTypeDecl || 
		to instanceof RecordTypeDecl ||
		to instanceof MapTypeDecl ||
		to instanceof MapTypeConstructor
	}
	
	def static boolean isMapType(Type t){
		return t.getTypeObject.isMapType
	}
	
	def static boolean isMapType(TypeObject t){
		t instanceof MapTypeConstructor || t instanceof MapTypeDecl
	}
	
	def static TypeObject getKeyType(TypeObject t){
		if(t instanceof MapTypeConstructor) return t.type
		if(t instanceof MapTypeDecl) return t.constructor.type
		
		return null
	}
	
	def static TypeObject getValueType(TypeObject t){
		if(t instanceof MapTypeConstructor) return t.valueType.typeObject
		if(t instanceof MapTypeDecl) return t.constructor.valueType.typeObject
		
		return null
	}
	
	def static dispatch boolean usesMaps(TypeReference t){
		if(t?.type === null) return false
		usesMaps(t.type)
	}
	
	def static dispatch boolean usesMaps(SimpleTypeDecl t){false}
	
	def static dispatch boolean usesMaps(MapTypeDecl t){true}
	
	def static dispatch boolean usesMaps(EnumTypeDecl t){false}
	
	def static dispatch boolean usesMaps(RecordTypeDecl t){
		if(t.parent !== null){t.parent.usesMaps}else{false} ||
		t.fields.map[type].exists[it.usesMaps]
	}
	
	def static dispatch boolean usesMaps(VectorTypeDecl t){
		t.constructor.usesMaps
	}
	
	def static dispatch boolean usesMaps(VectorTypeConstructor t){
		t.type.usesMaps
	}
	
	def static dispatch boolean usesMaps(MapTypeConstructor t){
		true
	}
	
	//The check for array is needed for the generation to C++.
	//An array is a vector type with size of the first dimension > 0
	def static boolean isArray(Type t){
		var to = t.getTypeObject
		
		if(to instanceof VectorTypeConstructor)
			return to.dimensions.get(0).size != 0
			
		if(to instanceof VectorTypeDecl)
			return to.constructor.dimensions.get(0).size != 0
			
		return false
	}
	
	def static boolean isVoid(Type t){
		val to = t.getTypeObject
		
		if(to instanceof SimpleTypeDecl){
			return to.name.equals('void')
		}
		return false
	}
	
	def static boolean isPredefinedType(TypeDecl t){
		if(t instanceof SimpleTypeDecl)
			return isPredefinedType(t.name)
		else
			return false
	}
	
	def static boolean isPredefinedType(Type t){
		if(t instanceof TypeReference){
			return isPredefinedType(t.type)
		}
		false
	}
	
	def static boolean isPredefinedType(String typeName){
		return (typeName.equals('int') ||
			    typeName.equals('real') ||
			    typeName.equals('bool') ||
			    typeName.equals('string') ||
			    typeName.equals('void') ||
			    typeName.equals('any')) ||
			    typeName.equals('bulkdata') ||
			    typeName.equals('id')
	}
	
	/*
	 * Utility method to get the base type of a vector. Resolves any possible indirections
	 */
	def static dispatch TypeDecl getBaseType(VectorTypeConstructor vtc){
		if(vtc.type instanceof VectorTypeDecl) {
			return vtc.type.getBaseType
		}
		else{return vtc.type}
	}
	
	def static dispatch TypeDecl getBaseType(VectorTypeDecl vtd){
		vtd.constructor.getBaseType
	}	
	
	def static dispatch int getFirstDimension(VectorTypeConstructor vtc){
		vtc.dimensions.get(0).size
	}
	
	def static dispatch int getFirstDimension(VectorTypeDecl vtd){
		getFirstDimension(vtd.constructor)
	}
	
	static def List<RecordTypeDecl> getAllParents(RecordTypeDecl rt){
		var List<RecordTypeDecl> result = new ArrayList<RecordTypeDecl>()
		
		var current = rt.parent
		
		while(current !== null && !result.contains(current)){
			result.add(current)
			current = current.parent
		}
		
		result
	}
	
	def static List<RecordField> getAllFields(RecordTypeDecl rt){
		var result = new ArrayList<RecordField>()
		if(rt.parent !== null && ! rt.allParents.contains(rt)){
			result.addAll(rt.parent.allFields)
		}
		
		result.addAll(rt.fields)
		
		result
	}
	
	def static EnumElement getEnumElementByValue(EnumTypeDecl enumType, int value){
		var currentValue = -1
		for(l : enumType.literals){
			if(l.value === null){
				currentValue++
			}
			else{
				currentValue = l.value.value
			}
			if(currentValue == value) return l
		}
		return null
	}
}