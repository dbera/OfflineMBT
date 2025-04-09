package nl.asml.matala.product.mcrl2

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

class TypesGenerator
{
    var ArrayList<String> maps = new ArrayList<String>
    
    def generateJSON(TypesModel tm)
    {
        var List<TypeDecl> userTypes = tm.types

        var listOfEnumTypes = new HashSet<EnumTypeDecl>
        for(typ : userTypes.filter[ t | t instanceof EnumTypeDecl]) {
            listOfEnumTypes.add(typ as EnumTypeDecl)
        }

        var List<RecordTypeDecl> userRecordTypes = new ArrayList<RecordTypeDecl>()
        for(typ : userTypes.filter[ t | t instanceof RecordTypeDecl]) {
            userRecordTypes.add(typ as RecordTypeDecl)
        }

        return
        '''
        {
            "enum": {
                «FOR typ : listOfEnumTypes SEPARATOR ","»
                     «generateEnumTypeDefinition(typ)»
                «ENDFOR»
            },
            
            "record": {
                «FOR typ : userRecordTypes SEPARATOR ","»
                     «generateRecordTypeDefinition(typ)»
                «ENDFOR»
            },
            
            "maps": [
                «FOR m : maps SEPARATOR ", "»
                     «m»
                «ENDFOR»
            ]
        }
        '''
    }

    def generateEnumTypeDefinition(EnumTypeDecl type) {
        '''
        "«type.name»": [
            «FOR lit : type.literals SEPARATOR ","»
                "«lit.name»"
            «ENDFOR»
        ]
        '''
    }
    
    def generateRecordTypeDefinition(RecordTypeDecl type)
    {
        var mapTypes = new HashSet<RecordField>
        var varTypes = new HashSet<RecordField>
        
        for (stype : type.fields) {
            if (stype.type instanceof MapTypeConstructor) {
                mapTypes.add(stype)
                maps.add('''["Int", "«(stype.type as MapTypeConstructor).getValueType().getType().name»"]''')
            } else {
                varTypes.add(stype)                
            }
            
        }
        '''
        "«type.name»": {
            "maps": {
                «FOR t : mapTypes SEPARATOR ","»
                    "«t.name»": {"from": "Int", "to": "«(t.type as MapTypeConstructor).getValueType().type.name»"}
                «ENDFOR»
            },
            "vars": {
                «FOR t : varTypes SEPARATOR ","»
                    "«t.name»": "«t.type.type.name»"
                «ENDFOR»
            }
        }
        '''
    }
}