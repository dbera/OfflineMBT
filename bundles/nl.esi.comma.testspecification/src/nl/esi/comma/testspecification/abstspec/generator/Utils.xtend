package nl.esi.comma.testspecification.abstspec.generator

import java.util.Collections
import java.util.List
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.ComposeStep
import nl.esi.comma.testspecification.testspecification.RunStep
import nl.esi.comma.testspecification.testspecification.TSJsonArray
import nl.esi.comma.testspecification.testspecification.TSJsonBool
import nl.esi.comma.testspecification.testspecification.TSJsonFloat
import nl.esi.comma.testspecification.testspecification.TSJsonLong
import nl.esi.comma.testspecification.testspecification.TSJsonMember
import nl.esi.comma.testspecification.testspecification.TSJsonObject
import nl.esi.comma.testspecification.testspecification.TSJsonString
import nl.esi.comma.testspecification.testspecification.TSJsonValue
import nl.esi.comma.testspecification.testspecification.TestspecificationFactory
import nl.esi.comma.types.types.MapTypeConstructor
import nl.esi.comma.types.types.Type
import nl.esi.comma.types.types.TypeReference
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.types.types.VectorTypeConstructor
import org.eclipse.emf.ecore.util.EcoreUtil

class Utils 
{
    private new() {
        // Empty
    }

    static def getSteps(AbstractTestDefinition atd) {
        return atd.testSeq.flatMap[step]
    }

    static def getSystem(RunStep step) {
        return step.name.split('_').get(0)
    }

    // Gets the list of referenced compose steps
    // RULE. Exactly one referenced Compose Step.
    static def getComposeSteps(RunStep step) {
        return step.stepRef.map[refStep].filter(ComposeStep)
    }

    dispatch static def String printField(ExpressionRecordAccess exp) {
        return exp.record.printField + '.' + exp.field.name
    }

    dispatch static def String printField(ExpressionVariable exp) {
        return exp.variable.name
    }

    // Types utilities

    static def Type getOuterDimension(VectorTypeConstructor type) {
        return if (type.dimensions.size > 1) {
            EcoreUtil.copy(type) => [
                dimensions.removeLast
            ]
        } else {
            TypesFactory.eINSTANCE.createTypeReference => [
                type = type.type
            ]
        }
    }

    dispatch static def String getTypeName(TypeReference type) '''
        «type.type.name»'''

    dispatch static def String getTypeName(VectorTypeConstructor type) '''
        «type.type.name»«FOR dimension : type.dimensions»[]«ENDFOR»'''

    dispatch static def String getTypeName(MapTypeConstructor type) '''
        map<«type.type.name», «type.valueType.typeName»>'''

    // JSON utilities

    static def List<TSJsonMember> getMemberValues(TSJsonValue value) {
        return value instanceof TSJsonObject ? value.members : Collections.emptyList
    }

    static def boolean hasMemberValue(TSJsonValue value, String member) {
        return value instanceof TSJsonObject ? value.members.exists[key == member] : false
    }

    static def TSJsonValue getMemberValue(TSJsonValue value, String member) {
        return value instanceof TSJsonObject ? value.members.findFirst[key == member]?.value : null
    }

    static def List<TSJsonValue> getItemValues(TSJsonValue value) {
        return value instanceof TSJsonArray ? value.values : Collections.emptyList
    }

    static def String getStringValue(TSJsonValue value) {
        return switch (value) {
            case null: null
            TSJsonString: value.value
            TSJsonBool: String.valueOf(value.value)
            TSJsonFloat: String.valueOf(value.value)
            TSJsonLong: String.valueOf(value.value)
            TSJsonObject: value.members.join('{', ', ', '}')[key + ': ' value.stringValue]
            TSJsonArray: value.values.join('[', ', ', ']')[stringValue]
            default: throw new IllegalArgumentException('Unknown JSON type ' + value)
        }
    }

    static def TSJsonString toJsonString(String text) {
        return TestspecificationFactory.eINSTANCE.createTSJsonString => [
            value = text
        ]
    }
}