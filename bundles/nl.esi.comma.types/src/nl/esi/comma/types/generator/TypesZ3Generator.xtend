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
import nl.esi.comma.types.types.TypesModel
import org.eclipse.emf.ecore.resource.Resource
import java.util.List
import java.util.ArrayList
import nl.esi.comma.types.types.RecordField
import java.util.HashMap
import java.util.Map
import java.util.HashSet

/*
 * This class provides methods that map ComMA types to Z3 representation
 */
 
class TypesZ3Generator {

	var map_rec_txt = ''''''
	
	def createSimpleTypeList() {
		var listOfSimpleTypeNames = new HashSet<String>
		listOfSimpleTypeNames.add("int")
		listOfSimpleTypeNames.add("string")
		listOfSimpleTypeNames.add("bool")
		listOfSimpleTypeNames.add("real")
		return listOfSimpleTypeNames
	}
	
	def CharSequence generateAllUserDefinedTypes(TypesModel tm)
	{
		// val root = ResourceUtils::resourceToEObject(resource)
		// var List<TypeDecl> userTypes = StateMachineUtilities::getGlobalTypes(root, scopeProvider)
		var List<TypeDecl> userTypes = tm.types
		
		var listOfSimpleTypeNames = createSimpleTypeList
		var listOfEnumTypeNames = new HashSet<String>
		for(typ : userTypes.filter[ t | t instanceof EnumTypeDecl]) {
			listOfEnumTypeNames.add(typ.name)
		}
		// Sort the record types in accordance with their defined hierarchy
		var List<RecordTypeDecl> userRecordTypes = new ArrayList<RecordTypeDecl>()
		for(typ : userTypes.filter[ t | t instanceof RecordTypeDecl]) {
			userRecordTypes.add(typ as RecordTypeDecl)
		}
		var sortedRecTxt = generateSortedHierarchyOfRecordTypes(userRecordTypes, listOfSimpleTypeNames, listOfEnumTypeNames)
	    // System.out.println(userRecordTypes)
		
		return
		'''
		from z3 import *
		
		
		«FOR typ : userTypes»
«««			«IF typ instanceof SimpleTypeDecl»
«««				«generateSimpleTypeDefinition(typ)»
«««			«ENDIF»
			«IF typ instanceof EnumTypeDecl»
				«generateEnumTypeDefinition(typ)»
			«ENDIF»
«««			«IF typ instanceof VectorTypeDecl»
«««				«generateVectorTypeDefinition(typ)»
«««			«ENDIF»
		«ENDFOR»
		«sortedRecTxt»
«««		«FOR typ : userRecordTypes»
«««			«generateRecordTypeDefinition(typ)»
«««		«ENDFOR»
		'''
	}
	
	def generateSortedHierarchyOfRecordTypes(List<RecordTypeDecl> typeList, 
		HashSet<String> listOfSimpleTypes, HashSet<String> listOfEnumTypes
	)
	{
		var Map<String, HashSet<String>> recordNameToDepMap = new HashMap<String, HashSet<String>>()
		var Map<String, Integer> recordNameToIDMap = new HashMap<String, Integer>()
		var Map<Integer, String> recordIDToNameMap = new HashMap<Integer, String>()
		var sortedMapTxt = ''''''
		var idx = 0
		// create unique ID for each record
		for(t : typeList) {
			recordIDToNameMap.put(idx, t.name)
			recordNameToIDMap.put(t.name, idx)
			idx++
		}
		// detect which types are referenced in a record
		for(t : typeList) {
			var depList = new HashSet<String>()
			for(f : t.fields) {
				if(f.type instanceof TypeReference) {
					if(f.type.type instanceof RecordTypeDecl) {
						depList.add(f.type.type.name)
						//System.out.println( " DEBUG : Type Decl > Record" + f.type.type.name)
					} // else {System.out.println( " DEBUG NOT Record: Type Decl > Record" + f.type.type.name)}
				}
				else if(f.type instanceof VectorTypeConstructor) {
					depList.add(f.type.type.name) // TODO Vector of Map is not Handled!
				}
				else if(f.type instanceof MapTypeConstructor) {
					depList.add(f.type.type.name)
					depList.add((f.type as MapTypeConstructor).valueType.type.name) 
				}
			}
			depList.removeAll(listOfSimpleTypes)
			depList.removeAll(listOfEnumTypes)
			recordNameToDepMap.put(t.name, depList)
		}
		// do a topological sort
		var numVertices = 0
		for(k : recordNameToDepMap.keySet) {
			// System.out.println(" Key: " + k)
			numVertices++
			for(v : recordNameToDepMap.get(k)) {
				// System.out.println(" 	Depends on : " + v)
			}
		}
		var tpg = new TopologicalSort(numVertices)
		for(k : recordNameToDepMap.keySet) {
			for(v : recordNameToDepMap.get(k)) {
				tpg.addEdge(recordNameToIDMap.get(k), recordNameToIDMap.get(v))
			}
		}
		var sortedList = tpg.topologicalSort.reverse
		// System.out.println("Sorted List")
		// return sortedList
		for(rec : sortedList) {
			//System.out.println("	> " + recordIDToNameMap.get(rec))
			var recName = recordIDToNameMap.get(rec)
			for(trec : typeList) {
				map_rec_txt = ''''''
				if(recName.equals(trec.name)) {
					var recTxt = generateRecordTypeDefinition(trec)
					if(!map_rec_txt.equals(''''''))
						sortedMapTxt += map_rec_txt
					sortedMapTxt += recTxt
				}
			}
		}
		sortedMapTxt
	}

