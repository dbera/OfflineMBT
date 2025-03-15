package nl.asml.matala.product.generator

import nl.asml.matala.product.product.SymbConstraint
import nl.asml.matala.product.product.DataConstraints
import nl.asml.matala.product.product.RefConstraint
import nl.asml.matala.product.product.DataReferences
import nl.asml.matala.product.product.VarRef
import nl.asml.matala.product.product.UpdateOutVar
import nl.asml.matala.product.product.Block
import nl.esi.comma.expressions.expression.Variable
import nl.asml.matala.product.product.Function
import nl.asml.matala.product.product.Blocks
import nl.asml.matala.product.product.Specification
import nl.asml.matala.product.product.Update
import nl.esi.comma.assertthat.assertThat.DataCheckItems
import nl.asml.matala.product.product.DataAssertions

class Utils 
{
    // Added for Asserts
//    dispatch def String printConstraint(DataCheckItems dcref) {
//        return printConstraint(dcref.eContainer as DataAssertions)
//    }

    // Added for Asserts
    dispatch def String printConstraint(DataAssertions ref) {
        return printConstraint(ref.eContainer as Update) + "." + ref.name
    } 

    dispatch def String printConstraint(SymbConstraint sref) {
        return printConstraint(sref.eContainer as DataConstraints) + "." + sref.name
    }   

    dispatch def String printConstraint(RefConstraint ref) {
        return printConstraint(ref.eContainer as DataReferences) + "." + ref.name
    }
    
    dispatch def String printConstraint(DataConstraints ref) {
        return printConstraint(ref.eContainer as VarRef)
    }
    
    dispatch def String printConstraint(DataReferences ref) {
        return printConstraint(ref.eContainer as VarRef)
    }
    
    dispatch def String printConstraint(VarRef ref) {
        return printConstraint(ref.eContainer as UpdateOutVar)
    }
    
    dispatch def String printConstraint(UpdateOutVar ref) {
        return printConstraint(ref.eContainer as Update)
    }
    
    dispatch def String printConstraint(Update ref) {
        return printConstraint(ref.eContainer as Function) + "." + ref.name
    }
    
    dispatch def String printConstraint(Function ref) {
        return printConstraint(ref.eContainer as Block) + "." + ref.name
    }
    
    dispatch def String printConstraint(Variable ref) {
        return printConstraint(ref.eContainer as Block) + "." + ref.name
    }
    
    dispatch def String printConstraint(Block ref) {
        return printConstraint(ref.eContainer as Blocks) + "." + ref.name
    }
    
    dispatch def String printConstraint(Blocks ref) {
        return printConstraint(ref.eContainer as Specification)
    }
    
    dispatch def String printConstraint(Specification ref) {
        return ref.name
    }

}