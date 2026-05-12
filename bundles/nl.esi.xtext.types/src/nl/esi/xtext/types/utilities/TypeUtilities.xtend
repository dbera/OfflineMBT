/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.types.utilities

import java.math.BigDecimal
import java.math.BigInteger
import java.util.ArrayList
import java.util.List
import nl.esi.xtext.common.lang.base.ModelContainer
import nl.esi.xtext.types.BasicTypes
import nl.esi.xtext.types.types.EnumElement
import nl.esi.xtext.types.types.EnumTypeDecl
import nl.esi.xtext.types.types.MapTypeConstructor
import nl.esi.xtext.types.types.MapTypeDecl
import nl.esi.xtext.types.types.RecordField
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.SimpleTypeDecl
import nl.esi.xtext.types.types.Type
import nl.esi.xtext.types.types.TypeDecl
import nl.esi.xtext.types.types.TypeObject
import nl.esi.xtext.types.types.TypeReference
import nl.esi.xtext.types.types.TypesFactory
import nl.esi.xtext.types.types.VectorTypeConstructor
import nl.esi.xtext.types.types.VectorTypeDecl
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil

class TypeUtilities {
	/*
	 * Methods for getting the type object from a type. 
	 * Type is either a reference to a type declaration or an inline type constructor
	 */
	def static TypeObject getTypeObject(Type t) {
		return if (t instanceof TypeReference) {
			t.type
		} else {
			t as TypeObject
		}
	}
	