	def makeFirstLetterUpperCase(String str) {
		return str.substring(0, 1).toUpperCase() + str.substring(1)
	}

	def generateSimpleTypeDefinition(SimpleTypeDecl type, RecordField elm, String recName) {
		'''«type.name.substring(0, 1).toUpperCase() + type.name.substring(1)»Sort()'''
	}

	def generateEnumTypeDefinition(EnumTypeDecl type) {
		'''
		«type.name» = Datatype('«type.name»')
		«FOR lit : type.literals SEPARATOR ","»
			«type.name».declare('«lit.name»')
		«ENDFOR»
		«type.name».declare('none')
		«type.name» = «type.name».create()
		
		'''
	}

	def generateVectorFieldDefinition(VectorTypeConstructor type, RecordField elm, String recName) {
		var vecIter = (elm.type as VectorTypeConstructor).dimensions.size
		return '''('«elm.name»', «FOR iter_ : 0..<vecIter»ArraySort(IntSort(), «ENDFOR»«elm.type.type.name»«FOR iter_ : 0..<vecIter»)«ENDFOR»)'''
	}
	
	
	def generateRecordFields(RecordTypeDecl type) {
		'''
		«FOR elm : type.fields SEPARATOR ','»
			«IF elm.type instanceof TypeReference»
				«IF elm.type.type instanceof SimpleTypeDecl»
					('«elm.name»', «generateSimpleTypeDefinition(elm.type.type as SimpleTypeDecl, elm, type.name)»)
				«ELSEIF elm.type.type instanceof RecordTypeDecl»
					('«elm.name»_rec', «elm.type.type.name»)
				«ELSEIF elm.type.type instanceof EnumTypeDecl»
					('«elm.name»', «elm.type.type.name»)
				«ELSE»
					UNHANDLED TYPE «elm.type.type»
				«ENDIF»
			«ELSEIF elm.type instanceof VectorTypeConstructor»
				«generateVectorFieldDefinition((elm.type as VectorTypeConstructor), elm, type.name)»
			«ELSEIF elm.type instanceof MapTypeConstructor»
				«{map_rec_txt += addMapRecTxt(elm) ""}»
				('«elm.name»', «elm.name»_map)
			«ELSE»
				[FATAL] UNHANDLED TYPE!
			«ENDIF»
		«ENDFOR»
		'''
	}
	
	def generateRecordTypeDefinition(RecordTypeDecl type)
	{
		'''
		
		«type.name» = Datatype('«type.name»')
		«type.name».declare('init',
		               «generateRecordFields(type)»
		               )
		«type.name» = «type.name».create()

		'''
	}

	
	def addMapRecTxt(RecordField elm) {
		return 
		'''
		«elm.name»Rec = Datatype('«elm.name»Rec')
		«elm.name»Rec.declare('init', ('key', IntSort()), ('value', «(elm.type as MapTypeConstructor).valueType.type.name»))
		«elm.name»Rec = «elm.name»Rec.create()
		
		«elm.name»_map = Datatype('«elm.name»')
		«elm.name»_map.declare('init',
		                     ('«elm.name»_list', ArraySort(IntSort(), «elm.name»Rec)),
		                     ('«elm.name»_idx', IntSort()),
		                     «IF (elm.type as MapTypeConstructor).valueType.type instanceof SimpleTypeDecl»
		                     	('«elm.name»_t', «makeFirstLetterUpperCase((elm.type as MapTypeConstructor).valueType.type.name)»Sort())
		                     «ELSE»
		                     	('«elm.name»_t', «(elm.type as MapTypeConstructor).valueType.type.name»)
		                     «ENDIF»
		                     )
		«elm.name»_map = «elm.name»_map.create()
		«elm.name»_map.«elm.name»_list = (K(IntSort(), «elm.name»Rec.init(0, «generateDefaultValue((elm.type as MapTypeConstructor).valueType.type)»)))
		'''
	}
	

	
//	def dispatch CharSequence generateDefaultValue(TypeReference t){
//		generateDefaultValue(t.type)
//	}
//	
	def dispatch CharSequence generateDefaultValue(SimpleTypeDecl t){
		if(t.name.equals("int")) return '''0'''
		if(t.name.equals("real")) return '''0.0'''
		if(t.name.equals("bool")) return '''true'''
		if(t.name.equals("string")) return '''""'''
		
		""
	}
	
	def dispatch CharSequence generateDefaultValue(EnumTypeDecl t){
		t.name + ".none" // + t.literals.get(0).name
	}
	
