package nl.esi.comma.expressions.validation

import com.google.inject.Inject
import java.util.List
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionAddition
import nl.esi.comma.expressions.expression.ExpressionAnd
import nl.esi.comma.expressions.expression.ExpressionAny
import nl.esi.comma.expressions.expression.ExpressionBinary
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionBulkData
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionDivision
import nl.esi.comma.expressions.expression.ExpressionEnumLiteral
import nl.esi.comma.expressions.expression.ExpressionEqual
import nl.esi.comma.expressions.expression.ExpressionFunctionCall
import nl.esi.comma.expressions.expression.ExpressionGeq
import nl.esi.comma.expressions.expression.ExpressionGreater
import nl.esi.comma.expressions.expression.ExpressionLeq
import nl.esi.comma.expressions.expression.ExpressionLess
import nl.esi.comma.expressions.expression.ExpressionMap
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionMaximum
import nl.esi.comma.expressions.expression.ExpressionMinimum
import nl.esi.comma.expressions.expression.ExpressionMinus
import nl.esi.comma.expressions.expression.ExpressionModulo
import nl.esi.comma.expressions.expression.ExpressionMultiply
import nl.esi.comma.expressions.expression.ExpressionNEqual
import nl.esi.comma.expressions.expression.ExpressionNot
import nl.esi.comma.expressions.expression.ExpressionOr
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.ExpressionPlus
import nl.esi.comma.expressions.expression.ExpressionPower
import nl.esi.comma.expressions.expression.ExpressionQuantifier
import nl.esi.comma.expressions.expression.ExpressionRecord
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionSubtraction
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.expressions.expression.InterfaceAwareType
import nl.esi.comma.expressions.expression.QUANTIFIER
import nl.esi.comma.signature.interfaceSignature.Signature
import nl.esi.comma.types.types.Dimension
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.RecordTypeDecl
import nl.esi.comma.types.types.SimpleTypeDecl
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeDecl
import nl.esi.comma.types.types.TypeObject
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.TypesPackage
import nl.esi.comma.types.types.VectorTypeConstructor
import nl.esi.comma.types.types.VectorTypeDecl
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.validation.Check

import static extension nl.esi.comma.types.utilities.TypeUtilities.*

/*
 * This class mainly captures the ComMA type system for expressions. Constraints are not formulated
 * in text here. Consult the document with the formal definition of the ComMA type system.
 */
class ExpressionValidator extends AbstractExpressionValidator {
	
	@Inject protected IScopeProvider scopeProvider
	
	protected var SimpleTypeDecl boolType = null;
	protected var SimpleTypeDecl intType = null;
	protected var SimpleTypeDecl realType = null;
	protected var SimpleTypeDecl stringType = null;
	protected var SimpleTypeDecl voidType = null;
	protected var SimpleTypeDecl anyType = null
	protected var SimpleTypeDecl idType = null
	protected var SimpleTypeDecl bulkdataType = null;
	
	new(){
		initPredefinedTypes();
	}
	