	def static Type asType(TypeObject t) {
        return if (t instanceof TypeDecl) {
            TypesFactory.eINSTANCE.createTypeReference => [
                type = t
            ]
        } else {
            t as Type
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
		t.getTypeObject.isRecordType
	}
	
    def static boolean isRecordType(TypeObject t){
        t instanceof RecordTypeDecl
    }

    def static boolean isEnumType(Type t) {
        return t.getTypeObject.isEnumType
    }

    def static boolean isEnumType(TypeObject t) {
        t instanceof EnumTypeDecl
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
			    typeName.equals('any'))
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

    def static dispatch TypeObject getElementType(VectorTypeConstructor vtc) {
        if (vtc.getDimensions().size() > 1) {
            return EcoreUtil.copy(vtc) => [
                dimensions.removeLast
            ]
        } else {
            return vtc.type
        }
    }

    def static dispatch TypeObject getElementType(VectorTypeDecl vtd) {
        vtd.constructor.elementType
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

    def static RecordTypeDecl getRecordType(RecordField rf) {
        return rf.eContainer as RecordTypeDecl
    }
	
	def static EnumElement getEnumElementByValue(EnumTypeDecl enumType, int value){
		var currentValue = -1
		for(l : enumType.literals){
			if(l.value === null){
				currentValue++
			}
			else{
				currentValue = l.value
			}
			if(currentValue == value) return l
		}
		return null
	}
	
   def static boolean identical(TypeObject t1, TypeObject t2) {
        if(t1 === null || t2 === null) return false

        if (t1 instanceof SimpleTypeDecl)
            if (t2 instanceof SimpleTypeDecl)
                return t1.name.equals(t2.name)

        if (t1 instanceof VectorTypeConstructor)
            if (t2 instanceof VectorTypeConstructor) {
                if(!t1.type.identical(t2.type)) return false
                if(t1.dimensions.size != t2.dimensions.size) return false
                for (i : 0 ..< t1.dimensions.size) {
                    if(t1.dimensions.get(i).size != t2.dimensions.get(i).size) return false
                }
                return true
            }

        if (t1 instanceof MapTypeConstructor)
            if (t2 instanceof MapTypeConstructor) {
                return t1.keyType.identical(t2.keyType) && t1.valueType.typeObject.identical(t2.valueType.typeObject)
            }

        t1 === t2
    }

    def static boolean subTypeOf(TypeObject subType, TypeObject baseType) {
        if(subType === null || baseType === null) return false
        if(subType.synonym(baseType)) return true // reflexive case
        if(subType.identical(BasicTypes.anyType)) return true // any is subtype of all types
        if (subType instanceof RecordTypeDecl && baseType instanceof RecordTypeDecl) // record type subtyping
            return getAllParents(subType as RecordTypeDecl).contains(baseType)

        if (subType instanceof VectorTypeConstructor) {
            if (baseType instanceof VectorTypeConstructor) {
                if(!subType.type.subTypeOf(baseType.type)) return false
                if(subType.dimensions.size != baseType.dimensions.size) return false
                for (i : 0 ..< subType.dimensions.size) {
                    if(subType.dimensions.get(i).size != baseType.dimensions.get(i).size) return false
                }
                return true
            }
        }
        if (subType instanceof MapTypeConstructor) {
            if (baseType instanceof MapTypeConstructor) {
                if(!subType.type.subTypeOf(baseType.type)) return false
                if(!getValueType(subType).subTypeOf(getValueType(baseType))) return false
                return true
            }
        }
        return false
    }

    def static boolean synonym(TypeObject t1, TypeObject t2) {
        if(t1 === null || t2 === null) return false
        if(t1.identical(t2)) return true // reflexive case
        if (t1 instanceof SimpleTypeDecl)
            if (t2 instanceof SimpleTypeDecl) {
                return (t1.base.identical(t2)) || (t2.base.identical(t1)) || (t1.base.identical(t2.base))
            }
        false
    }

    def static String getTypeName(Type type) {
        type.typeObject.typeName
    }

    def static String getTypeName(TypeObject type) {
        if (type === null){
            return "null"
        }
        return switch (type) {
            TypeDecl: type.name
            VectorTypeConstructor: '''«type.type.name»«FOR dim : type.dimensions»[]«ENDFOR»'''
            MapTypeConstructor: '''map<«type.type.name»,«type.valueType.typeName»>'''
        }
    }

    def static dispatch VectorTypeConstructor vectorOf(TypeDecl td) {
        val vtc = TypesFactory.eINSTANCE.createVectorTypeConstructor
        vtc.dimensions += TypesFactory.eINSTANCE.createDimension
        vtc.type = td
        return vtc
    }

    def static dispatch VectorTypeConstructor vectorOf(VectorTypeDecl vtd) {
        val vtc = EcoreUtil.copy(vtd.constructor)
        vtc.dimensions += TypesFactory.eINSTANCE.createDimension
        return vtc
    }

    def static MapTypeConstructor mapOf(TypeDecl keyType, TypeDecl valueType) {
        val mtc = TypesFactory.eINSTANCE.createMapTypeConstructor
        mtc.type = keyType
        mtc.valueType = TypesFactory.eINSTANCE.createTypeReference => [
            type = valueType
        ]
        return mtc
    }

    /**
     * Maps a Java object to the corresponding built-in {@link SimpleTypeDecl}
     * ({@code int}, {@code real}, {@code string}, {@code bool}, {@code any}).
     */
    def static SimpleTypeDecl resolveBasicType(Object value) {
        if (value === null) return BasicTypes.anyType
        if (value instanceof Long || value instanceof Integer
                || value instanceof Short || value instanceof Byte
                || value instanceof BigInteger) return BasicTypes.intType
        if (value instanceof BigDecimal || value instanceof Double
                || value instanceof Float) return BasicTypes.realType
        if (value instanceof String || value instanceof CharSequence) return BasicTypes.stringType
        if (value instanceof Boolean) return BasicTypes.boolType
        return BasicTypes.anyType
    }


    def static getImports(Resource res) {
        return res.contents.filter(ModelContainer).flatMap[imports]
    }

    def static getImports(Resource res, String fileExtension) {
        val suffix = '.' + fileExtension.toLowerCase
        return res.imports.filter[importURI.toLowerCase.endsWith(suffix)]
    }
}