package nl.esi.comma.testspecification.generator.json

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

/**
 * Produces a compact semantic JSON tree for XPlus expressions.
 *
 * Only known semantic features are traversed. Unknown model elements are
 * represented as "unsupported" instead of recursively exporting arbitrary
 * EMF containment.
 */
class SemanticExpressionJsonSerializer {

    def Map<String, Object> serialize(EObject expression) {
        normalize(
            expression,
            new LinkedHashSet<EObject>
        ) as Map<String, Object>
    }

    private def Object normalize(
        EObject expression,
        Set<EObject> active
    ) {
        if (expression === null) {
            return null
        }

        if (active.contains(expression)) {
            return reference(expression)
        }

        active.add(expression)

        val result =
            switch expression.eClass.name {
                case "ExpressionVector":
                    vector(expression, active)

                case "ExpressionRecord":
                    record(expression, active)

                case "ExpressionRecordLiteral":
                    record(expression, active)

                case "ExpressionMap":
                    mapExpression(expression, active)

                case "ExpressionMapRW":
                    mapAccess(expression, active)

                case "ExpressionMapEntry":
                    mapEntry(expression, active)

                case "ExpressionVariable":
                    variable(expression)

                case "ExpressionRecordAccess":
                    featureAccess(expression, active)

                case "ExpressionBracket":
                    bracket(expression, active)

                case "ExpressionConstantString":
                    literal(expression, "string")

                case "ExpressionConstantInt":
                    literal(expression, "integer")

                case "ExpressionConstantReal":
                    literal(expression, "real")

                case "ExpressionConstantBool":
                    literal(expression, "boolean")

                case "ExpressionNullLiteral":
                    nullLiteral(expression)

                case "ExpressionEnumLiteral":
                    enumLiteral(expression)

                case "ExpressionMinus":
                    unary(expression, "-", active)

                case "ExpressionNot":
                    unary(expression, "not", active)

                case "ExpressionConditional":
                    conditional(expression, active)

                case "ExpressionNullCoalescing":
                    binary(expression, "??", active)

                case "ExpressionFunctionCall":
                    functionCall(expression, active)

                default:
                    normalizeByShape(
                        expression,
                        active
                    )
            }

        active.remove(expression)
        result
    }

    private def Object normalizeByShape(
        EObject expression,
        Set<EObject> active
    ) {
        val className =
            expression.eClass.name.toLowerCase

        if (
            className.contains("vector") ||
            className.contains("collection") ||
            className.contains("array") ||
            className.contains("list")
        ) {
            return vector(expression, active)
        }

        if (
            className.contains("map") &&
            className.contains("entry")
        ) {
            return mapEntry(expression, active)
        }

        if (className.contains("map")) {
            return mapExpression(expression, active)
        }

        if (
            className.contains("record") &&
            !className.contains("access") &&
            !className.contains("assignment")
        ) {
            return record(expression, active)
        }

        if (
            className.contains("recordaccess") ||
            className.contains("featureaccess") ||
            className.contains("fieldaccess")
        ) {
            return featureAccess(
                expression,
                active
            )
        }

        if (
            className.contains("function") ||
            className.contains("operation") ||
            className.contains("call")
        ) {
            return functionCall(
                expression,
                active
            )
        }

        if (
            className.contains("conditional") ||
            className.contains("ternary")
        ) {
            return conditional(
                expression,
                active
            )
        }

        if (className.contains("coalesc")) {
            return binary(
                expression,
                "??",
                active
            )
        }

        if (isBinary(expression)) {
            return binary(
                expression,
                operator(expression),
                active
            )
        }

        if (isUnary(expression)) {
            return unary(
                expression,
                operator(expression),
                active
            )
        }

        if (
            className.contains("constant") ||
            className.contains("literal")
        ) {
            return genericLiteral(expression)
        }

        unsupported(expression)
    }

    private def Map<String, Object> vector(
        EObject expression,
        Set<EObject> active
    ) {
        val result = base(
            "list",
            expression
        )

        val elementType = named(
            firstObject(
                expression,
                #[
                    "type",
                    "elementType",
                    "vectorType"
                ]
            )
        )

