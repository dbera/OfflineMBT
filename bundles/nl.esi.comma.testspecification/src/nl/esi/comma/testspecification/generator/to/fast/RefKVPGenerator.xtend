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
package nl.esi.comma.testspecification.generator.to.fast

import java.util.ArrayList
import java.util.List
import java.util.stream.Collectors
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
import nl.esi.comma.assertthat.assertThat.ScriptParameterNameOnly
import nl.esi.comma.assertthat.assertThat.ScriptParameterNamed
import nl.esi.comma.assertthat.assertThat.ScriptParameterNamedArg
import nl.esi.comma.assertthat.assertThat.ScriptParameterNamedPositional
import nl.esi.comma.assertthat.assertThat.ScriptParameterPositional
import nl.esi.comma.assertthat.assertThat.ScriptParameterPositionalFile
import nl.esi.comma.assertthat.assertThat.ScriptParameterWithValue
import nl.esi.comma.expressions.expression.Expression
import nl.esi.comma.expressions.expression.ExpressionBracket
import nl.esi.comma.expressions.expression.ExpressionConstantBool
import nl.esi.comma.expressions.expression.ExpressionConstantInt
import nl.esi.comma.expressions.expression.ExpressionConstantReal
import nl.esi.comma.expressions.expression.ExpressionConstantString
import nl.esi.comma.expressions.expression.ExpressionMapRW
import nl.esi.comma.expressions.expression.ExpressionRecordAccess
import nl.esi.comma.expressions.expression.ExpressionVariable
import nl.esi.comma.expressions.expression.ExpressionVector
import nl.esi.comma.testspecification.testspecification.AssertionStep
import nl.esi.comma.testspecification.testspecification.TestDefinition

class RefKVPGenerator {
    def generateRefKVP(TestDefinition atd) {
        var constraints = atd.testSeq.flatMap[it.stepSeqRef] // for-all test sequence
                                     .flatMap[it.step].filter(AssertionStep) // for-all assertion steps
                                     .flatMap[it.asserts].flatMap[it.constr] // fetch all constraints
        var hasScripts = ! constraints.filter(GenericScriptBlock).empty // any script-block?
        var hasAsserts = ! constraints.filter(AssertThatBlock).empty    // any assertion?
        var txt = ''
        if (hasScripts)
            txt += '''
                matlab_calls=[
                    «FOR testseq : atd.testSeq SEPARATOR ','»
                        «FOR step : testseq.stepSeqRef.flatMap[it.step].filter(AssertionStep) SEPARATOR ',' »
                            «FOR mlcal : step.asserts.flatMap[it.constr].filter(GenericScriptBlock) SEPARATOR ',' »
                                {
                                    "id":"«getScriptId(mlcal,step)»", 
                                    "script_path":"«mlcal.params.scriptApi»",
                                    "parameters":[
                                        {
                                            "type": "OUTPUT",
                                            "value":"«mlcal.params.scriptOut»"
                                        }«FOR param : mlcal.params.scriptArgs BEFORE "," SEPARATOR ","»
                                            {
                                                «IF param instanceof ScriptParameterNamed»"name": "«getScriptParamName(param)»",«ENDIF»
                                                "type": "«getScriptParamType(param)»"«IF param instanceof ScriptParameterWithValue»,
                                                "value": «expression(param, step)»«ENDIF»
                                        }«ENDFOR»
                                    ]
                                }
                            «ENDFOR»
                        «ENDFOR»
                    «ENDFOR»
                ]
                
            '''

        if (hasAsserts)
            txt += '''
                asserts = [
                    «FOR testseq : atd.testSeq SEPARATOR ','»
                        «FOR step : testseq.stepSeqRef.flatMap[it.step].filter(AssertionStep) SEPARATOR ',' »
                            «FOR asrt : step.asserts.flatMap[it.constr].filter(AssertThatBlock) SEPARATOR ',' »
                                {
                                    "id":"«getScriptId(asrt,step)»", "type":"«getAssertionType(asrt.^val)»",
                                    "input":{
                                        "output":«expression(asrt, step)»,
                                        «extractAssertionParams(asrt.^val, step)»
                                    }
                                }
                            «ENDFOR»
                        «ENDFOR»
                    «ENDFOR»
                ]
                
            '''
        return txt
    }

    def String getScriptParamType(ScriptParameterNamedPositional param) {
        if(param instanceof ScriptParameterNameOnly) return "NAME_ONLY"
        if (param instanceof ScriptParameterNamedArg) {
            var type = param.file ? "FILE" : "VALUE"
            if(isScriptParamTypeNonConstant(param.^val)) type += "_REF"
            return type
        }
        if (param instanceof ScriptParameterPositional) {
            var type = param instanceof ScriptParameterPositionalFile ? "FILE" : "VALUE"
            if(isScriptParamTypeNonConstant(param.^val)) type += "_REF"
            return type
        }
        throw new RuntimeException("Not supported")
    }

    def String getScriptParamName(ScriptParameterNamed param) {
        switch (param) {
            ScriptParameterNameOnly: return param.label
            ScriptParameterNamedArg: return param.label
        }
        throw new RuntimeException("Not supported")
    }

    def Expression getScriptParamExpression(ScriptParameterWithValue param) {
        switch (param) {
            ScriptParameterNamedArg: return param.^val
            ScriptParameterPositionalFile: return param.^val
            ScriptParameterPositional: return param.^val
        }
        throw new RuntimeException("Not supported")
    }

    def String expression(AssertThatBlock asrt, AssertionStep step) {
        var expr = asrt.output
        var prefix_list = getExpressionPrefix(expr, step)
        prefix_list = expression(expr, prefix_list)
        prefix_list.remove(2) // remove ".output."
        var prefix = prefix_list.stream().map(s|String.format("['%s']", s)).collect(Collectors.joining());
        return String.format('"%s"', prefix)
    }

