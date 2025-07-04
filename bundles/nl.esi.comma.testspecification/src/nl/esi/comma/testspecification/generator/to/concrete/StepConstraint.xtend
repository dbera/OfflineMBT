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
package nl.esi.comma.testspecification.generator.to.concrete

class StepConstraint 
{
    public var composeStepName = new String
    public var runStepName = new String
    public var lhs = new String
    public var rhs = new String
    public var text = new String

    new(String runStepName, String composeStepName, String lhs, String rhs, String text) {
        this.runStepName = runStepName
        this.composeStepName = composeStepName
        this.lhs = lhs
        this.rhs = rhs
        this.text = text
    }
    
    def getComposeStepName() { return composeStepName }
    def getRunStepName() { return runStepName }
    def getLHS() { return lhs }
    def getRHS() { return rhs }
    def getText() { return text }

    def void print(StepConstraint sc) {
        System.out.println(" RUN-STEP-NAME: " + runStepName)
        System.out.println(" COMPOSE-STEP-NAME: " + composeStepName)
        sc.printLHSandRHS()
    }

    def printLHSandRHS() {
        System.out.println("    -> LHS: " + lhs + "  RHS: " + rhs)
    }
}
