/**
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
/*
 * generated by Xtext 2.29.0
 */
package nl.asml.matala.product.scoping;

import nl.asml.matala.product.product.Block
import nl.asml.matala.product.product.Update
import nl.asml.matala.product.product.UpdateOutVar
import nl.esi.comma.actions.actions.ActionsPackage
import nl.esi.comma.expressions.expression.ExpressionPackage
import nl.esi.comma.expressions.expression.Variable
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

/**
 * This class contains custom scoping description.
 * 
 * See
 * https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class ProductScopeProvider extends AbstractProductScopeProvider {
    override getScope(EObject context, EReference reference) {
        logScope('Enter', context, reference)

        return switch (context) {
            Update case reference.isTypeDeclReference: {
                IScope.NULLSCOPE
            }
            UpdateOutVar case reference == ActionsPackage.Literals.ASSIGNMENT_ACTION__ASSIGNMENT,
            UpdateOutVar case reference == ExpressionPackage.Literals.EXPRESSION_VARIABLE__VARIABLE: {
                Scopes.scopeFor(context.fnOut.map[ref])
            }
            case reference.EType == ExpressionPackage.Literals.VARIABLE: {
                val scope = EcoreUtil2.getContainerOfType(context, Block)
                scope === null ? IScope.NULLSCOPE : Scopes.scopeFor(EcoreUtil2.getAllContentsOfType(scope, Variable))
            }
            default: {
                super.getScope(context, reference)
            }
        }
    }
}
