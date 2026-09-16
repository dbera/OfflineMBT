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

class RefInfo {
    var refType = new String
    var refName = new String
    
    new() {
        refType = new String
        refName = new String
    }
    
    new (String _refType, String _refName) {
        refType = _refType
        refName = _refName
    }
    
    def getRefType() { return refType}
    def getRefName() { return refName}
}