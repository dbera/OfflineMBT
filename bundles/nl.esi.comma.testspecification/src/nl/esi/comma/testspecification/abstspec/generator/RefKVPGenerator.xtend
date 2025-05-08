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
package nl.esi.comma.testspecification.abstspec.generator

import nl.esi.comma.assertthat.assertThat.AssertThatBlock
import nl.esi.comma.assertthat.assertThat.AssertThatValue
import nl.esi.comma.assertthat.assertThat.AssertThatValueClose
import nl.esi.comma.assertthat.assertThat.AssertThatValueEq
import nl.esi.comma.assertthat.assertThat.AssertThatValueIdentical
import nl.esi.comma.assertthat.assertThat.AssertThatValueMatch
import nl.esi.comma.assertthat.assertThat.AssertThatValueSimilar
import nl.esi.comma.assertthat.assertThat.AssertThatValueSize
import nl.esi.comma.assertthat.assertThat.AssertThatXMLFile
import nl.esi.comma.assertthat.assertThat.AssertThatXPaths
import nl.esi.comma.assertthat.assertThat.AssertValidation
import nl.esi.comma.assertthat.assertThat.ComparisonsForMultiReference
import nl.esi.comma.assertthat.assertThat.ComparisonsForSingleReference
import nl.esi.comma.assertthat.assertThat.GenericScriptBlock
import nl.esi.comma.assertthat.assertThat.MARGIN_TYPE
import nl.esi.comma.assertthat.assertThat.MargingItem
import nl.esi.comma.testspecification.testspecification.AbstractTestDefinition
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.assertthat.assertThat.ScriptParameterNamedPositional
import nl.esi.comma.assertthat.assertThat.ScriptParameterNameOnly
import nl.esi.comma.assertthat.assertThat.ScriptParameterNamed
import nl.esi.comma.assertthat.assertThat.ScriptParameterWithValue
import nl.esi.comma.assertthat.assertThat.ScriptParameterNamedArg
import nl.esi.comma.assertthat.assertThat.ScriptParameterPositional
import nl.esi.comma.assertthat.assertThat.ScriptParameterPositionalFile
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.testspecification.testspecification.RunStep

class RefKVPGenerator {
    def generateRefKVP(AbstractTestDefinition atd) {
        var txt = 
        '''
        matlab_calls=[
        «FOR testseq : atd.testSeq»
            «FOR step : testseq.step.filter(AssertionStep) »
            «FOR asrtce : step.asserts » 
            «FOR ce : asrtce.ce»
                «FOR mlcal : ce.constr.filter(GenericScriptBlock) SEPARATOR ',' »
                {
                    "id":"«mlcal.assignment.name»", 
                    "script_path":"«mlcal.params.scriptApi»",
                    "parameters":[
                        {
                            "type": "OUTPUT",
                            "value":"«mlcal.params.scriptOut»"
                        }«IF ! mlcal.params.scriptArgs.empty»,
                        «FOR param : mlcal.params.scriptArgs SEPARATOR ","»
                        {
                            «IF param instanceof ScriptParameterNamed»"name": "«getScriptParamName(param)»",
                            «ENDIF»"type": "«getScriptParamType(param)»"«IF param instanceof ScriptParameterWithValue»,
                            "value": «expression(param, step)»«ENDIF»
                        }
                        «ENDFOR»
                        «ENDIF»
                    ]
                }
                «ENDFOR»
            «ENDFOR»
            «ENDFOR»
            «ENDFOR»
        «ENDFOR»
        ]

        assertions = [
        «FOR testseq : atd.testSeq»
            «FOR step : testseq.step.filter(AssertionStep) » 
            «FOR asrtce : step.asserts »
            «FOR ce : asrtce.ce»
                «FOR asrt : ce.constr.filter(AssertThatBlock) SEPARATOR ',' »
                {
                    "id":"«asrt.identifier»", "type":"«getAssertionType(asrt.^val)»",
                    "input":{
                        "output":«expression(asrt, step)»,
                        «extractAssertionParams(asrt.^val, step)»
                    }
                }
                «ENDFOR»
            «ENDFOR»
            «ENDFOR»
            «ENDFOR»
        «ENDFOR»
        ]
        '''
        return txt
    }

