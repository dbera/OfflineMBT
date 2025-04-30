package nl.esi.comma.testspecification.abstspec.generator

import java.util.ArrayList
import org.eclipse.emf.common.util.EList

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
import nl.esi.comma.testspecification.testspecification.AbstractStep
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

class RefKVPGenerator {
    def generateRefKVP(AbstractTestDefinition atd) {
        var txt = 
        '''
        matlab_calls=[
        «FOR test : atd.testSeq»
            «FOR assertionStep : test.step.filter(AssertionStep) »
            «FOR step : assertionStep.asserts » «FOR ce : step.ce»
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
                            "value": «expression(getScriptParamExpression(param))»«ENDIF»
                        }
                        «ENDFOR»
                        «ENDIF»
                    ]
                }
                «ENDFOR»
            «ENDFOR»«ENDFOR»
            «ENDFOR»
        ]

        assertions = [
        «FOR assertionStep : test.step.filter(AssertionStep) »
            «FOR step : assertionStep.asserts »
            «FOR ce : step.ce»
            «FOR asrt : ce.constr.filter(AssertThatBlock) SEPARATOR ',' »
            {
                "id":"«asrt.identifier»", "type":"«getAssertionType(asrt.^val)»",
                "input":{
                    "output":«expression(asrt.output)»,
                    «extractAssertionParams(asrt.^val)»
                }
            }
            «ENDFOR»
            «ENDFOR»
            «ENDFOR»
            «ENDFOR»
        ]
        «ENDFOR»
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
        if (param instanceof ScriptParameterNameOnly) return param.label
        if (param instanceof ScriptParameterNamedArg) return param.label
        throw new RuntimeException("Not supported")
    }

    def Expression getScriptParamExpression(ScriptParameterWithValue param){
        if (param instanceof ScriptParameterNamedArg) return param.^val
        if (param instanceof ScriptParameterPositionalFile) return param.^val
        if (param instanceof ScriptParameterPositional) return param.^val
        throw new RuntimeException("Not supported")
    }

    def String expression(Expression expr) {
        return expression(expr,"['step_output']")
    }

    def String expression(Expression expr, String prefix) {
        // referencing variable value
        if (expr instanceof ExpressionVariable) return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
        if (expr instanceof ExpressionRecordAccess) return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
        if (expr instanceof ExpressionMapRW) return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
        if (expr instanceof ExpressionVector) return String.format("\"%s%s\"", prefix, AssertionsHelper.expression(expr))
        // constant values
        if (expr instanceof ExpressionConstantBool) return String.format("%s", AssertionsHelper.expression(expr))
        if (expr instanceof ExpressionConstantInt) return String.format("%s", AssertionsHelper.expression(expr))
        if (expr instanceof ExpressionConstantReal) return String.format("%s", AssertionsHelper.expression(expr))
        if (expr instanceof ExpressionConstantString) return String.format("%s", AssertionsHelper.expression(expr))
        throw new RuntimeException("Not supported")
    }


    def Boolean isScriptParamTypeNonConstant(Expression param) {
        if (param instanceof ExpressionVariable) return true
        if (param instanceof ExpressionRecordAccess) return true
        if (param instanceof ExpressionMapRW) return true
        if (param instanceof ExpressionVector) return true
        return false
    }

    /**
     * Parses input parameters of an assertion type into string format. 
     * @param assertion Assertion of type value, xpaths or xmlfile
     */
    def String extractAssertionParams(AssertValidation params) {
        if (params instanceof AssertThatValue)   return extractAssertionParams(params.comparisonType)
        if (params instanceof AssertThatXPaths)  return extractAssertionParams(params)
        if (params instanceof AssertThatXMLFile) return extractAssertionParams(params)
        throw new RuntimeException("Not supported")
    }

    /**
     * Parses input parameters of parameters for an assertion comparing output against a single reference value. 
     * @param assertion Assertion parameters of type equality, closeness, regex-matching, size-of
     */
    def String extractAssertionParams(ComparisonsForSingleReference compType) {
        if (compType instanceof AssertThatValueEq)    return extractAssertionParams(compType)
        if (compType instanceof AssertThatValueClose) return extractAssertionParams(compType)
        if (compType instanceof AssertThatValueMatch) return extractAssertionParams(compType)
        if (compType instanceof AssertThatValueSize)  return extractAssertionParams(compType)
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
    def String extractAssertionParams(AssertThatXMLFile xmlfile) {
        return '''
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
        if (asrt instanceof AssertThatValue) return "Value" // assertion of type Value
        if (asrt instanceof AssertThatXPaths) return "XPaths" // assertion of type XPaths
        if (asrt instanceof AssertThatXMLFile) return "XMLFile" // assertion of type XMLFile
        throw new RuntimeException("Not supported")
    }
}