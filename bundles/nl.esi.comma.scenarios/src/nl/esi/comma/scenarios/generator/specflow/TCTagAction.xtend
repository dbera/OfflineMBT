/*
 * (C) Copyright 2018 TNO-ESI.
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