    def String getScriptParamType(ScriptParameterNamedPositional param){
        if (param instanceof ScriptParameterNameOnly) return "NAME_ONLY"
        if (param instanceof ScriptParameterNamedArg) {
            var type = param.file? "FILE" : "VALUE"
            if (isScriptParamTypeNonConstant(param.^val)) type+="_REF"
            return type
        }
        if (param instanceof ScriptParameterPositional) {
            var type = param instanceof ScriptParameterPositionalFile? "FILE" : "VALUE"
            if (isScriptParamTypeNonConstant(param.^val)) type+="_REF"
            return type
        }
        throw new RuntimeException("Not supported")
    }

    def String getScriptParamName(ScriptParameterNamed param){
        switch (param){
            ScriptParameterNameOnly: return param.label
            ScriptParameterNamedArg: return param.label
        }
        throw new RuntimeException("Not supported")
    }

    def Expression getScriptParamExpression(ScriptParameterWithValue param){
        switch (param){
            ScriptParameterNamedArg: return param.^val
            ScriptParameterPositionalFile: return param.^val
            ScriptParameterPositional: return param.^val
        }
        throw new RuntimeException("Not supported")
    }

    def String expression(AssertThatBlock asrt, AssertionStep step) {
        var expr = asrt.output
        var prefix = getExpressionPrefix(expr,step)
        return expression(expr,prefix)
    }

    def String expression(ScriptParameterWithValue param, AssertionStep step) {
        var expr = getScriptParamExpression(param)
        var prefix = getExpressionPrefix(expr,step)
        return expression(expr,prefix)
    }

    def String getExpressionPrefix(Expression expr, AssertionStep step) {
        switch (expr){
            ExpressionBracket: return getExpressionPrefix(expr.sub,step)
            ExpressionRecordAccess: return getExpressionPrefix(expr.record,step)
            ExpressionMapRW: return getExpressionPrefix(expr.map,step)
            ExpressionVariable: return getExpressionPrefix(expr,step)
            ExpressionConstantBool: return ""
            ExpressionConstantInt: return ""
            ExpressionConstantReal: return ""
            ExpressionConstantString: return ""
        }
        throw new RuntimeException("Not supported")
    }

    def String getExpressionPrefix(ExpressionVariable expr, AssertionStep step) {
        var vari = expr.variable
        if (vari.eContainer instanceof GenericScriptBlock) return "['matlab_script']"
        else return "['step_output']"+getExpressionInfix(expr, step)
    }

    private def String getExpressionInfix(ExpressionVariable expr, AssertionStep assertStep) {
        for (consumesFrom : assertStep.stepRef) {
            if(consumesFrom.refStep instanceof RunStep){
                for (step : consumesFrom.refData) {
                	// TODO check if this is the right way to find the step from which an input is consumed
                	if (step.name == expr.variable.name){ 
                	    return String.format("['%s']",consumesFrom.refStep.name)
                	}
                }
            }
        }
        return "" // TODO Check if this exception case is correct
    }

    def String expression(Expression expr, String prefix) {
        switch (expr) {
            ExpressionBracket: return expression(expr.sub,prefix)
            // referencing variable value
            ExpressionVariable: return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
            ExpressionRecordAccess: return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
            ExpressionMapRW: return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
            ExpressionVector: return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
            // constant values
            ExpressionConstantBool: return String.format("%s", AssertionsHelper.expression(expr))
            ExpressionConstantInt: return String.format("%s", AssertionsHelper.expression(expr))
            ExpressionConstantReal: return String.format("%s", AssertionsHelper.expression(expr))
            ExpressionConstantString: return String.format("%s", AssertionsHelper.expression(expr))
        }
        throw new RuntimeException("Not supported")
    }

    def Boolean isScriptParamTypeNonConstant(Expression param) {
        switch (param) {
            ExpressionVariable: return true
            ExpressionRecordAccess: return true
            ExpressionMapRW: return true
            ExpressionVector: return true
        }
        return false
    }

    /**
     * Parses input parameters of an assertion type into string format. 
     * @param assertion Assertion of type value, xpaths or xmlfile
     */
    def String extractAssertionParams(AssertValidation params, AssertionStep step) {
        switch (params){
            AssertThatValue:   return extractAssertionParams(params.comparisonType)
            AssertThatXPaths:  return extractAssertionParams(params)
            AssertThatXMLFile: return extractAssertionParams(params, step)
        }
        throw new RuntimeException("Not supported")
    }

