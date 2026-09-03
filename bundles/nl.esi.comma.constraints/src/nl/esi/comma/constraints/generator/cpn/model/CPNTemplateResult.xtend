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

class CPNTemplateResult {
    val String psBody
    val String acceptanceJson
    
    new(String psBody, String acceptanceJson) {
        this.psBody = psBody
        this.acceptanceJson = acceptanceJson
    }
    
    def String getPsBody() {
        return psBody
    }

    def String getAcceptanceJson() {
        return acceptanceJson
    } 
}