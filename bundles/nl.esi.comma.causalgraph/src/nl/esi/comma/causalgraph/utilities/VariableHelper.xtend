package nl.esi.comma.causalgraph.utilities

import nl.esi.comma.causalgraph.causalGraph.CausalGraphFactory
import nl.esi.comma.expressions.expression.ExpressionFactory
import nl.esi.comma.types.types.TypeDecl

class VariableHelper {
    static extension val CausalGraphFactory m_cg = CausalGraphFactory::eINSTANCE
    static extension val ExpressionFactory m_exp = ExpressionFactory::eINSTANCE
    
    def createVar(String namevar, String typevar){        
//        val variableX = createVariable => [
//            name = namevar
//            type = createTypeReference => [
//                type = 
//            ]
//        ]
    }
}