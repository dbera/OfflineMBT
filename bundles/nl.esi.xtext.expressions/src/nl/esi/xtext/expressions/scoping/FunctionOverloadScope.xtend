/**
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.expressions.scoping

import nl.esi.xtext.expressions.expression.ExpressionFunctionCall
import nl.esi.xtext.expressions.expression.FunctionDecl
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope

import static extension nl.esi.xtext.expressions.utilities.ExpressionsUtilities.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*

/**
 * Custom scope for function call resolution with three-phase matching strategy:
 * 1. Exact match: name + argument count + compatible types
 * 2. Size match: name + argument count (enables "type mismatch" errors)
 * 3. Name match: any overload (enables "wrong argument count" errors)
 * 
 * Fallback strategy provides specific error messages rather than generic "function not found".
 */
class FunctionOverloadScope implements IScope {
    
    val IScope parent
    val ExpressionFunctionCall context
    
    new(IScope parent, ExpressionFunctionCall context) {
        this.parent = parent
        this.context = context
    }
    
    override getAllElements() {
        parent.allElements
    }
    
    override getElements(QualifiedName name) {
        val candidates = parent.getElements(name).toList
        
        if (candidates.empty) {
            return emptyList
        }
        
        // Phase 1: Exact match (name + arity + types)
        val exactMatches = candidates.filter[matchesExactly(it)]
        if (!exactMatches.empty) {
            return exactMatches
        }
        
        // Phase 2: Size match (name + arity) - enables type mismatch errors
        val sizeMatches = candidates.filter[matchesSize(it)]
        if (!sizeMatches.empty) {
            return #[sizeMatches.head] // First match to avoid ambiguity
        }
        
        // Phase 3: Name match - enables wrong argument count errors
        return #[candidates.head]
    }
    
    override getElements(EObject object) {
        parent.getElements(object)
    }
    
    override getSingleElement(QualifiedName name) {
        val elements = getElements(name)
        return elements.empty ? null : elements.head
    }
    
    override getSingleElement(EObject object) {
        parent.getSingleElement(object)
    }
    
    /** Checks if function matches by name, argument count, and all parameter types */
    private def boolean matchesExactly(IEObjectDescription desc) {
        val fd = desc.EObjectOrProxy as FunctionDecl
        if (fd.params.size != context.args.size) {
            return false
        }
        
        for (var i = 0; i < fd.params.size; i++) {
            val param = fd.params.get(i)
            val arg = context.args.get(i)
            val actualType = param.type.inferActualType(arg)?.typeObject
            val argType = typeOf(arg)
            if (!argType.subTypeOf(actualType)) {
                return false
            }
        }
        
        return true
    }
    
    /** Checks if function matches by argument count only */
    private def boolean matchesSize(IEObjectDescription desc) {
        val fd = desc.EObjectOrProxy as FunctionDecl
        return fd.params.size == context.args.size
    }
}
