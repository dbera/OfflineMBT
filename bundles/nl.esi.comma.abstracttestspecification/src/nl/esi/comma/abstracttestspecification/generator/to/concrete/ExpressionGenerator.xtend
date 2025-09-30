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
package nl.esi.comma.abstracttestspecification.generator.to.concrete

import nl.esi.comma.abstracttestspecification.abstractTestspecification.StepReference
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.generator.ExpressionsCommaGenerator
import org.eclipse.emf.common.util.EList

class ExpressionGenerator extends ExpressionsCommaGenerator {
    EList<StepReference> stepRef
    String BlockInputName
    String varRefName

    new(EList<StepReference> stepRef, String BlockInputName, String varRefName) {
        this.stepRef = stepRef
        this.BlockInputName = BlockInputName
        this.varRefName = varRefName
    }

    override dispatch CharSequence exprToComMASyntax(ExpressionVariable e) {
        var vname = e.getVariable().getName()
        for (sf : this.stepRef) {
            for (rd : sf.refData) {
                if (vname.equals(rd.name)) {
                    vname = "step_" + sf.refStep.name + ".output." + vname
                }
            }
        }
        // Experiment DB. RHS cannot have input to run step expression! 03.09.2025
        /*
         * if (vname.equals(varRefName)) {
         *     vname = this.BlockInputName.split("_").get(0) + "Input" + "." + vname
         * } else {
         *     for (sf : this.stepRef) {
         *         for (rd : sf.refData) {
         *             if (vname.equals(rd.name)) {
         *                 vname = "step_" + sf.refStep.name + ".output." + vname
         *             }
         *         }
         *     }
         }*/
        return '''«vname»'''
    }

}