    def String expression(ScriptParameterWithValue param, AssertionStep step) {
        var expr = getScriptParamExpression(param)
        var prefix_list = getExpressionPrefix(expr, step)
        prefix_list = expression(expr, prefix_list)
        prefix_list.remove(2) // remove ".output."
        var prefix = prefix_list.stream().map(s|String.format("['%s']", s)).collect(Collectors.joining());
        return String.format('"%s"', prefix)
    }

    def List<String> getExpressionPrefix(Expression expr, AssertionStep step) {
        var List<String> fields = new ArrayList
        switch (expr) {
            ExpressionBracket: fields.addAll(getExpressionPrefix(expr.sub, step))
            ExpressionRecordAccess: fields.addAll(getExpressionPrefix(expr.record, step))
            ExpressionMapRW: fields.addAll(getExpressionPrefix(expr.map, step))
            ExpressionVariable: fields.addAll(getExpressionPrefix(expr, step))
            default: throw new RuntimeException("Not supported")
        }
        return fields
    }

    def List<String> getExpressionPrefix(ExpressionVariable expr, AssertionStep step) {
        var List<String> fields = new ArrayList
        var vari = expr.variable.eContainer
        if (vari instanceof GenericScriptBlock) {
            fields.add("matlab_script")
            fields.add(getScriptId(vari, step))
        } else
            fields.add("step_output")
        return fields
    }

    def String getScriptId(GenericScriptBlock block, AssertionStep assertStep) {
        return getDatacheckId(block.name, assertStep)
    }

    def String getScriptId(AssertThatBlock block, AssertionStep assertStep) {
        return getDatacheckId(block.name, assertStep)
    }

    def getDatacheckId(String label, AssertionStep assertStep) {
        return String.format(
            "%s__@__%s",
            label,
            assertStep.inputVar.name
        )
    }

    def List<String> expression(Expression expr, List<String> prefix) {
        switch (expr) {
            ExpressionBracket:
                expression(expr.sub, prefix)
            // referencing variable value
            ExpressionVariable:
                prefix.add(expr.variable.name)
            ExpressionRecordAccess: {
                expression(expr.record, prefix)
                prefix.add(expr.field.name)
            }
            default:
                throw new RuntimeException("Not supported")
        }
        return prefix
    }

    def String expression(Expression expr) {
        return expression(expr, '')
    }

    def String expression(Expression expr, String prefix) {
        switch (expr) {
            ExpressionBracket: return expression(expr.sub, prefix)
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
        switch (params) {
            AssertThatValue: return extractAssertionParams(params.comparisonType)
            AssertThatXPaths: return extractAssertionParams(params)
            AssertThatXMLFile: return extractAssertionParams(params, step)
        }
        throw new RuntimeException("Not supported")
    }

    /**
     * Parses input parameters of parameters for an assertion comparing output against a single reference value. 
     * @param assertion Assertion parameters of type equality, closeness, regex-matching, size-of
     */
    def String extractAssertionParams(ComparisonsForSingleReference compType) {
        switch (compType) {
            AssertThatValueEq: return extractAssertionParams(compType)
            AssertThatValueClose: return extractAssertionParams(compType)
            AssertThatValueMatch: return extractAssertionParams(compType)
            AssertThatValueSize: return extractAssertionParams(compType)
        }
        throw new RuntimeException("Not supported")
    }

    /**
     * Parses input parameters of parameters for an assertion comparing output against a multi-reference value. 
     * @param assertion Assertion parameters of type identical (as equality), similarity (as closeness)
     */
    def String extractAssertionParams(ComparisonsForMultiReference compType) {
        if(compType instanceof AssertThatValueIdentical) return ""
        if (compType instanceof AssertThatValueSimilar) {
            if(compType.margin === null) return "" else return extractAssertionParams(compType.margin)
        }
        throw new RuntimeException("Not supported")
    }

    def String extractAssertionParams(AssertThatValueEq value) {
        return '''
            "reference":«JsonHelper.jsonElement(value.reference)»«IF value.margin instanceof MargingItem»,
                «extractAssertionParams(value.margin)»
            «ENDIF»«IF value.asRegex»,
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
            "margin":«IF marginitem.type.equals(MARGIN_TYPE.NONE)»None«ELSEIF marginitem.type.equals(MARGIN_TYPE.ABSOLUTE)»{"type":"Absolute", "value":«marginitem.marginVal»}«ELSEIF marginitem.type.equals(MARGIN_TYPE.RELATIVE)»{"type":"Relative", "value":«marginitem.marginVal»}«ENDIF»
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
            "namespaces":«JsonHelper.jsonElement(paths.namespace.namespaceMap)»«ENDIF»«IF paths.globalMargin !== null»«IF paths.globalMargin.margin !== null»,
                «extractAssertionParams(paths.globalMargin.margin)»
            «ENDIF»«ENDIF»
        '''
    }

    def String extractAssertionParams(AssertThatXMLFile xmlfile, AssertionStep step) {
        var expr = xmlfile.reference
        var prefix_list = getExpressionPrefix(expr, step)
        var prefix = prefix_list.stream().map(s|String.format("['%s']", s)).collect(Collectors.joining());
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

    def getAssertionType(AssertValidation asrt) {
        switch (asrt) {
            AssertThatValue: return "Value" // assertion of type Value
            AssertThatXPaths: return "XPaths" // assertion of type XPaths
            AssertThatXMLFile: return "XMLFile" // assertion of type XMLFile
        }
        throw new RuntimeException("Not supported")
    }
}
