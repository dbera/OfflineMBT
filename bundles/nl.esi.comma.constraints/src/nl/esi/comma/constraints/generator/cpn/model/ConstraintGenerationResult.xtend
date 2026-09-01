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
package nl.esi.comma.constraints.generator.cpn.model

class ConstraintGenerationResult {
    val String pspecFileName
    val String acceptanceJsonFileName
    val String acceptancePythonFileName
    val String constraintFolderName
    
    

    new(
        String pspecFileName,
        String acceptanceJsonFileName,
        String acceptancePythonFileName,
        String constraintFolderName
    ) {
        this.pspecFileName = pspecFileName
        this.acceptanceJsonFileName = acceptanceJsonFileName
        this.acceptancePythonFileName = acceptancePythonFileName
        this.constraintFolderName = constraintFolderName
    }

    def String getPspecFileName() {
        pspecFileName
    }

    def String getAcceptanceJsonFileName() {
        acceptanceJsonFileName
    }

    def String getAcceptancePythonFileName() {
        acceptancePythonFileName
    }
    
    def String getConstraintFolderName() {
        constraintFolderName
    }
}