	def dispatch CharSequence generateDefaultValue(RecordTypeDecl  t){
		// '''«typeToZ3Syntax(t)»{«FOR f : TypeUtilities::getAllFields(t) SEPARATOR ', '»«f.name» = «generateDefaultValue(f.type)»«ENDFOR»}'''
		'''«t.name».init(«FOR f : TypeUtilities::getAllFields(t) SEPARATOR ', '»«generateDefaultValue(f.type.type)»«ENDFOR»)''' 
	}


/*
«««		class «type.name»:
«««			def __init__(self, idx):
«««				«FOR elm : type.fields»
«««					«{vecIter = 0 ""}»
«««					«IF elm.type instanceof TypeReference»
«««						«IF elm.type.type instanceof VectorTypeDecl»
«««							«generateVectorTypeDefinition(elm.type.type as VectorTypeDecl, elm, type.name)»
«««						«ELSEIF elm.type.type instanceof RecordTypeDecl»
««««««						«generateRecordTypeDefinition(elm.type.type as RecordTypeDecl)»
«««						«ELSEIF elm.type.type instanceof EnumTypeDecl»
««««««						«generateEnumTypeDefinition(elm.type.type as EnumTypeDecl)»
«««						«ELSEIF elm.type.type instanceof SimpleTypeDecl»
«««							«generateSimpleTypeDefinition(elm.type.type as SimpleTypeDecl, elm, type.name)»
«««						«ENDIF»
«««					«ELSEIF elm.type instanceof VectorTypeConstructor»
«««						«{vecIter = (elm.type as VectorTypeConstructor).dimensions.size ""}»
«««						self.«type.name»_«elm.name» =  «FOR iter_ : 0..<vecIter»[«ENDFOR»«elm.type.type.name»([«FOR _iter : 0..<vecIter SEPARATOR ', '»i«_iter»«ENDFOR»])«FOR iter : 0..<vecIter» for i«iter» in range(«(elm.type as VectorTypeConstructor).dimensions.get(iter).size»)]«ENDFOR»
«««					«ELSEIF elm.type instanceof MapTypeConstructor»
«««						«{addMapRecTxt(elm) ""}»
«««						self.«type.name»_«elm.name» = Const('«type.name»_«elm.name»_' + str(idx), «elm.name»)
«««					«ELSE»
«««						[FATAL] UNHANDLED TYPE!
«««					«ENDIF»
«««				«ENDFOR»


//		'''
//		«IF type.constructor.dimensions!== null»
//			self.«recName»_«elm.name» = Array('«recName»_«elm.name»_' + str(idx), IntSort(), «type.name»)
//		«ELSE»
//			«{vecIter = (elm.type as VectorTypeConstructor).dimensions.size ""}»
//			(«elm.name», Array('«elm.name»', IntSort(), «elm.type.type.name»))
//			«FOR iter_ : 0..<vecIter»[«ENDFOR»«elm.type.type.name»([«FOR _iter : 0..<vecIter SEPARATOR ', '»i«_iter»«ENDFOR»])«FOR iter : 0..<vecIter» for i«iter» in range(«(elm.type as VectorTypeConstructor).dimensions.get(iter).size»)]«ENDFOR»)
//		«ENDIF»
//		'''

 */

//class «elm.name»:
//		    def __init__(self, j):
//			    self.«elm.name»_list = Array('«elm.name»_list' + str(j), IntSort(), «elm.name»Rec)
//				self.«elm.name»_idx = Int('«elm.name»_idx' + str(j))
//				«IF (elm.type as MapTypeConstructor).valueType.type instanceof SimpleTypeDecl»
//					self.«elm.name»_t = «(elm.type as MapTypeConstructor).valueType.type.name»('«elm.name»_t' + str(j))
//				«ELSE»
//					self.«elm.name»_t = Const('«elm.name»_t' + str(j), «makeFirstLetterUpperCase((elm.type as MapTypeConstructor).valueType.type.name)»)
//				«ENDIF»
//				self.«elm.name»_list = K(IntSort(), «elm.name»Rec.init(0, «generateDefaultValue((elm.type as MapTypeConstructor).valueType.type)»))
//			
//			def select(self, sol, k):
//			    sol.add(Select(self.«elm.name»_list, self.«elm.name»_idx) == «elm.name»Rec.init(k, self.«elm.name»_t))
//		
//	def dispatch CharSequence generateDefaultValue(VectorTypeDecl t){ // DO NTO HANDLE!
//		'''<«typeToZ3Syntax(t)»>[]'''
//	}
//	

	// TODO handle other data types!!!
	def dispatch CharSequence generateDefaultValue(VectorTypeConstructor t){
		'''K(IntSort(), «generateDefaultValue(t.type)»)'''
	}
//	
//	def dispatch CharSequence generateDefaultValue(MapTypeDecl t){
//		'''<«typeToZ3Syntax(t)»>{}'''
//	}
//	
//	def dispatch CharSequence generateDefaultValue(MapTypeConstructor t){
//		'''<«typeToZ3Syntax(t)»>{}'''
//	}
}