    /**
     * Parses input parameters of parameters for an assertion comparing output against a single reference value. 
     * @param assertion Assertion parameters of type equality, closeness, regex-matching, size-of
     */
    def String extractAssertionParams(ComparisonsForSingleReference compType) {
        switch(compType){
            AssertThatValueEq:     return extractAssertionParams(compType)
            AssertThatValueClose:  return extractAssertionParams(compType)
            AssertThatValueMatch:  return extractAssertionParams(compType)
            AssertThatValueSize:   return extractAssertionParams(compType)
        }
        throw new RuntimeException("Not supported")
    }

    /**
     * Parses input parameters of parameters for an assertion comparing output against a multi-reference value. 
     * @param assertion Assertion parameters of type identical (as equality), similarity (as closeness)
     */
    def String extractAssertionParams(ComparisonsForMultiReference compType) {
        if (compType instanceof AssertThatValueIdentical) return ""
        if (compType instanceof AssertThatValueSimilar) {
            if (compType.margin === null) return ""
            else return extractAssertionParams(compType.margin)
        }
        throw new RuntimeException("Not supported")
    }

    def String extractAssertionParams(AssertThatValueEq value) {
        return '''
        "reference":«JsonHelper.jsonElement(value.reference)»«IF value.margin instanceof MargingItem»,
        «extractAssertionParams(value.margin)»
        «ENDIF»«
        IF value.asRegex»,
        "regex":True«ENDIF»
        '''
    }
    def String extractAssertionParams(AssertThatValueClose value) {
        return '''
        "reference":«JsonHelper.jsonElement(value.reference)»«IF value.margin instanceof MargingItem»,
        «extractAssertionParams(value.margin)»
        «ENDIF»
        '''
    }
    def String extractAssertionParams(AssertThatValueMatch value) {
        return '''
        "reference":«JsonHelper.jsonElement(value.reference)»,
        "regex":True
        '''
    }
    def String extractAssertionParams(AssertThatValueSize value) {
        return '''
        "reference":«value.reference»,
        "size_compare":True
        '''
    }
    def String extractAssertionParams(MargingItem marginitem) {
        return '''
        "margin":«IF marginitem.type.equals(MARGIN_TYPE.NONE)»None«
        ELSEIF marginitem.type.equals(MARGIN_TYPE.ABSOLUTE)»{"type":"Absolute", "value":«marginitem.marginVal»}«
        ELSEIF marginitem.type.equals(MARGIN_TYPE.RELATIVE)»{"type":"Relative", "value":«marginitem.marginVal»}«ENDIF»
        '''
    }
    def String extractAssertionParams(AssertThatXPaths paths) {
        return '''
        "xpaths":[
                «FOR anAssert : paths.assertRef SEPARATOR ","»
                    {
                        «IF anAssert.loggingId !== null »"id":"«anAssert.loggingId»",«ENDIF»
                        "xpath":"«anAssert.xpath»",
                        «extractAssertionParams(anAssert.comparisonType)»
                    }
                «ENDFOR»
        ]«IF paths.namespace !== null»,
        "namespaces":«JsonHelper.jsonElement(paths.namespace.namespaceMap)»«ENDIF»
        '''
    }
    def String extractAssertionParams(AssertThatXMLFile xmlfile, AssertionStep step) {
        var expr = xmlfile.reference
        var prefix = getExpressionPrefix(expr,step)
        return '''
        "reference":«expression(expr,prefix)»,
        "xpaths":[
                «FOR anAssert : xmlfile.assertRef SEPARATOR ","»
                    {
                        «IF anAssert.loggingId !== null »"id":"«anAssert.loggingId»",«ENDIF»
                        "xpath":"«anAssert.xpath»"«IF !(anAssert.comparisonType instanceof AssertThatValueIdentical)»
                        «extractAssertionParams(anAssert.comparisonType)» «ENDIF»
                    }
                «ENDFOR»
        ]«IF xmlfile.namespace !== null»,
        "namespaces":«JsonHelper.jsonElement(xmlfile.namespace.namespaceMap)»«ENDIF»«IF xmlfile.globalMargin !== null»«IF xmlfile.globalMargin.margin !== null»,
        «extractAssertionParams(xmlfile.globalMargin.margin)»
        «ENDIF»«ENDIF»
        '''
    }

    def getAssertionType(AssertValidation asrt){
        switch (asrt){
            AssertThatValue: return "Value" // assertion of type Value
            AssertThatXPaths: return "XPaths" // assertion of type XPaths
            AssertThatXMLFile: return "XMLFile" // assertion of type XMLFile
        }
        throw new RuntimeException("Not supported")
    }
}