	def initPredefinedTypes(){
			
		boolType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); boolType.name = 'bool'
		voidType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); voidType.name = 'void'
		intType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); intType.name = 'int'
		stringType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); stringType.name = 'string'
		realType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); realType.name = 'real'
		anyType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); anyType.name = 'any'
		idType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); idType.name = 'id'
		bulkdataType = TypesFactory.eINSTANCE.createSimpleTypeDecl(); bulkdataType.name = 'bulkdata'
	}
	def boolean identical(TypeObject t1, TypeObject t2) {
		if(t1 === null || t2 === null) return false
		
		if(t1 instanceof SimpleTypeDecl)
			if(t2 instanceof SimpleTypeDecl)
				return t1.name.equals(t2.name)
				
		if(t1 instanceof VectorTypeConstructor)
			if(t2 instanceof VectorTypeConstructor){
				if(!t1.type.identical(t2.type)) return false
				if(t1.dimensions.size != t2.dimensions.size) return false
				for(i : 0..< t1.dimensions.size){
					if(t1.dimensions.get(i).size != t2.dimensions.get(i).size) return false
				}
				return true
			}
			
		if(t1 instanceof MapTypeConstructor)
			if(t2 instanceof MapTypeConstructor){
				return t1.keyType.identical(t2.keyType) && t1.valueType.typeObject.identical(t2.valueType.typeObject)
			}
				
		t1 === t2	
	}
	
	def boolean subTypeOf(TypeObject t1, TypeObject t2){
		if(t1 === null || t2 === null) return false
		if(t1.synonym(t2)) return true //reflexive case
		if(t1.identical(anyType)) return true //any is subtype of all types
		if(t1 instanceof RecordTypeDecl  && t2 instanceof RecordTypeDecl) //record type subtyping
			return getAllParents(t1 as RecordTypeDecl).contains(t2)
			
		if(t1 instanceof VectorTypeConstructor){
			if(t2 instanceof VectorTypeConstructor){
				if(!t1.type.subTypeOf(t2.type)) return false
				if(t1.dimensions.size != t2.dimensions.size) return false
				for(i : 0..< t1.dimensions.size){
					if(t1.dimensions.get(i).size != t2.dimensions.get(i).size) return false
				}
				return true
			}
		}
		false
	}
	
	def boolean synonym(TypeObject t1, TypeObject t2){
		if(t1 === null || t2 === null) return false
		if(t1.identical(t2)) return true //reflexive case
		
		if(t1 instanceof SimpleTypeDecl)
			if(t2 instanceof SimpleTypeDecl){
				return (t1.base.identical(t2)) ||
				       (t2.base.identical(t1)) ||
				       (t1.base.identical(t2.base))
			}
		false
	}
	
	//Type computation. No checking is performed. If the type cannot be determined, null is returned
	def TypeObject typeOf(Expression e){
		if(e === null) return null
		switch(e){
			ExpressionConstantBool |
			ExpressionAnd |
			ExpressionOr |
			ExpressionNot |
			ExpressionEqual |
			ExpressionNEqual |
			ExpressionLess |
			ExpressionGreater |
			ExpressionLeq |
			ExpressionGeq : boolType
			ExpressionConstantInt |
			ExpressionModulo : intType
			ExpressionConstantReal : realType
			ExpressionAddition |
			ExpressionSubtraction |
			ExpressionDivision | 
			ExpressionMultiply |
			ExpressionPower |
			ExpressionMinimum |
			ExpressionMaximum : inferTypeBinaryArithmetic(e)
			ExpressionMinus |
			ExpressionPlus : {
				val t = e.sub.typeOf
				if(t.subTypeOf(intType) || t.subTypeOf(realType))
					t
				else
					null
			}
			ExpressionVariable : e.variable?.type.typeObject
			ExpressionConstantString : stringType
			ExpressionBracket : e.sub?.typeOf
			ExpressionEnumLiteral : e.type
			ExpressionRecord : e.type
			ExpressionRecordAccess : e.field?.type?.typeObject
			ExpressionBulkData : bulkdataType
			ExpressionAny : anyType
			ExpressionFunctionCall : inferTypeFunCall(e)
			ExpressionVector : e.typeAnnotation?.type?.typeObject
			ExpressionQuantifier : {
				if(e.quantifier == QUANTIFIER::DELETE)
					e.collection.typeOf
				else
					boolType
			}
			ExpressionMap : e.typeAnnotation?.type?.typeObject
			ExpressionMapRW : {
				val t = e.map.typeOf
				if(t !== null && t.mapType)
					if(e.value !== null){
						t
					}else{
						t.valueType
					}
				else
					null
			}
			
		}
	}
		
	def TypeObject inferTypeBinaryArithmetic(ExpressionBinary e){
		val leftType = e.left.typeOf
		val rightType = e.right.typeOf
		switch(e){
			ExpressionAddition : {
				if(leftType.subTypeOf(intType) && rightType.subTypeOf(intType)) return intType
				if(leftType.subTypeOf(realType) && rightType.subTypeOf(realType)) return realType
				if(leftType.subTypeOf(stringType) && rightType.subTypeOf(stringType)) return stringType
				return null
			}
			ExpressionSubtraction |
			ExpressionDivision |
			ExpressionPower | 
			ExpressionMultiply |
			ExpressionMinimum |
			ExpressionMaximum : {
				if(leftType.subTypeOf(intType) && rightType.subTypeOf(intType)) return intType
				if(leftType.subTypeOf(realType) && rightType.subTypeOf(realType)) return realType
				return null
			}
			default : null
		}
	}
	
	def TypeObject inferTypeFunCall(ExpressionFunctionCall e){
		switch(e.functionName){
			case "isEmpty" : boolType
			case "contains" : boolType
			case "hasKey" : boolType
			case "asReal" : realType
			case "length",
			case "size" : intType
			case "abs",
			case "add",
			case "deleteKey" : {
				if(! e.args.empty){
					val t = e.args.get(0).typeOf
					if(e.functionName.equals("abs")) {
						if(t.subTypeOf(intType) || t.subTypeOf(realType)) t
						else null
					}
					else e.args.get(0).typeOf
				}	
				else null
			}
			default: null
		}
	}
	
	//Type checking
	
	@Check
	def checkTypingExpression(Expression e){
		switch(e){
			ExpressionAnd |
			ExpressionOr : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
		
				if((leftType !== null) && !leftType.identical(boolType)){ //use subtype instead!
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
				if((rightType !== null) && !rightType.identical(boolType)){
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_BINARY__RIGHT)
				}
			}
			ExpressionNot: {
				val t = e.sub.typeOf
				if((t !== null) && !t.identical(boolType)){
					error("Type mismatch: expected type bool", ExpressionPackage.Literals.EXPRESSION_UNARY__SUB)
				}
			}
			ExpressionLess |
			ExpressionGreater |
			ExpressionLeq |
			ExpressionGeq : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
		
				if(leftType === null || rightType === null) {return}
				if(!leftType.synonym(rightType)){
					error("Arguments must be of compatible types", e.eContainer, e.eContainingFeature)
					return
				}
				if(!leftType.synonym(intType) && !leftType.synonym(realType)){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
			}
			ExpressionAddition |
			ExpressionSubtraction | 
			ExpressionMultiply |
			ExpressionDivision |
			ExpressionModulo |
			ExpressionPower |
			ExpressionMinimum |
			ExpressionMaximum : {
				val leftType = e.left.typeOf
				val rightType = e.right.typeOf
				if(leftType === null || rightType === null) {return}
				if(!leftType.synonym(rightType)){
					error("Arguments must be of compatible types", e.eContainer, e.eContainingFeature)
					return
				}
				if(e instanceof ExpressionModulo){
					if(!leftType.synonym(intType)){
						error("Type mismatch: expected type int", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
					}
					return
				}
				if(e instanceof ExpressionAddition){
					if(!leftType.synonym(intType) && !leftType.synonym(realType) && !leftType.synonym(stringType)){
						error("Type mismatch: expected type int, real or string", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
					return
				}
				if(!leftType.synonym(intType) && !leftType.synonym(realType)){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_BINARY__LEFT)
				}
				
			}
			ExpressionMinus |
			ExpressionPlus : {
				val t = e.sub.typeOf
				if((t !== null) && !t.subTypeOf(intType) && !t.subTypeOf(realType)){
					error("Type mismatch: expected type int or real", ExpressionPackage.Literals.EXPRESSION_UNARY__SUB)
				}
			}
			ExpressionRecord : {
				if(e.fields.size()!=getAllFields(e.type).size()) {
					//error('Wrong number of fields', ExpressionPackage.Literals.EXPRESSION_RECORD__FIELDS)
					//return
				} 
				for(f : e.fields){
				    var counter = e.fields.stream.filter(r| r.recordField.name == f.recordField.name).count
				    if (counter > 1) {
				        error('Duplicated field name', e, ExpressionPackage.Literals.EXPRESSION_RECORD__FIELDS, e.fields.indexOf(f))
				    }
				    for(var i=0; i<getAllFields(e.type).size;i++) {
				        var field = getAllFields(e.type).get(i)
				        if (f.recordField.name.equals(field.name)){
				            //type checking
				            if (!f.exp.typeOf.subTypeOf(field.type.typeObject)){
				                error('Type mismatch', e, ExpressionPackage.Literals.EXPRESSION_RECORD__FIELDS, e.fields.indexOf(f))
				            }
				        }
				    }
				}
				
			}
			ExpressionMapRW : {
				val mapType = e.map.typeOf
				if(mapType === null) {return}
				if(!mapType.isMapType){
					error("Expression is not a map", ExpressionPackage.Literals.EXPRESSION_MAP_RW__MAP)
					return
				}
				val keyType = e.key.typeOf
				if(keyType !== null && !keyType.identical(mapType.keyType)){
					error("Type of expression does not conform to map key type", ExpressionPackage.Literals.EXPRESSION_MAP_RW__KEY)
				}
				if(e.value !== null){
					val valType = e.value.typeOf
					if(valType !== null && !valType.subTypeOf(mapType.valueType)){
						error("Type of expression does not conform to map value type", ExpressionPackage.Literals.EXPRESSION_MAP_RW__VALUE)
					}
				}
			}
			ExpressionMap : {
				if(e.typeAnnotation?.type === null) {return}
				val mapType = e.typeAnnotation.type
				if(! mapType.isMapType){
					error("The type must be a map type", e.typeAnnotation, ExpressionPackage.Literals.TYPE_ANNOTATION__TYPE)
					return
				}
				//check the pairs
				val keyType = mapType.typeObject.keyType
				val valueType = mapType.typeObject.valueType
				for(p : e.pairs){
					val pairKeyType = p.key.typeOf
					val pairValueType = p.value.typeOf
					if(pairKeyType !== null && ! pairKeyType.identical(keyType)){
						error("Type of expression does not conform to map key type", p, ExpressionPackage.Literals.PAIR__KEY)
					}
					if(pairValueType !== null && ! pairValueType.subTypeOf(valueType)){
						error("Type of expression does not conform to map value type", p, ExpressionPackage.Literals.PAIR__VALUE)
					}
				}
			}
			ExpressionVector : {
				if(e.typeAnnotation?.type === null) {return}
				val vectorType = e.typeAnnotation.type
				if(! isVectorType(vectorType)){
					error("The type must be a vector type", e.typeAnnotation, ExpressionPackage.Literals.TYPE_ANNOTATION__TYPE)
					return
				}
				val s = getFirstDimension(vectorType.typeObject)
				if(s > 0 && (e.elements.size != s)){
					error("Expected size of the vector is " + s, ExpressionPackage.Literals.EXPRESSION_VECTOR__ELEMENTS)
					return
				}
				//check the elements
				val expectedType = getBaseTypeToCheck(vectorType.typeObject)
				for(el : e.elements){
					val t = el.typeOf
					if(t !== null && !t.subTypeOf(expectedType))
						error("The element does not conform to the base type", ExpressionPackage.Literals.EXPRESSION_VECTOR__ELEMENTS, e.elements.indexOf(el))
				}
			}
			ExpressionFunctionCall : {
				switch(e.functionName) {
					case "isEmpty" : checkFunIsEmpty(e)
					case "size"	: checkFunSize(e)
					case "contains" : checkFunContains(e)
					case "add" : checkFunAdd(e)
					case "asReal" : checkFunAsReal(e)
					case "abs" : checkFunAbs(e)
					case "length" : checkFunLength(e)
					case "hasKey" : checkFunHasOrDeleteKey(e)
					case "deleteKey" : checkFunHasOrDeleteKey(e)
					default : error("Unknown function", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
				}
			}
			//TODO consider adding a new check if the type of the iterator is compatible with the type of
			//the vector elements
			ExpressionQuantifier: {
				val collectionType = e.collection.typeOf
				if(collectionType !== null && !isVectorType(collectionType))
					error("Expression must be of type vector", ExpressionPackage.Literals.EXPRESSION_QUANTIFIER__COLLECTION)
				val condType = e.condition.typeOf
				if(condType !== null && !condType.subTypeOf(boolType))
					error("Condition expression must be of type boolean", ExpressionPackage.Literals.EXPRESSION_QUANTIFIER__CONDITION)
	
			}
		}
	}
	
	def checkFunIsEmpty(ExpressionFunctionCall e){
		if(e.args.size != 1){
			error("Function isEmpty expects one argument", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			return
		}
		val t = e.args.get(0).typeOf
		if(t !== null && !isVectorType(t)){
			error("Function isEmpty expects argument of type vector", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
		}
	}
	
	def checkFunSize(ExpressionFunctionCall e){
		if(e.args.size != 1){
			error("Function size expects one argument", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			return
		}
		val t = e.args.get(0).typeOf
		if(t !== null && ! (isVectorType(t) || isMapType(t)) ){
			error("Function size expects argument of type vector or map", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
		}
	}
	
	def checkFunContains(ExpressionFunctionCall e){
		if(e.args.size != 2){
			error("Function contains expects two arguments", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			return
		}
		val t = e.args.get(0).typeOf
		if(t !== null && !isVectorType(t)){
			error("Function contains expects first argument of type vector", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
		}	
	}
	
	def checkFunAdd(ExpressionFunctionCall e){
		if(e.args.size != 2){
			error("Function add expects two arguments", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			return
		}
		val t = e.args.get(0).typeOf
 		if(t === null || !isVectorType(t)){
 			error("Function add expects first argument of type vector", e, ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
 			return
 		}
		//Check if the second argument conforms to the base type of the vector
		val expectedType = getBaseTypeToCheck(t)
		val elType = e.args.get(1).typeOf
		if(elType !== null && !subTypeOf(elType, expectedType))
			error("Second argument does not conform to the base type of the vector", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 1)	
	}
	
	def checkFunAsReal(ExpressionFunctionCall e){
		if(e.args.size != 1)
			error("Function asReal expects one argument", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
		else{
			val t = e.args.get(0).typeOf
			if(t !== null && !t.subTypeOf(intType))
				error("Function asReal expects an argument of type int", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
		}
	}
	
	def checkFunAbs(ExpressionFunctionCall e){
		if(e.args.size != 1)
			error("Function abs expects one argument", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
		else{
			val t = e.args.get(0).typeOf
			if(t !== null && !(t.subTypeOf(realType) || t.subTypeOf(intType)))
				error("Function abs expects an argument of numeric type", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS)
		}
	}
	
	def checkFunLength(ExpressionFunctionCall e){
		if(e.args.size != 1)
			error("Function length expects one argument", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
		else{
			val t = e.args.get(0).typeOf
			if(t !== null && !t.subTypeOf(bulkdataType))
				error("Function length expects an argument of type bulkdata", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
		}
	}
	
	def checkFunHasOrDeleteKey(ExpressionFunctionCall e){
		if(e.args.size != 2){
			error("This function expects two arguments", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__FUNCTION_NAME)
			return
		}
		val t = e.args.get(0).typeOf
 		if(t === null || !t.isMapType) {
 			error("This function expects first argument of type map", e, ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 0)
 			return
 		}
		//Check if the second argument conforms to the key type of the map
		val expectedType = t.keyType
		val keyExprType = e.args.get(1).typeOf
		if(keyExprType !== null && !identical(keyExprType, expectedType))
			error("Second argument does not conform to the key type of the map", ExpressionPackage.Literals.EXPRESSION_FUNCTION_CALL__ARGS, 1)	
	}
	
	private def getBaseTypeToCheck(TypeObject vt){
		var TypeDecl base
		var List<Dimension> dimensions
		if(vt instanceof VectorTypeDecl){
			base = vt.constructor.type
			dimensions = vt.constructor.dimensions
		}
		else{
			base = (vt as VectorTypeConstructor).type
			dimensions = (vt as VectorTypeConstructor).dimensions
		}
		
		if(dimensions.size == 1){
			base
		}
		else{
			var result = TypesFactory.eINSTANCE.createVectorTypeConstructor
			result.type = base
			for(i : 1..< dimensions.size){
				var newDimension = TypesFactory.eINSTANCE.createDimension
				newDimension.size = dimensions.get(i).size
				result.dimensions.add(newDimension)
			}
			result
		}
	}
	
	//Check some expressions for possible ambiguous types
	
	protected def boolean isAmbigousType(EObject context, String typeName, EReference ref){
		var scopeElements = scopeProvider.getScope(context, ref).allElements.filter(od | (od.name.lastSegment == typeName) && (od.name.segmentCount == 1))	
		scopeElements.size > 1
	}
	
	//In order to avoid the code duplication below, the type can be made to refer
	//just to a type declaration and then via validation and scoping make sure that 
	//only the relevant types are bound.
	//For now this is not implemented
	@Check
	def checkDuplicatedEnumTypes(ExpressionEnumLiteral lit){
		if(lit.interface === null){
			if(isAmbigousType(lit, lit.type.name, ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__TYPE))
				error('Several enum types with this name exist. Use an explicit interface name.', ExpressionPackage.Literals.EXPRESSION_ENUM_LITERAL__TYPE)
		}
	}
	
	@Check
	def checkDuplicatedRecordTypes(ExpressionRecord er){
		if(er.interface === null){
			if(isAmbigousType(er, er.type.name, ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE))
				error('Several record types with this name exist. Use an explicit interface name.', ExpressionPackage.Literals.EXPRESSION_RECORD__TYPE)
		}
	}
	
	@Check
	def checkDuplicatedTypeInTypeReference(InterfaceAwareType type){
		var String name = (type as Type).type.name
		var EReference ref = TypesPackage.Literals.TYPE__TYPE
		var Signature i = (type as InterfaceAwareType).interface
		
		if(i === null){
			if(isAmbigousType(type, name, ref))
				error('Several types with this name exist. Use an explicit interface name.', ref)
		}
	}	
}