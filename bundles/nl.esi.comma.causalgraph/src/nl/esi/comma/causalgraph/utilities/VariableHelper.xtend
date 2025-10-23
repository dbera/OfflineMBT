package nl.esi.comma.causalgraph.utilities

import nl.esi.comma.causalgraph.causalGraph.CausalGraphFactory
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.expressions.expression.Variable
import nl.esi.comma.types.types.TypesFactory
import nl.esi.comma.actions.actions.ActionsFactory
import nl.esi.comma.actions.actions.AssignmentAction
import nl.esi.comma.types.BasicTypes
import nl.esi.comma.types.types.TypeDecl

class VariableHelper {
    static extension val CausalGraphFactory m_cg = CausalGraphFactory::eINSTANCE
    static extension val ExpressionFactory m_exp = ExpressionFactory::eINSTANCE
    static extension val ActionsFactory m_act = ActionsFactory::eINSTANCE

    /**
     * Creates a step parameter Variable with the specified name and type by the stepDefinitionAgent.
     */
    static def Variable createStepParameter(String paramName, String paramType) {
        val variableX = createVariable => [
            name = paramName
            type = createTypeReference => [
                type = getBasicTypeFromString(paramType)
            ]
        ]
        return variableX
    }
    

    /**
     * Maps LLM-suggested parameter types (in string format) to accepted BasicTypes for serialization compatibility.
     */
    static def TypeDecl getBasicTypeFromString(String paramType) {
        val lowerType = paramType.toLowerCase()
        if (lowerType == "string" || lowerType == "str") {
            BasicTypes.stringType
        } else if (lowerType == "int" || lowerType == "integer") {
            BasicTypes.intType
        } else if (lowerType == "bool" || lowerType == "boolean") {
            BasicTypes.boolType
        } else if (lowerType == "float" || lowerType == "real" || lowerType == "double") {
            BasicTypes.realType
        } else {
            // Default to string for unknown types
            System.out.println(String.format("Unknown type '%s', defaulting to string", paramType))
            BasicTypes.stringType
        }
    }
    
    
    /**
     * Creates a step argument AssignmentAction with the suggested parameter value and parameter type by the 
     * stepDefinitionAgent and it reuses the corresponding existing step parameter Variable.
     * This ensures proper cross-reference resolution during serialization.
     */
    static def AssignmentAction createStepArgumentWithVariable(Variable existingVariable, Object paramValue, String paramType) {
        val assignmentAction = createAssignmentAction => [
            assignment = existingVariable
            exp = createExpressionFromValue(paramValue, paramType)
        ]
        return assignmentAction
    }
    
    /**
     * Creates an Expression from a value based on its type.
     * Handles different types of parameter values for step arguments.
     */
    static def createExpressionFromValue(Object value, String paramType) {
        val lowerType = paramType.toLowerCase()
        
        if (lowerType == "string" || lowerType == "str") {
            createExpressionConstantString => [
                setValue(value.toString())
            ]
        } else if (lowerType == "int" || lowerType == "integer") {
            createExpressionConstantInt => [
                setValue(Integer.parseInt(value.toString()))
            ]
        } else if (lowerType == "bool" || lowerType == "boolean") {
            createExpressionConstantBool => [
                setValue(Boolean.parseBoolean(value.toString()))
            ]
        } else if (lowerType == "float" || lowerType == "real" || lowerType == "double") {
            createExpressionConstantReal => [
                setValue(Double.parseDouble(value.toString()))
            ]
        } else {
            // Default to string for unknown types
            System.out.println(String.format("Unknown type '%s' for value '%s', defaulting to string", paramType, value))
            createExpressionConstantString => [
                setValue(value.toString())
            ]
        }
    }
    
}