        if (elementType !== null) {
            result.put(
                "elementType",
                elementType
            )
        }

        result.put(
            "items",
            normalizeList(
                expression,
                #[
                    "items",
                    "elements",
                    "values",
                    "expressions",
                    "args"
                ],
                active
            )
        )

        result
    }

    private def Map<String, Object> record(
        EObject expression,
        Set<EObject> active
    ) {
        val result = base(
            "record",
            expression
        )

        val typeName = named(
            firstObject(
                expression,
                #[
                    "type",
                    "recordType",
                    "decl"
                ]
            )
        )

        if (typeName !== null) {
            result.put("type", typeName)
        }

        val fields = new ArrayList<Object>

        for (
            field :
                firstList(
                    expression,
                    #[
                        "fields",
                        "assignments",
                        "members",
                        "values",
                        "entries"
                    ]
                )
        ) {
            fields.add(
                recordField(
                    field,
                    active
                )
            )
        }

        result.put("fields", fields)
        result
    }

    private def Map<String, Object> recordField(
        EObject field,
        Set<EObject> active
    ) {
        val result = base(
            "field",
            field
        )

        val fieldReference = firstObject(
            field,
            #[  
                "recordField",
                "field",
                "feature",
                "member"
            ]
        )

        val fieldName = named(fieldReference)

        if (fieldName === null) {
            val directName = attribute(
                field,
                #["name"]
            )

            if (directName !== null) {
                result.put(
                    "name",
                    directName
                )
            }
        } else {
            result.put(
                "name",
                fieldName
            )
        }

        val valueExpression = firstObject(
            field,
            #[
                "value",
                "exp",
                "expression",
                "rhs",
                "right"
            ]
        )

        if (valueExpression !== null) {
            result.put(
                "value",
                normalize(
                    valueExpression,
                    active
                )
            )
        }

        result
    }
    
    private def Map<String, Object> mapAccess(
        EObject expression,
        Set<EObject> active
    ) {
        val update = firstObject(expression, #["value"])
        val result = base(
            if (update === null) "mapAccess" else "mapUpdate",
            expression
        )
    
        result.put(
            "map",
            normalize(firstObject(expression, #["map"]), active)
        )
        result.put(
            "key",
            normalize(firstObject(expression, #["key"]), active)
        )
    
        if (update !== null) {
            result.put("value", normalize(update, active))
        }
    
        result
    }

    private def Map<String, Object> mapExpression(
        EObject expression,
        Set<EObject> active
    ) {
        val result = base(
            "map",
            expression
        )

        val entries = new ArrayList<Object>

        for (
            entry :
                firstList(
                    expression,
                    #[
                        "pairs",
                        "entries",
                        "items",
                        "elements",
                        "values"
                    ]
                )
        ) {
            entries.add(
                mapEntry(
                    entry,
                    active
                )
            )
        }

        result.put("entries", entries)
        result
    }

    private def Map<String, Object> mapEntry(
        EObject entry,
        Set<EObject> active
    ) {
        val result = base(
            "mapEntry",
            entry
        )

        val key = firstObject(
            entry,
            #[
                "key",
                "left",
                "lhs"
            ]
        )

        val value = firstObject(
            entry,
            #[
                "value",
                "right",
                "rhs",
                "exp",
                "expression"
            ]
        )

        if (key !== null) {
            result.put(
                "key",
                normalize(key, active)
            )
        }

        if (value !== null) {
            result.put(
                "value",
                normalize(value, active)
            )
        }

        result
    }

    private def Map<String, Object> variable(
        EObject expression
    ) {
        val result = base(
            "variable",
            expression
        )

        val variable = firstObject(
            expression,
            #[
                "variable",
                "ref"
            ]
        )

        val variableName = named(variable)

        if (variableName !== null) {
            result.put(
                "name",
                variableName
            )
        }

        result
    }

    private def Map<String, Object> featureAccess(
        EObject expression,
        Set<EObject> active
    ) {
        val result = base(
            "featureAccess",
            expression
        )

        val receiver = firstObject(
            expression,
            #[
                "record",
                "receiver",
                "target",
                "source"
            ]
        )

        if (receiver !== null) {
            result.put(
                "receiver",
                normalize(
                    receiver,
                    active
                )
            )
        }

        val feature = firstObject(
            expression,
            #[
                "field",
                "feature",
                "member"
            ]
        )

        val featureName = named(feature)

        if (featureName !== null) {
            result.put(
                "feature",
                featureName
            )
        }

        val path = expressionPath(expression)

        if (!path.empty) {
            result.put("path", path)
        }

        result
    }

    private def Map<String, Object> bracket(
        EObject expression,
        Set<EObject> active
    ) {
        val nested = firstObject(
            expression,
            #[
                "sub",
                "expression",
                "exp",
                "operand"
            ]
        )

        if (nested !== null) {
            return normalize(
                nested,
                active
            ) as Map<String, Object>
        }

        unsupported(expression)
    }

    private def Map<String, Object> unary(
        EObject expression,
        String fallbackOperator,
        Set<EObject> active
    ) {
        val result = base(
            "unary",
            expression
        )

        val actualOperator =
            operator(expression)

        result.put(
            "operator",
            if (actualOperator === null)
                fallbackOperator
            else
                actualOperator
        )

        val operand = firstObject(
            expression,
            #[
                "operand",
                "sub",
                "expression",
                "exp",
                "value"
            ]
        )

        if (operand !== null) {
            result.put(
                "operand",
                normalize(
                    operand,
                    active
                )
            )
        }

        result
    }

    private def Map<String, Object> binary(
        EObject expression,
        String fallbackOperator,
        Set<EObject> active
    ) {
        val result = base(
            "binary",
            expression
        )

        val actualOperator =
            operator(expression)

        result.put(
            "operator",
            if (actualOperator === null)
                fallbackOperator
            else
                actualOperator
        )

        val left = firstObject(
            expression,
            #[
                "left",
                "lhs",
                "first"
            ]
        )

        val right = firstObject(
            expression,
            #[
                "right",
                "rhs",
                "second"
            ]
        )

        if (left !== null) {
            result.put(
                "left",
                normalize(left, active)
            )
        }

        if (right !== null) {
            result.put(
                "right",
                normalize(right, active)
            )
        }

        result
    }

    private def Map<String, Object> conditional(
        EObject expression,
        Set<EObject> active
    ) {
        val result = base(
            "conditional",
            expression
        )

        val condition = firstObject(
            expression,
            #[
                "left",
                "condition",
                "guard",
                "if"
            ]
        )

        val thenExpression = firstObject(
            expression,
            #[
                "middle",
                "then",
                "thenExpression",
                "ifTrue",
                "trueExpression"
            ]
        )

        val elseExpression = firstObject(
            expression,
            #[
                "right",
                "else",
                "elseExpression",
                "ifFalse",
                "falseExpression"
            ]
        )

        if (condition !== null) {
            result.put(
                "condition",
                normalize(condition, active)
            )
        }

        if (thenExpression !== null) {
            result.put(
                "then",
                normalize(
                    thenExpression,
                    active
                )
            )
        }

        if (elseExpression !== null) {
            result.put(
                "else",
                normalize(
                    elseExpression,
                    active
                )
            )
        }

        result
    }

    private def Map<String, Object> functionCall(
        EObject expression,
        Set<EObject> active
    ) {
        val result = base(
            "functionCall",
            expression
        )

        val function = firstObject(
            expression,
            #[
                "function",
                "operation",
                "method"
            ]
        )

        val functionName = named(function)

        if (functionName !== null) {
            result.put(
                "function",
                functionName
            )
        }

        result.put(
            "arguments",
            normalizeList(
                expression,
                #[
                    "arguments",
                    "args",
                    "parameters",
                    "expressions"
                ],
                active
            )
        )

        result
    }

    private def Map<String, Object> literal(
        EObject expression,
        String kind
    ) {
        val result = base(
            kind,
            expression
        )

        result.put(
            "value",
            attribute(
                expression,
                #[
                    "value",
                    "val",
                    "literal",
                    "string",
                    "integer",
                    "real",
                    "boolean"
                ]
            )
        )

        result
    }

    private def Map<String, Object> genericLiteral(
        EObject expression
    ) {
        val className =
            expression.eClass.name.toLowerCase

        if (className.contains("null")) {
            return nullLiteral(expression)
        }

        if (className.contains("enum")) {
            return enumLiteral(expression)
        }

        val kind =
            if (className.contains("string"))
                "string"
            else if (className.contains("bool"))
                "boolean"
            else if (
                className.contains("real") ||
                className.contains("double") ||
                className.contains("float")
            )
                "real"
            else if (
                className.contains("int") ||
                className.contains("long")
            )
                "integer"
            else
                "literal"

        literal(expression, kind)
    }

    private def Map<String, Object> nullLiteral(
        EObject expression
    ) {
        val result = base(
            "null",
            expression
        )

        result.put("value", null)
        result
    }

    private def Map<String, Object> enumLiteral(
        EObject expression
    ) {
        val result = base(
            "enum",
            expression
        )

        val literal = firstObject(
            expression,
            #[
                "literal",
                "enumLiteral",
                "value"
            ]
        )

        result.put(
            "value",
            named(literal)
        )

        val type = firstObject(
            expression,
            #[
                "type",
                "enumType"
            ]
        )

        val typeName = named(type)

        if (typeName !== null) {
            result.put("type", typeName)
        }

        result
    }

    private def Map<String, Object> unsupported(
        EObject expression
    ) {
        val result = base(
            "unsupported",
            expression
        )

        val text = sourceText(expression)

        if (
            text !== null &&
            !text.empty
        ) {
            result.put("text", text)
        }

        result
    }

    private def Map<String, Object> reference(
        EObject expression
    ) {
        val result = base(
            "reference",
            expression
        )

        val objectName = named(expression)

        if (objectName !== null) {
            result.put("name", objectName)
        }

        result
    }

    private def List<Object> normalizeList(
        EObject owner,
        List<String> featureNames,
        Set<EObject> active
    ) {
        val result = new ArrayList<Object>

        for (
            item :
                firstList(
                    owner,
                    featureNames
                )
        ) {
            result.add(
                normalize(item, active)
            )
        }

        result
    }

    private def EObject firstObject(
        EObject owner,
        List<String> featureNames
    ) {
        if (owner === null) {
            return null
        }

        for (featureName : featureNames) {
            val feature =
                owner.eClass.getEStructuralFeature(
                    featureName
                )

            if (
                feature !== null &&
                owner.eIsSet(feature)
            ) {
                val rawValue =
                    owner.eGet(feature)

                if (rawValue instanceof EObject) {
                    return rawValue
                }
            }
        }

        null
    }

    private def List<EObject> firstList(
        EObject owner,
        List<String> featureNames
    ) {
        val result = new ArrayList<EObject>

        if (owner === null) {
            return result
        }

        for (featureName : featureNames) {
            val feature =
                owner.eClass.getEStructuralFeature(
                    featureName
                )

            if (
                feature !== null &&
                owner.eIsSet(feature)
            ) {
                val rawValue =
                    owner.eGet(feature)

                if (
                    rawValue instanceof Iterable<?>
                ) {
                    for (
                        item :
                            rawValue as Iterable<?>
                    ) {
                        if (item instanceof EObject) {
                            result.add(item)
                        }
                    }

                    if (!result.empty) {
                        return result
                    }
                }
            }
        }

        result
    }

    private def Object attribute(
        EObject owner,
        List<String> featureNames
    ) {
        if (owner === null) {
            return null
        }

        for (featureName : featureNames) {
            val feature =
                owner.eClass.getEStructuralFeature(
                    featureName
                )

            if (
                feature !== null 
//                &&
//                owner.eIsSet(feature)
            ) {
                val rawValue =
                    owner.eGet(feature)

                if (!(rawValue instanceof EObject)) {
                    return scalar(rawValue)
                }
            }
        }

        null
    }

    private def String operator(
        EObject expression
    ) {
         val knownOperator = switch expression.eClass.name {
            case "ExpressionAnd": "and"
            case "ExpressionOr": "or"
    
            case "ExpressionEqual": "=="
            case "ExpressionNEqual": "!="
            case "ExpressionGeq": ">="
            case "ExpressionGreater": ">"
            case "ExpressionLeq": "<="
            case "ExpressionLess": "<"
    
            case "ExpressionAddition": "+"
            case "ExpressionSubtraction": "-"
            case "ExpressionMultiply": "*"
            case "ExpressionDivision": "/"
            case "ExpressionMaximum": "max"
            case "ExpressionMinimum": "min"
            case "ExpressionModulo": "mod"
            case "ExpressionPower": "^"
    
            case "ExpressionNullCoalescing": "??"
    
            case "ExpressionNot": "not"
            case "ExpressionMinus": "-"
            case "ExpressionPlus": "+"
    
            default: null
        }
    
        if (knownOperator !== null) {
            return knownOperator
        }
    
        val rawValue = attribute(expression, #["operator", "op"])
        if (rawValue === null) null else rawValue.toString
    
//        val rawValue = attribute(
//            expression,
//            #[
//                "operator",
//                "op"
//            ]
//        )

//        if (rawValue === null) {
//            return null
//            
            }

    private def boolean isBinary(
        EObject expression
    ) {
        firstObject(
            expression,
            #[
                "left",
                "lhs",
                "first"
            ]
        ) !== null &&
        firstObject(
            expression,
            #[
                "right",
                "rhs",
                "second"
            ]
        ) !== null
    }

    private def boolean isUnary(
        EObject expression
    ) {
        firstObject(
            expression,
            #[
                "operand",
                "sub"
            ]
        ) !== null &&
        !isBinary(expression)
    }

    private def List<String> expressionPath(
        EObject expression
    ) {
        val result = new ArrayList<String>

        if (expression === null) {
            return result
        }

        switch expression.eClass.name {
            case "ExpressionVariable": {
                val variableName = named(
                    firstObject(
                        expression,
                        #[
                            "variable",
                            "ref"
                        ]
                    )
                )

                if (variableName !== null) {
                    result.add(variableName)
                }
            }

            case "ExpressionRecordAccess": {
                result.addAll(
                    expressionPath(
                        firstObject(
                            expression,
                            #[
                                "record",
                                "receiver",
                                "target"
                            ]
                        )
                    )
                )

                val fieldName = named(
                    firstObject(
                        expression,
                        #[
                            "field",
                            "feature",
                            "member"
                        ]
                    )
                )

                if (fieldName !== null) {
                    result.add(fieldName)
                }
            }

            case "ExpressionBracket": {
                result.addAll(
                    expressionPath(
                        firstObject(
                            expression,
                            #[
                                "sub",
                                "expression",
                                "exp"
                            ]
                        )
                    )
                )
            }
        }

        result
    }

    private def String named(
        EObject object
    ) {
        if (object === null) {
            return null
        }

        val feature =
            object.eClass
                .getEStructuralFeature("name")

        if (
            feature === null ||
            !object.eIsSet(feature)
        ) {
            return null
        }

        val rawValue =
            object.eGet(feature)

        if (rawValue === null) {
            return null
        }

        rawValue.toString
    }

    private def Object scalar(
        Object rawValue
    ) {
        if (
            rawValue === null ||
            rawValue instanceof String ||
            rawValue instanceof Number ||
            rawValue instanceof Boolean
        ) {
            return rawValue
        }

        if (rawValue instanceof Enum<?>) {
            return rawValue.toString
        }

        rawValue.toString
    }

    private def LinkedHashMap<String, Object> base(
        String kind,
        EObject expression
    ) {
        val result =
            new LinkedHashMap<String, Object>

        result.put("kind", kind)

        result.put(
            "modelType",
            expression.eClass.name
        )

        result
    }

    private def String sourceText(
        EObject object
    ) {
        if (object === null) {
            return null
        }

        val node =
            NodeModelUtils.getNode(object)

        if (node === null) {
            return null
        }

        node.text.trim
    }
}