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
package nl.esi.comma.scenarios.generator.specflow

import nl.esi.comma.expressions.expression.Expression

class TCTagAction {
    
    boolean command = false 
    String tagText = ""
    Expression[] data
    
    new(boolean comd, String tagText, Expression[] data){
        this.command = comd
        this.tagText = tagText
        this.data = data
    }
    
    def getTagText(){
        return this.tagText
    }
    
    def getComd(){
        return this.command
    }
    
    def getData(){
        return this.data
    }
}