package nl.asml.matala.product.generator

import java.util.ArrayList
import nl.asml.matala.product.product.Product
import nl.esi.comma.types.types.TypesModel
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.EnumTypeDecl
import nl.esi.comma.types.types.RecordTypeDecl

class TypesGenerator 
{
	def generatePythonGetters(Product prod, Resource resource) 
	{	
		var txt = ''''''
		var typesList = new ArrayList<DataInstance>
		for(imp : prod.imports) {
			val inputResource = EcoreUtil2.getResource(resource, imp.importURI)
			var types = inputResource.allContents.head
			if( types instanceof TypesModel) {
				typesList.addAll(getTypesList(types, resource))
			}
		}
		for(datainst : typesList) {
			txt +=
			'''
			@staticmethod
			def get_«datainst.type_name»():
				«IF datainst.ctype instanceof RecordTypeDecl»
					return json.dumps(«datainst.value»)
				«ELSE»
					return «datainst.value»
				«ENDIF»
				
			'''
		}
		return txt
	}
	
	def ArrayList<DataInstance> getTypesList(TypesModel tmodel, Resource resource) {
		var dataInstanceList = new ArrayList<DataInstance>
		for(imp : tmodel.imports) {
			val inputResource = EcoreUtil2.getResource(resource, imp.importURI)
			var _tmodel = inputResource.allContents.head
			if( _tmodel instanceof TypesModel) {
				getTypesList(_tmodel,resource)
			}
		}
		for(type : tmodel.types) {
			dataInstanceList.add(new DataInstance(type.name, SnakesHelper.defaultValue(type), type))
		}
		return dataInstanceList
	}
}

class DataInstance {
	public var type_name = new String
	public var value = new String
	public var TypeDecl ctype
	
	new(String t, String v, TypeDecl ct) {
		type_name = t
		value = v
		ctype = ct
	}
	
	def display() {
		System.out.println("	> Data Type: " + type_name + " Init: " + value)
	}
}
