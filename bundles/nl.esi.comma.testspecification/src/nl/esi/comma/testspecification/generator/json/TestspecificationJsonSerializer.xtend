package nl.esi.comma.testspecification.generator.json

import java.util.ArrayList
import java.util.IdentityHashMap
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

/**
 * Serializes a TestDefinition to a compact, structured JSON representation.
 *
 * Expressions, including nested maps, records and vectors, are serialized
 * recursively through their containment references. Cross-references remain
 * compact and container references are never exported.
 *
 * Source text is included only at the root of an explicitly serialized
 * expression or element. It is not repeated for every nested AST node.
 */
class TestspecificationJsonSerializer {

    val JsonWriter jsonWriter = new JsonWriter
    
    val SemanticExpressionJsonSerializer semanticExpressionSerializer = new SemanticExpressionJsonSerializer

    val Map<EObject, StepInfo> stepByVariable =
        new IdentityHashMap<EObject, StepInfo>

    val List<Map<String, Object>> diagnostics =
        new ArrayList<Map<String, Object>>

    def String serialize(
        EObject definition,
        String sourceName
    ) {
        stepByVariable.clear
        diagnostics.clear

        if (definition === null) {
            throw new IllegalArgumentException(
                "TestDefinition must not be null"
            )
        }

        indexSteps(definition)

        val result = linkedMap

        result.put(
            "format",
            "comma-test-specification"
        )

        result.put(
            "formatVersion",
            "1.0"
        )

        result.put(
            "source",
            sourceName
        )

        result.put(
            "testSequences",
            serializeTestSequences(
                list(definition, "testSeq")
            )
        )

        result.put(
            "stepSequences",
            serializeStepSequences(
                list(definition, "stepSeq")
            )
        )

        // Commented DB: to be addressed when we migrate to new TSpec Grammar.
        /*result.put(
            "globalParameterInitializations",
            serializeActions(
                list(definition, "gparamsInitActions"),
                null
            )
        )

        result.put(
            "sutParameterInitializations",
            serializeActions(
                list(definition, "sutInitActions"),
                null
            )
        )*/

        result.put(
            "diagnostics",
            diagnostics
        )

        jsonWriter.write(result)
    }

    private def void indexSteps(EObject definition) {
        for (sequence : list(definition, "stepSeq")) {
            var index = 0

            for (step : list(sequence, "step")) {
                val variable = value(
                    step,
                    "inputVar"
                ) as EObject

                if (variable !== null) {
                    stepByVariable.put(
                        variable,
                        new StepInfo(
                            name(variable),
                            name(sequence),
                            index,
                            step.eClass.name
                        )
                    )
                }

                index++
            }
        }
    }

    private def List<Object> serializeTestSequences(
        List<EObject> sequences
    ) {
        val resultList = new ArrayList<Object>

        for (sequence : sequences) {
            val result = linkedMap

            result.put(
                "name",
                scalar(sequence, "name")
            )

            val references = new ArrayList<Object>

            for (
                referencedSequence :
                    list(sequence, "stepSeqRef")
            ) {
                references.add(
                    name(referencedSequence)
                )
            }

            result.put(
                "stepSequences",
                references
            )

            resultList.add(result)
        }

        resultList
    }

    private def List<Object> serializeStepSequences(
        List<EObject> sequences
    ) {
        val resultList = new ArrayList<Object>

        for (sequence : sequences) {
            val result = linkedMap

            result.put(
                "name",
                scalar(sequence, "name")
            )

            val steps = new ArrayList<Object>
            var index = 0

            for (step : list(sequence, "step")) {
                steps.add(
                    serializeStep(
                        step,
                        sequence,
                        index
                    )
                )

                index++
            }

            result.put(
                "steps",
                steps
            )

            resultList.add(result)
        }

        resultList
    }

    private def Map<String, Object> serializeStep(
        EObject step,
        EObject sequence,
        int index
    ) {
        val result = linkedMap

        val kind =
            if (step.eClass.name == "AssertionStep")
                "assertion"
            else
                "run"

        result.put(
            "index",
            index
        )

        result.put(
            "kind",
            kind
        )

        result.put(
            "name",
            name(
                value(step, "inputVar") as EObject
            )
        )

        result.put(
            "type",
            name(
                value(step, "type") as EObject
            )
        )

        result.put(
            "input",
            name(
                value(step, "stepVar") as EObject
            )
        )

        result.put(
            "features",
            list(step, "featuresForStep")
                .map[name(it)]
                .filterNull
                .toList
        )

        val references = new ArrayList<Object>
        val dependencies = new ArrayList<Object>

        for (referencedStep : list(step, "refStep")) {
            val referenceJson = linkedMap

            referenceJson.put(
                "features",
                list(
                    referencedStep,
                    "featuresToOutput"
                )
                    .map[name(it)]
                    .filterNull
                    .toList
            )

            val actions = serializeActionList(
                value(
                    referencedStep,
                    "input"
                ) as EObject,
                step
            )

            referenceJson.put(
                "actions",
                actions
            )

            references.add(referenceJson)

            for (action : actions) {
                if (action instanceof Map<?, ?>) {
                    val actionMap =
                        action as Map<String, Object>

                    val actionDependencies =
                        actionMap.get("dependencies")

                    if (
                        actionDependencies
                            instanceof Iterable<?>
                    ) {
                        for (
                            dependency :
                                actionDependencies
                                    as Iterable<?>
                        ) {
                            dependencies.add(dependency)
                        }
                    }
                }
            }
        }

        result.put(
            "referenceInputs",
            references
        )

        if (kind == "assertion") {
            val assertions = new ArrayList<Object>

            for (
                assertionGroup :
                    list(step, "asserts")
            ) {
                val assertionJson =
                    serializeAssertion(
                        assertionGroup,
                        step
                    )

                assertions.add(assertionJson)

                val assertionDependencies =
                    assertionJson.get("dependencies")

                if (
                    assertionDependencies
                        instanceof Iterable<?>
                ) {
                    for (
                        dependency :
                            assertionDependencies
                                as Iterable<?>
                    ) {
                        dependencies.add(dependency)
                    }
                }
            }

            result.put(
                "assertions",
                assertions
            )
        }

        result.put(
            "dependencies",
            uniqueDependencies(dependencies)
        )

        result
    }

//    private def Map<String, Object> serializeAssertion(
//        EObject assertionGroup,
//        EObject currentStep
//    ) {
//        val result = compactElement(assertionGroup)
//        val dependencies = new ArrayList<Object>
//        val items = new ArrayList<Object>
//
//        for (
//            item :
//                list(assertionGroup, "constr")
//        ) {
//            val targetPath =
//                assertionTargetPath(
//                    assertionGroup,
//                    item
//                )
//
//            val itemJson =
//                compactExpression(item)
//
//            val itemDependencies =
//                collectDependencies(
//                    item,
//                    currentStep,
//                    targetPath
//                )
//
//            itemJson.put(
//                "targetPath",
//                targetPath
//            )
//
//            itemJson.put(
//                "dependencies",
//                uniqueDependencies(
//                    itemDependencies
//                )
//            )
//
//            items.add(itemJson)
//            dependencies.addAll(itemDependencies)
//        }
//
//        result.put(
//            "items",
//            items
//        )
//
//        result.put(
//            "dependencies",
//            uniqueDependencies(dependencies)
//        )
//
//        result
//    }

    private def Map<String, Object> serializeAssertion(
        EObject assertionGroup,
        EObject currentStep
    ) {
        /*
         * Do not recursively serialize assertionGroup here. Its constraints are
         * serialized separately below. Recursively serializing the group would
         * duplicate its complete expression tree.
         */
        val result = linkedMap
        result.put(
            "kind",
            lowerFirst(assertionGroup.eClass.name)
        )
        result.put(
            "modelType",
            assertionGroup.eClass.name
        )
        val assertionName =
            name(assertionGroup)
        if (assertionName !== null) {
            result.put(
                "name",
                assertionName
            )
        }
        val dependencies =
            new ArrayList<Object>
        val items =
            new ArrayList<Object>
        for (
            item :
                list(assertionGroup, "constr")
        ) {
            val targetPath =
                assertionTargetPath(
                    assertionGroup,
                    item
                )
            val itemJson =
                compactExpression(item)
            val itemDependencies =
                collectDependencies(
                    item,
                    currentStep,
                    targetPath
                )
            itemJson.put(
                "targetPath",
                targetPath
            )
            itemJson.put(
                "dependencies",
                uniqueDependencies(
                    itemDependencies
                )
            )
            items.add(itemJson)
            dependencies.addAll(itemDependencies)
        }
        result.put(
            "items",
            items
        )
        result.put(
            "dependencies",
            uniqueDependencies(dependencies)
        )
        result
    }

    private def List<String> assertionTargetPath(
        EObject assertionGroup,
        EObject item
    ) {
        val result = new ArrayList<String>

        result.add("assertions")

        val groupName = name(assertionGroup)

        if (groupName !== null) {
            result.add(groupName)
        }

        val itemName = name(item)

        if (itemName !== null) {
            result.add(itemName)
        }

        if (
            value(item, "output")
                instanceof EObject
        ) {
            result.add("output")
        }

        result
    }

    private def List<Object> serializeActionList(
        EObject actionList,
        EObject currentStep
    ) {
        val result = new ArrayList<Object>

        if (actionList === null) {
            return result
        }

        val directActions =
            containmentChildren(actionList)
                .filter[
                    eClass.name.endsWith("Action") ||
                    eClass.name == "ActionList"
                ]
                .toList

        val actions =
            if (directActions.empty)
                #[actionList]
            else
                directActions

        for (action : actions) {
            result.add(
                serializeAction(
                    action,
                    currentStep
                )
            )
        }

        result
    }

    private def List<Object> serializeActions(
        List<EObject> actions,
        EObject currentStep
    ) {
        val result = new ArrayList<Object>

        for (action : actions) {
            result.add(
                serializeAction(
                    action,
                    currentStep
                )
            )
        }

        result
    }

    private def Map<String, Object> serializeAction(
        EObject action,
        EObject currentStep
    ) {
        val result = linkedMap

        result.put(
            "kind",
            lowerFirst(action.eClass.name)
        )

        result.put(
            "modelType",
            action.eClass.name
        )

        val actionText =
            sourceText(action)

        if (
            actionText !== null &&
            !actionText.empty
        ) {
            result.put(
                "text",
                actionText
            )
        }

        val lhs = firstEObject(
            action,
            #[
                "fieldAccess",
                "assignment",
                "lhs",
                "left",
                "target",
                "variable"
            ]
        )

        val rhs = firstEObject(
            action,
            #[
                "exp",
                "rhs",
                "right",
                "value",
                "expression"
            ]
        )

        val targetPath =
            expressionPath(lhs)

        if (lhs !== null) {
            result.put(
                "target",
                compactExpression(lhs)
            )
        }

        if (!targetPath.empty) {
            result.put(
                "targetPath",
                withoutRoot(targetPath)
            )
        }

        if (rhs !== null) {
            result.put(
                "expression",
                compactExpression(rhs)
            )
        }

        if (
            lhs === null &&
            rhs === null
        ) {
            result.put(
                "element",
                compactElement(action)
            )
        }

        result.put(
            "dependencies",
            uniqueDependencies(
                collectDependencies(
                    if (rhs !== null)
                        rhs
                    else
                        action,
                    currentStep,
                    withoutRoot(targetPath)
                )
            )
        )

        result
    }

    private def List<Object> collectDependencies(
        EObject expression,
        EObject currentStep,
        List<String> targetPath
    ) {
        val result = new ArrayList<Object>

        val currentInfo =
            if (currentStep === null)
                null
            else
                stepByVariable.get(
                    value(
                        currentStep,
                        "inputVar"
                    ) as EObject
                )

        val visited =
            new LinkedHashSet<EObject>

        visit(
            expression,
            visited
        ) [ object |
            for (
                reference :
                    object.eClass.EAllReferences.filter[
                        !containment &&
                        !container &&
                        !derived &&
                        !transient &&
                        !volatile &&
                        object.eIsSet(it)
                    ]
            ) {
                val referenced =
                    object.eGet(reference)

                if (referenced instanceof EObject) {
                    addDependency(
                        result,
                        referenced,
                        currentInfo,
                        object,
                        targetPath
                    )
                } else if (
                    referenced instanceof Iterable<?>
                ) {
                    for (
                        item :
                            referenced as Iterable<?>
                    ) {
                        if (item instanceof EObject) {
                            addDependency(
                                result,
                                item,
                                currentInfo,
                                object,
                                targetPath
                            )
                        }
                    }
                }
            }
        ]

        result
    }

    private def void addDependency(
        List<Object> output,
        EObject referenced,
        StepInfo current,
        EObject occurrence,
        List<String> targetPath
    ) {
        val source =
            stepByVariable.get(referenced)

        if (source === null) {
            return
        }

        val classification =
            if (current === null)
                "step-reference"
            else if (
                source.sequence != current.sequence
            )
                "other-sequence"
            else if (
                source.index < current.index
            )
                "preceding-step"
            else if (
                source.index == current.index
            )
                "same-step"
            else
                "forward-step"

        val dependency = linkedMap

        dependency.put(
            "sourceStep",
            source.name
        )

        dependency.put(
            "sourceStepIndex",
            source.index
        )

        dependency.put(
            "sourceSequence",
            source.sequence
        )

        if (current !== null) {
            dependency.put(
                "targetStep",
                current.name
            )

            dependency.put(
                "targetStepIndex",
                current.index
            )

            dependency.put(
                "targetSequence",
                current.sequence
            )
        }

        dependency.put(
            "sourcePath",
            sourcePath(
                occurrence,
                referenced
            )
        )

        dependency.put(
            "targetPath",
            new ArrayList<String>(
                targetPath
            )
        )

        dependency.put(
            "classification",
            classification
        )

        val occurrencePath =
            expressionPath(
                topPathExpression(occurrence)
            )

        if (!occurrencePath.empty) {
            dependency.put(
                "expressionPath",
                occurrencePath
            )
        }

        output.add(dependency)

        if (
            classification == "forward-step"
        ) {
            diagnostics.add(
                diagnostic(
                    "warning",
                    "FORWARD_STEP_REFERENCE",
                    "Step '" +
                        current.name +
                        "' references later step '" +
                        source.name +
                        "'."
                )
            )
        }
    }

    /**
     * Returns a variable or record-access path, including the root variable.
     */
    private def List<String> expressionPath(
        EObject expression
    ) {
        val result = new ArrayList<String>

        if (expression === null) {
            return result
        }

        switch expression.eClass.name {
            case "ExpressionVariable": {
                val variable =
                    value(
                        expression,
                        "variable"
                    ) as EObject

                val variableName =
                    name(variable)

                if (variableName !== null) {
                    result.add(variableName)
                }
            }

            case "ExpressionRecordAccess": {
                result.addAll(
                    expressionPath(
                        value(
                            expression,
                            "record"
                        ) as EObject
                    )
                )

                val field =
                    value(
                        expression,
                        "field"
                    ) as EObject

                val fieldName =
                    name(field)

                if (fieldName !== null) {
                    result.add(fieldName)
                }
            }

            case "ExpressionBracket": {
                result.addAll(
                    expressionPath(
                        value(
                            expression,
                            "sub"
                        ) as EObject
                    )
                )
            }

            default: {
                /*
                 * AssignmentAction.assignment is a direct Variable reference
                 * rather than an ExpressionVariable containment.
                 */
                val directName =
                    name(expression)

                if (directName !== null) {
                    result.add(directName)
                }
            }
        }

        result
    }

    private def List<String> withoutRoot(
        List<String> path
    ) {
        val result = new ArrayList<String>

        if (
            path !== null &&
            path.size > 1
        ) {
            for (
                var index = 1;
                index < path.size;
                index++
            ) {
                result.add(
                    path.get(index)
                )
            }
        }

        result
    }

    private def List<String> sourcePath(
        EObject occurrence,
        EObject referencedVariable
    ) {
        val fullPath =
            expressionPath(
                topPathExpression(occurrence)
            )

        val referencedName =
            name(referencedVariable)

        if (
            referencedName !== null &&
            !fullPath.empty &&
            fullPath.get(0) == referencedName
        ) {
            return withoutRoot(fullPath)
        }

        new ArrayList<String>
    }

    private def EObject topPathExpression(
        EObject occurrence
    ) {
        var current = occurrence
        var parent = current?.eContainer

        while (
            parent !== null &&
            (
                (
                    parent.eClass.name ==
                        "ExpressionRecordAccess" &&
                    value(
                        parent,
                        "record"
                    ) === current
                ) ||
                parent.eClass.name ==
                    "ExpressionBracket"
            )
        ) {
            current = parent
            parent = current.eContainer
        }

        current
    }

    private def List<Object> uniqueDependencies(
        List<Object> dependencies
    ) {
        val result = new ArrayList<Object>
        val seen = new LinkedHashSet<String>

        for (dependency : dependencies) {
            val key = dependency.toString

            if (!seen.contains(key)) {
                seen.add(key)
                result.add(dependency)
            }
        }

        result
    }

    /**
     * Produces a compact semantic representation through the dedicated
     * expression serializer.
     *
     * Source text is added only at this expression root. Child expressions are
     * represented structurally without repeating their complete DSL text.
     */
    private def Map<String, Object> compactExpression(
        EObject expression
    ) {
        if (expression === null) {
            return linkedMap(
                "kind",
                "null"
            )
        }
    
        val result =
            semanticExpressionSerializer.serialize(
                expression
            )
    
        /*
         * Retain source text for traceability, but downstream semantic diffing
         * should normally ignore this property.
         */
        val text =
            sourceText(expression)
    
        if (
            text !== null &&
            !text.empty
        ) {
            result.put(
                "text",
                text
            )
        }
    
        val path =
            expressionPath(expression)
    
        if (!path.empty) {
            result.put(
                "path",
                path
            )
        }
    
        result
    }
    
    /**
     * Produces a shallow representation for non-expression model elements.
     *
     * This method deliberately does not recurse through arbitrary EMF
     * containment. Expressions owned by the element must be serialized
     * explicitly by the caller through compactExpression(...).
     */
    private def Map<String, Object> compactElement(
        EObject object
    ) {
        val result = linkedMap

        if (object === null) {
            result.put(
                "kind",
                "null"
            )

            return result
        }

        result.put(
            "kind",
            lowerFirst(object.eClass.name)
        )

        result.put(
            "modelType",
            object.eClass.name
        )

        val objectName =
            name(object)

        if (objectName !== null) {
            result.put(
                "name",
                objectName
            )
        }
    
        val text =
            sourceText(object)
    
        if (
            text !== null &&
            !text.empty
        ) {
            result.put(
                "text",
                text
            )
        }
    
        result
    }

//    /**
//     * Produces a recursively normalized expression representation.
//     *
//     * The expression root receives source text and a path. Nested nodes keep
//     * only their semantic structure.
//     */
//    private def Map<String, Object> compactExpression(
//        EObject expression
//    ) {
//        if (expression === null) {
//            return linkedMap(
//                "kind",
//                "null"
//            )
//        }
//
//        val result =
//            normalizeEObject(
//                expression,
//                new LinkedHashSet<EObject>
//            ) as Map<String, Object>
//
//        val text =
//            sourceText(expression)
//
//        if (
//            text !== null &&
//            !text.empty
//        ) {
//            result.put(
//                "text",
//                text
//            )
//        }
//
//        val path =
//            expressionPath(expression)
//
//        if (!path.empty) {
//            result.put(
//                "path",
//                path
//            )
//        }
//
//        result
//    }
//
//    /**
//     * Produces a recursively normalized representation for a non-expression
//     * element. Source text is attached only to this root object.
//     */
//    private def Map<String, Object> compactElement(
//        EObject object
//    ) {
//        if (object === null) {
//            return linkedMap(
//                "kind",
//                "null"
//            )
//        }
//
//        val result =
//            normalizeEObject(
//                object,
//                new LinkedHashSet<EObject>
//            ) as Map<String, Object>
//
//        val text =
//            sourceText(object)
//
//        if (
//            text !== null &&
//            !text.empty
//        ) {
//            result.put(
//                "text",
//                text
//            )
//        }
//
//        result
//    }

    /**
     * Converts an EMF containment tree to compact normalized JSON.
     *
     * Containment references are expanded recursively. Selected semantic
     * cross-references are represented as compact references. Container,
     * derived, transient and volatile features are excluded.
     */
//    private def Object normalizeEObject(
//        EObject object,
//        Set<EObject> active
//    ) {
//        if (object === null) {
//            return null
//        }
//
//        if (active.contains(object)) {
//            val cycle = linkedMap
//
//            cycle.put(
//                "kind",
//                "reference"
//            )
//
//            cycle.put(
//                "modelType",
//                object.eClass.name
//            )
//
//            val objectName =
//                name(object)
//
//            if (objectName !== null) {
//                cycle.put(
//                    "name",
//                    objectName
//                )
//            }
//
//            return cycle
//        }
//
//        active.add(object)
//
//        val result = linkedMap
//
//        result.put(
//            "kind",
//            normalizedKind(object)
//        )
//
//        result.put(
//            "modelType",
//            object.eClass.name
//        )
//
//        /*
//         * Scalar attributes contain literal values, operators and other
//         * compact semantic information.
//         */
//        for (
//            attribute :
//                object.eClass.EAllAttributes.filter[
//                    !derived &&
//                    !transient &&
//                    !volatile &&
//                    object.eIsSet(it)
//                ]
//        ) {
//            result.put(
//                normalizedAttributeName(
//                    object,
//                    attribute.name
//                ),
//                normalizeScalar(
//                    object.eGet(attribute)
//                )
//            )
//        }
//
//        /*
//         * Recursively serialize containment only. This preserves nested maps,
//         * vectors, records, operator operands and function arguments.
//         */
//        for (
//            reference :
//                object.eClass.EAllReferences.filter[
//                    containment &&
//                    !container &&
//                    !derived &&
//                    !transient &&
//                    !volatile &&
//                    object.eIsSet(it)
//                ]
//        ) {
//            val rawValue =
//                object.eGet(reference)
//
//            val outputName =
//                normalizedReferenceName(
//                    object,
//                    reference.name
//                )
//
//            if (rawValue instanceof EObject) {
//                result.put(
//                    outputName,
//                    normalizeEObject(
//                        rawValue,
//                        active
//                    )
//                )
//            } else if (
//                rawValue instanceof Iterable<?>
//            ) {
//                val values =
//                    new ArrayList<Object>
//
//                for (
//                    item :
//                        rawValue as Iterable<?>
//                ) {
//                    if (item instanceof EObject) {
//                        values.add(
//                            normalizeEObject(
//                                item,
//                                active
//                            )
//                        )
//                    } else {
//                        values.add(
//                            normalizeScalar(item)
//                        )
//                    }
//                }
//
//                result.put(
//                    outputName,
//                    values
//                )
//            }
//        }
//
//        /*
//         * Cross-references remain compact. Infrastructure and parent
//         * references are deliberately omitted.
//         */
//        for (
//            reference :
//                object.eClass.EAllReferences.filter[
//                    !containment &&
//                    !container &&
//                    !derived &&
//                    !transient &&
//                    !volatile &&
//                    object.eIsSet(it) &&
//                    isRelevantCrossReference(
//                        it.name
//                    )
//                ]
//        ) {
//            val rawValue =
//                object.eGet(reference)
//
//            val outputName =
//                normalizedReferenceName(
//                    object,
//                    reference.name
//                )
//
//            if (rawValue instanceof EObject) {
//                result.put(
//                    outputName,
//                    normalizeReference(
//                        rawValue
//                    )
//                )
//            } else if (
//                rawValue instanceof Iterable<?>
//            ) {
//                val references =
//                    new ArrayList<Object>
//
//                for (
//                    item :
//                        rawValue as Iterable<?>
//                ) {
//                    if (item instanceof EObject) {
//                        references.add(
//                            normalizeReference(item)
//                        )
//                    }
//                }
//
//                if (!references.empty) {
//                    result.put(
//                        outputName,
//                        references
//                    )
//                }
//            }
//        }
//
//        addCanonicalLiteralValue(
//            object,
//            result
//        )
//
//        active.remove(object)
//
//        result
//    }
//
//    private def boolean isRelevantCrossReference(
//        String featureName
//    ) {
//        if (featureName === null) {
//            return false
//        }
//
//        switch featureName.toLowerCase {
//            case "variable": true
//            case "field": true
//            case "feature": true
//            case "function": true
//            case "operation": true
//            case "literal": true
//            case "enumliteral": true
//            case "type": true
//            default: false
//        }
//    }
//
//    private def Map<String, Object> normalizeReference(
//        EObject target
//    ) {
//        val result = linkedMap
//
//        result.put(
//            "kind",
//            "reference"
//        )
//
//        result.put(
//            "modelType",
//            target.eClass.name
//        )
//
//        val targetName =
//            name(target)
//
//        if (targetName !== null) {
//            result.put(
//                "name",
//                targetName
//            )
//        }
//
//        val step =
//            stepByVariable.get(target)
//
//        if (step !== null) {
//            result.put(
//                "step",
//                step.name
//            )
//
//            result.put(
//                "stepIndex",
//                step.index
//            )
//
//            result.put(
//                "stepSequence",
//                step.sequence
//            )
//        }
//
//        result
//    }
//
//    /**
//     * Produces stable semantic kinds for common XPlus expression constructs.
//     */
//    private def String normalizedKind(
//        EObject object
//    ) {
//        val className =
//            object.eClass.name
//
//        val lower =
//            className.toLowerCase
//
//        if (
//            lower.contains("null") &&
//            (
//                lower.contains("expression") ||
//                lower.contains("literal")
//            )
//        ) {
//            return "null"
//        }
//
//        if (
//            lower.contains("constantstring") ||
//            lower.contains("stringliteral")
//        ) {
//            return "string"
//        }
//
//        if (
//            lower.contains("constantint") ||
//            lower.contains("integerliteral")
//        ) {
//            return "integer"
//        }
//
//        if (
//            lower.contains("constantreal") ||
//            lower.contains("realliteral") ||
//            lower.contains("doubleliteral")
//        ) {
//            return "real"
//        }
//
//        if (
//            lower.contains("constantbool") ||
//            lower.contains("booleanliteral")
//        ) {
//            return "boolean"
//        }
//
//        if (
//            lower.contains("enum") &&
//            lower.contains("literal")
//        ) {
//            return "enum"
//        }
//
//        if (
//            lower.contains("vector") ||
//            lower.contains("collection") ||
//            lower.contains("array") ||
//            lower.contains("list")
//        ) {
//            return "list"
//        }
//
//        if (
//            lower.contains("record") &&
//            !lower.contains("access") &&
//            !lower.contains("assignment")
//        ) {
//            return "record"
//        }
//
//        if (
//            lower.contains("map") &&
//            lower.contains("entry")
//        ) {
//            return "mapEntry"
//        }
//
//        if (lower.contains("map")) {
//            return "map"
//        }
//
//        if (
//            lower.contains("function") ||
//            lower.contains("operation") ||
//            lower.contains("call")
//        ) {
//            return "functionCall"
//        }
//
//        if (lower.contains("conditional")) {
//            return "conditional"
//        }
//
//        if (
//            lower.contains("coalesc") ||
//            lower.contains("nullsafe")
//        ) {
//            return "nullCoalescing"
//        }
//
//        if (
//            lower.contains("recordaccess") ||
//            lower.contains("featureaccess") ||
//            lower.contains("fieldaccess")
//        ) {
//            return "featureAccess"
//        }
//
//        if (
//            lower.contains("variable") &&
//            lower.contains("expression")
//        ) {
//            return "variable"
//        }
//
//        if (
//            lower.contains("binary") ||
//            lower.contains("addition") ||
//            lower.contains("multiplication") ||
//            lower.contains("comparison") ||
//            lower.contains("equality") ||
//            lower.contains("and") ||
//            lower.contains("or")
//        ) {
//            return "binary"
//        }
//
//        if (
//            lower.contains("unary") ||
//            lower.contains("minus") ||
//            lower.contains("not")
//        ) {
//            return "unary"
//        }
//
//        lowerFirst(className)
//    }
//
//    private def String normalizedReferenceName(
//        EObject owner,
//        String featureName
//    ) {
//        val ownerName =
//            owner.eClass.name.toLowerCase
//
//        val featureLower =
//            featureName.toLowerCase
//
//        if (
//            ownerName.contains("vector") ||
//            ownerName.contains("collection") ||
//            ownerName.contains("array") ||
//            ownerName.contains("list")
//        ) {
//            if (
//                featureLower == "elements" ||
//                featureLower == "element" ||
//                featureLower == "values" ||
//                featureLower == "value" ||
//                featureLower == "expressions" ||
//                featureLower == "expression" ||
//                featureLower == "items" ||
//                featureLower == "item" ||
//                featureLower == "contents" ||
//                featureLower == "content" ||
//                featureLower == "args" ||
//                featureLower == "arguments"
//            ) {
//                return "items"
//            }
//        }
//
//        if (
//            ownerName.contains("record") &&
//            !ownerName.contains("access")
//        ) {
//            if (
//                featureLower == "fields" ||
//                featureLower == "field" ||
//                featureLower == "assignments" ||
//                featureLower == "assignment" ||
//                featureLower == "members" ||
//                featureLower == "member" ||
//                featureLower == "values" ||
//                featureLower == "entries"
//            ) {
//                return "fields"
//            }
//        }
//
//        if (
//            ownerName.contains("map") &&
//            !ownerName.contains("entry")
//        ) {
//            if (
//                featureLower == "entries" ||
//                featureLower == "entry" ||
//                featureLower == "values" ||
//                featureLower == "elements" ||
//                featureLower == "items"
//            ) {
//                return "entries"
//            }
//        }
//
//        if (
//            ownerName.contains("function") ||
//            ownerName.contains("operation") ||
//            ownerName.contains("call")
//        ) {
//            if (
//                featureLower == "args" ||
//                featureLower == "arg" ||
//                featureLower == "parameters" ||
//                featureLower == "parameter" ||
//                featureLower == "expressions"
//            ) {
//                return "arguments"
//            }
//        }
//
//        switch featureLower {
//            case "sub": "operand"
//            case "operand": "operand"
//            case "left": "left"
//            case "lhs": "left"
//            case "right": "right"
//            case "rhs": "right"
//            case "condition": "condition"
//            case "then": "then"
//            case "thenexpression": "then"
//            case "iftrue": "then"
//            case "else": "else"
//            case "elseexpression": "else"
//            case "iffalse": "else"
//            case "key": "key"
//            case "value": "value"
//            case "record": "receiver"
//            case "receiver": "receiver"
//            case "target": "receiver"
//            default: featureName
//        }
//    }
//
//    private def String normalizedAttributeName(
//        EObject owner,
//        String attributeName
//    ) {
//        val ownerName =
//            owner.eClass.name.toLowerCase
//
//        val attributeLower =
//            attributeName.toLowerCase
//
//        if (
//            ownerName.contains("constant") ||
//            ownerName.contains("literal")
//        ) {
//            if (
//                attributeLower == "val" ||
//                attributeLower == "literal" ||
//                attributeLower == "string" ||
//                attributeLower == "integer" ||
//                attributeLower == "real" ||
//                attributeLower == "boolean"
//            ) {
//                return "value"
//            }
//        }
//
//        if (
//            attributeLower == "op" ||
//            attributeLower == "operator"
//        ) {
//            return "operator"
//        }
//
//        attributeName
//    }
//
//    private def Object normalizeScalar(
//        Object rawValue
//    ) {
//        if (
//            rawValue === null ||
//            rawValue instanceof String ||
//            rawValue instanceof Number ||
//            rawValue instanceof Boolean
//        ) {
//            return rawValue
//        }
//
//        if (rawValue instanceof Enum<?>) {
//            return rawValue.toString
//        }
//
//        rawValue.toString
//    }
//
//    private def void addCanonicalLiteralValue(
//        EObject object,
//        Map<String, Object> result
//    ) {
//        val className =
//            object.eClass.name.toLowerCase
//
//        if (
//            className.contains("null") &&
//            (
//                className.contains("expression") ||
//                className.contains("literal")
//            )
//        ) {
//            result.put(
//                "value",
//                null
//            )
//
//            return
//        }
//
//        if (
//            !className.contains("constant") &&
//            !className.contains("literal")
//        ) {
//            return
//        }
//
//        if (result.containsKey("value")) {
//            return
//        }
//
//        val preferredAttributes = #[
//            "value",
//            "val",
//            "literal",
//            "string",
//            "integer",
//            "real",
//            "boolean"
//        ]
//
//        for (
//            attributeName :
//                preferredAttributes
//        ) {
//            val feature =
//                object.eClass
//                    .getEStructuralFeature(
//                        attributeName
//                    )
//
//            if (
//                feature !== null &&
//                object.eIsSet(feature)
//            ) {
//                val rawValue =
//                    object.eGet(feature)
//
//                if (!(rawValue instanceof EObject)) {
//                    result.put(
//                        "value",
//                        normalizeScalar(rawValue)
//                    )
//
//                    return
//                }
//            }
//        }
//
//        val enumFeatures = #[
//            "literal",
//            "enumLiteral",
//            "value"
//        ]
//
//        for (featureName : enumFeatures) {
//            val rawValue =
//                value(
//                    object,
//                    featureName
//                )
//
//            if (rawValue instanceof EObject) {
//                val literalName =
//                    name(rawValue)
//
//                if (literalName !== null) {
//                    result.put(
//                        "value",
//                        literalName
//                    )
//                }
//
//                return
//            }
//        }
//    }

    private def void visit(
        EObject object,
        Set<EObject> visited,
        Procedure1<EObject> consumer
    ) {
        if (
            object !== null &&
            !visited.contains(object)
        ) {
            visited.add(object)
            consumer.apply(object)

            for (
                child :
                    containmentChildren(object)
            ) {
                visit(
                    child,
                    visited,
                    consumer
                )
            }
        }
    }

    private def Iterable<EObject> containmentChildren(
        EObject object
    ) {
        object.eClass.EAllContainments
            .filter[
                !derived &&
                !transient &&
                !volatile &&
                object.eIsSet(it)
            ]
            .map[
                object.eGet(it)
            ]
            .flatMap [ raw |
                if (raw instanceof EObject)
                    #[raw]
                else if (
                    raw instanceof Iterable<?>
                )
                    raw.filter(EObject)
                else
                    #[]
            ]
    }

    private def EObject firstEObject(
        EObject object,
        List<String> names
    ) {
        if (object === null) {
            return null
        }

        for (candidate : names) {
            val feature =
                object.eClass
                    .getEStructuralFeature(
                        candidate
                    )

            if (
                feature !== null &&
                object.eIsSet(feature)
            ) {
                val raw =
                    object.eGet(feature)

                if (raw instanceof EObject) {
                    return raw
                }
            }
        }

        null
    }

    private def Object value(
        EObject object,
        String featureName
    ) {
        if (object === null) {
            return null
        }

        val feature =
            object.eClass
                .getEStructuralFeature(
                    featureName
                )

        if (feature === null) {
            return null
        }

        object.eGet(feature)
    }

    private def List<EObject> list(
        EObject object,
        String featureName
    ) {
        val result = new ArrayList<EObject>

        val raw =
            value(
                object,
                featureName
            )

        if (raw instanceof Iterable<?>) {
            for (item : raw as Iterable<?>) {
                if (item instanceof EObject) {
                    result.add(item)
                }
            }
        }

        result
    }

    private def Object scalar(
        EObject object,
        String featureName
    ) {
        jsonScalar(
            value(
                object,
                featureName
            )
        )
    }

    private def Object jsonScalar(
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

    /**
     * Returns only an explicit name attribute.
     *
     * Source text is deliberately not used as a fallback because doing so can
     * copy complete nested expressions into names, paths and references.
     */
    private def String name(
        EObject object
    ) {
        if (object === null) {
            return null
        }

        val feature =
            object.eClass
                .getEStructuralFeature(
                    "name"
                )

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

    private def String lowerFirst(
        String input
    ) {
        if (
            input === null ||
            input.empty
        ) {
            return input
        }

        input.substring(0, 1).toLowerCase +
            input.substring(1)
    }

    private def Map<String, Object> diagnostic(
        String severity,
        String code,
        String message
    ) {
        val result = linkedMap

        result.put(
            "severity",
            severity
        )

        result.put(
            "code",
            code
        )

        result.put(
            "message",
            message
        )

        result
    }

    private def LinkedHashMap<String, Object> linkedMap() {
        new LinkedHashMap<String, Object>
    }

    private def LinkedHashMap<String, Object> linkedMap(
        String key,
        Object mapValue
    ) {
        val result = linkedMap
        result.put(key, mapValue)
        result
    }

    private static class StepInfo {

        val String name
        val String sequence
        val int index
        val String modelType

        new(
            String name,
            String sequence,
            int index,
            String modelType
        ) {
            this.name = name
            this.sequence = sequence
            this.index = index
            this.modelType = modelType
        }
    }
}


/////// THE CODE BELOW WAS OLD IMPL WHICH PRODUCED ENORMOUS JSON /////////////


//package nl.esi.comma.testspecification.generator.json
//
//import java.util.ArrayList
//import java.util.IdentityHashMap
//import java.util.LinkedHashMap
//import java.util.LinkedHashSet
//import java.util.List
//import java.util.Map
//import java.util.Set
//import org.eclipse.emf.ecore.EObject
//import org.eclipse.xtext.nodemodel.util.NodeModelUtils
//import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
//
///**
// * Model-aware serializer that deliberately uses EMF metadata for inherited
// * Actions/Expressions objects. This avoids hard-coding generated implementation
// * classes while preserving their exact EClass names, features and references.
// */
//class TestspecificationJsonSerializer {
//    val JsonWriter jsonWriter = new JsonWriter
//
//    val Map<EObject, StepInfo> stepByVariable = new IdentityHashMap
//    val List<Map<String, Object>> diagnostics = new ArrayList
//
//    def String serialize(
//    EObject definition,
//    String sourceName ) 
//    {
//        stepByVariable.clear
//        diagnostics.clear
//
//        if (definition === null) {
//            throw new IllegalArgumentException(
//                "TestDefinition must not be null"
//            )
//        }
//
//        indexSteps(definition)
//
//        val result = linkedMap
//        result.put(
//            "format",
//            "comma-test-specification"
//        )
//        result.put(
//            "formatVersion",
//            "1.0"
//        )
//        result.put(
//            "source",
//            sourceName
//        )
//        result.put(
//            "testSequences",
//            serializeTestSequences(
//                list(definition, "testSeq")
//            )
//        )
//        result.put(
//            "stepSequences",
//            serializeStepSequences(
//                list(definition, "stepSeq")
//            )
//        )
//        result.put(
//            "globalParameterInitializations",
//            serializeActions(
//                list(definition, "gparamsInitActions"),
//                null
//            )
//        )
//        result.put(
//            "sutParameterInitializations",
//            serializeActions(
//                list(definition, "sutInitActions"),
//                null
//            )
//        )
//        result.put(
//            "diagnostics",
//            diagnostics
//        )
//        jsonWriter.write(result)
//    }
//
//    private def void indexSteps(EObject definition) {
//        for (sequence : list(definition, "stepSeq")) {
//            var index = 0
//            for (step : list(sequence, "step")) {
//                val variable = value(step, "inputVar") as EObject
//                if (variable !== null) stepByVariable.put(variable,
//                    new StepInfo(name(variable), name(sequence), index, step.eClass.name))
//                index++
//            }
//        }
//    }
//
//    private def List<Object> serializeTestSequences(List<EObject> sequences) {
//        val resultList = new ArrayList<Object>
//        for (sequence : sequences) {
//            val result = linkedMap
//            result.put("name", scalar(sequence, "name"))
//            val references = new ArrayList<Object>
//            for (referencedSequence : list(sequence, "stepSeqRef")) {
//                references.add(name(referencedSequence))
//            }
//            result.put("stepSequences", references)
//            resultList.add(result)
//        }
//        resultList
//    }
//
//    private def List<Object> serializeStepSequences(List<EObject> sequences) {
//        val resultList = new ArrayList<Object>
//        for (sequence : sequences) {
//            val result = linkedMap
//            result.put("name", scalar(sequence, "name"))
//            val steps = new ArrayList<Object>
//            var index = 0
//            for (step : list(sequence, "step")) {
//                steps.add(serializeStep(step, sequence, index))
//                index++
//            }
//            result.put("steps", steps)
//            resultList.add(result)
//        }
//        resultList
//    }
//
//    private def Map<String, Object> serializeStep(EObject step, EObject sequence, int index) {
//        val result = linkedMap
//        val kind = if (step.eClass.name == "AssertionStep") "assertion" else "run"
//        result.put("index", index)
//        result.put("kind", kind)
//        result.put("name", name(value(step, "inputVar") as EObject))
//        result.put("type", name(value(step, "type") as EObject))
//        result.put("input", name(value(step, "stepVar") as EObject))
//        result.put("features", list(step, "featuresForStep").map[name(it)].toList)
//
//        val refs = new ArrayList<Object>
//        val dependencies = new ArrayList<Object>
//        for (refStep : list(step, "refStep")) {
//            val refJson = linkedMap
//            refJson.put("features", list(refStep, "featuresToOutput").map[name(it)].toList)
//            val actions = serializeActionList(value(refStep, "input") as EObject, step)
//            refJson.put("actions", actions)
//            refs.add(refJson)
//            for (action : actions) {
//                val map = action as Map<String, Object>
//                val deps = map.get("dependencies")
//                if (deps instanceof Iterable<?>) dependencies.addAll(deps as Iterable<Object>)
//            }
//        }
//        result.put("referenceInputs", refs)
//
//        // Assertion expressions can also refer to outputs of preceding steps.
//        // Serialize each assertion group and merge its dependencies into the
//        // same step-level dependency summary used for ref-to-step-output.
//        if (kind == "assertion") {
//            val assertions = new ArrayList<Object>
//            for (assertionGroup : list(step, "asserts")) {
//                val assertionJson = serializeAssertion(assertionGroup, step)
//                assertions.add(assertionJson)
//                val assertionDependencies = assertionJson.get("dependencies")
//                if (assertionDependencies instanceof Iterable<?>) {
//                    dependencies.addAll(assertionDependencies as Iterable<Object>)
//                }
//            }
//            result.put("assertions", assertions)
//        }
//
//        result.put("dependencies", uniqueDependencies(dependencies))
//        result
//    }
//
//    private def Map<String, Object> serializeAssertion(EObject assertionGroup, EObject currentStep) {
//        val result = compactElement(assertionGroup)
//        val dependencies = new ArrayList<Object>
//        val items = new ArrayList<Object>
//
//        for (item : list(assertionGroup, "constr")) {
//            val targetPath = assertionTargetPath(assertionGroup, item)
//            // val itemJson = compactElement(item)
//            val itemJson = compactExpression(item)
//            itemJson.put("targetPath", targetPath)
//            itemJson.put("dependencies", uniqueDependencies(
//                collectDependencies(item, currentStep, targetPath)
//            ))
//            items.add(itemJson)
//            dependencies.addAll(collectDependencies(item, currentStep, targetPath))
//        }
//
//        result.put("items", items)
//        result.put("dependencies", uniqueDependencies(dependencies))
//        result
//    }
//
//    private def List<String> assertionTargetPath(EObject assertionGroup, EObject item) {
//        val result = new ArrayList<String>
//        result.add("assertions")
//        val groupName = name(assertionGroup)
//        if (groupName !== null) result.add(groupName)
//        val itemName = name(item)
//        if (itemName !== null) result.add(itemName)
//
//        // AssertThatBlock stores the checked expression in 'output'. Script
//        // blocks may contain several arguments, for which the item path is the
//        // most precise common target available.
//        if (value(item, "output") instanceof EObject) result.add("output")
//        result
//    }
//
//    private def List<Object> serializeActionList(EObject actionList, EObject currentStep) {
//        val result = new ArrayList<Object>
//        if (actionList === null) return result
//        val directActions = containmentChildren(actionList).filter[
//            eClass.name.endsWith("Action") || eClass.name == "ActionList"
//        ].toList
//        val actions = if (directActions.empty) #[actionList] else directActions
//        for (action : actions) result.add(serializeAction(action, currentStep))
//        result
//    }
//
//    private def List<Object> serializeActions(List<EObject> actions, EObject currentStep) {
//        val result = new ArrayList<Object>
//        for (action : actions) result.add(serializeAction(action, currentStep))
//        result
//    }
//
//    private def Map<String, Object> serializeAction(EObject action, EObject currentStep) {
//        val result = linkedMap
//        result.put("kind", lowerFirst(action.eClass.name))
//        result.put("modelType", action.eClass.name)
//        result.put("text", sourceText(action))
//
//        // Exact XPlus Actions features are:
//        // AssignmentAction.assignment + exp, and
//        // RecordFieldAssignmentAction.fieldAccess + exp.
//        val lhs = firstEObject(action, #["fieldAccess", "assignment", "lhs", "left", "target", "variable"])
//        val rhs = firstEObject(action, #["exp", "rhs", "right", "value", "expression"])
//        val targetPath = expressionPath(lhs)
//
//        if (lhs !== null) result.put("target", compactExpression(lhs))
//        if (!targetPath.empty) result.put("targetPath", withoutRoot(targetPath))
//        if (rhs !== null) result.put("expression", compactExpression(rhs))
//        if (lhs === null && rhs === null) result.put("element", compactElement(action))
//        result.put("dependencies", collectDependencies(if (rhs !== null) rhs else action, currentStep, withoutRoot(targetPath)))
//        result
//    }
//
//    private def List<Object> collectDependencies(EObject expression, EObject currentStep, List<String> targetPath) {
//        val result = new ArrayList<Object>
//        val currentInfo = if (currentStep === null) null else stepByVariable.get(value(currentStep, "inputVar") as EObject)
//        val visited = new LinkedHashSet<EObject>
//        visit(expression, visited) [ object |
//            for (reference : object.eClass.EAllReferences.filter[!containment && !container]) {
//                val referenced = object.eGet(reference)
//                if (referenced instanceof EObject) addDependency(result, referenced, currentInfo, object, targetPath)
//                else if (referenced instanceof Iterable<?>)
//                    for (item : referenced as Iterable<?>) if (item instanceof EObject)
//                        addDependency(result, item, currentInfo, object, targetPath)
//            }
//        ]
//        result
//    }
//
//    private def void addDependency(List<Object> output, EObject referenced, StepInfo current, EObject occurrence, List<String> targetPath) {
//        val source = stepByVariable.get(referenced)
//        if (source === null) return
//        val classification = if (current === null) "step-reference"
//            else if (source.sequence != current.sequence) "other-sequence"
//            else if (source.index < current.index) "preceding-step"
//            else if (source.index == current.index) "same-step"
//            else "forward-step"
//        val dependency = linkedMap
//        dependency.put("sourceStep", source.name)
//        dependency.put("sourceStepIndex", source.index)
//        dependency.put("sourceSequence", source.sequence)
//        if (current !== null) {
//            dependency.put("targetStep", current.name)
//            dependency.put("targetStepIndex", current.index)
//            dependency.put("targetSequence", current.sequence)
//        }
//        dependency.put("sourcePath", sourcePath(occurrence, referenced))
//        dependency.put("targetPath", new ArrayList<String>(targetPath))
//        dependency.put("classification", classification)
//        dependency.put("expressionText", sourceText(topPathExpression(occurrence)))
//        output.add(dependency)
//        if (classification == "forward-step") diagnostics.add(diagnostic("warning", "FORWARD_STEP_REFERENCE",
//            "Step '" + current.name + "' references later step '" + source.name + "'."))
//    }
//
//    /** Returns a variable/record-access path, including its root variable. */
//    private def List<String> expressionPath(EObject expression) {
//        val result = new ArrayList<String>
//        if (expression === null) return result
//
//        switch expression.eClass.name {
//            case "ExpressionVariable": {
//                val variable = value(expression, "variable") as EObject
//                val variableName = name(variable)
//                if (variableName !== null) result.add(variableName)
//            }
//            case "ExpressionRecordAccess": {
//                result.addAll(expressionPath(value(expression, "record") as EObject))
//                val field = value(expression, "field") as EObject
//                val fieldName = name(field)
//                if (fieldName !== null) result.add(fieldName)
//            }
//            case "ExpressionBracket": {
//                result.addAll(expressionPath(value(expression, "sub") as EObject))
//            }
//            default: {
//                // AssignmentAction.assignment is a direct Variable reference,
//                // not an ExpressionVariable containment.
//                val directName = name(expression)
//                if (directName !== null) result.add(directName)
//            }
//        }
//        result
//    }
//
//    private def List<String> withoutRoot(List<String> path) {
//        val result = new ArrayList<String>
//        if (path !== null && path.size > 1) {
//            for (var i = 1; i < path.size; i++) result.add(path.get(i))
//        }
//        result
//    }
//
//    /**
//     * Ascend from the ExpressionVariable occurrence through its enclosing
//     * record-access chain and return the path after the referenced step name.
//     */
//    private def List<String> sourcePath(EObject occurrence, EObject referencedVariable) {
//        val fullPath = expressionPath(topPathExpression(occurrence))
//        if (!fullPath.empty && fullPath.get(0) == name(referencedVariable)) {
//            return withoutRoot(fullPath)
//        }
//        new ArrayList<String>
//    }
//
//    private def EObject topPathExpression(EObject occurrence) {
//        var current = occurrence
//        var parent = current?.eContainer
//        while (parent !== null && (
//            (parent.eClass.name == "ExpressionRecordAccess" && value(parent, "record") === current) ||
//            parent.eClass.name == "ExpressionBracket"
//        )) {
//            current = parent
//            parent = current.eContainer
//        }
//        current
//    }
//
//    private def List<Object> uniqueDependencies(List<Object> dependencies) {
//        val seen = new LinkedHashSet<String>
//        dependencies.filter [ item |
//            val key = item.toString
//            if (seen.contains(key)) false else { seen.add(key); true }
//        ].toList
//    }
//
//    /**
//     * Produces a recursively normalized, diff-friendly representation.
//     *
//     * The original source remains available in "text", but downstream tools
//     * should compare the structured attributes, references, fields, items,
//     * entries, operands and arguments.
//     */
//    private def Map<String, Object> compactExpression(EObject expression) {
//        if (expression === null) {
//            return linkedMap("kind", "null")
//        }
//    
//        val normalized = normalizeEObject(
//            expression,
//            new LinkedHashSet<EObject>
//        )
//    
//        val result = normalized as Map<String, Object>
//        val path = expressionPath(expression)
//    
//        if (!path.empty) {
//            result.put("path", path)
//        }
//    
//        result
//    }
//    
//    /**
//     * Compact representation for non-expression model elements.
//     *
//     * Containment is serialized recursively so records, lists, maps and
//     * compound assertion elements are not reduced to source text.
//     */
//    private def Map<String, Object> compactElement(EObject object) {
//        if (object === null) {
//            return linkedMap("kind", "null")
//        }
//    
//        normalizeEObject(
//            object,
//            new LinkedHashSet<EObject>
//        ) as Map<String, Object>
//    }
//    
//    /**
//     * Recursive EMF-to-normalized-JSON conversion.
//     *
//     * This intentionally works against the Ecore model rather than generated
//     * implementation classes. Consequently, inherited Actions/Expressions
//     * model elements are also handled.
//     */
//    private def Object normalizeEObject(
//        EObject object,
//        Set<EObject> active
//    ) {
//        if (object === null) {
//            return null
//        }
//    
//        if (active.contains(object)) {
//            val reference = linkedMap
//            reference.put("kind", "reference")
//            reference.put("modelType", object.eClass.name)
//    
//            val objectName = name(object)
//            if (objectName !== null) {
//                reference.put("name", objectName)
//            }
//    
//            return reference
//        }
//    
//        active.add(object)
//    
//        val className = object.eClass.name
//        val classNameLower = className.toLowerCase
//    
//        val result = linkedMap
//        result.put("kind", normalizedKind(object))
//        result.put("modelType", className)
//    
//        /*
//         * Retain source text strictly for traceability. Semantic comparison
//         * should normally exclude this property.
//         */
//        val text = sourceText(object)
//        if (text !== null && !text.empty) {
//            result.put("text", text)
//        }
//    
//        /*
//         * Null expressions must carry an actual JSON null value.
//         */
//        if (
//            classNameLower.contains("null") &&
//            (
//                classNameLower.contains("expression") ||
//                classNameLower.contains("literal")
//            )
//        ) {
//            result.put("value", null)
//        }
//    
//        /*
//         * Copy primitive EAttributes. This handles strings, numbers, Boolean
//         * values, operators, literal contents and other scalar metadata.
//         */
//        for (
//            attribute :
//                object.eClass.EAllAttributes.filter[
//                    !derived && object.eIsSet(it)
//                ]
//        ) {
//            val attributeValue = object.eGet(attribute)
//    
//            result.put(
//                normalizedAttributeName(
//                    object,
//                    attribute.name
//                ),
//                normalizeScalar(attributeValue)
//            )
//        }
//    
//        /*
//         * Serialize every reference. Containment references are recursively
//         * normalized. Cross-references remain compact named references.
//         */
//        for (
//            reference :
//                object.eClass.EAllReferences.filter[
//                    object.eIsSet(it)
//                ]
//        ) {
//            val rawValue = object.eGet(reference)
//            val outputName = normalizedReferenceName(
//                object,
//                reference.name
//            )
//    
//            if (reference.containment) {
//                if (rawValue instanceof EObject) {
//                    result.put(
//                        outputName,
//                        normalizeEObject(
//                            rawValue,
//                            active
//                        )
//                    )
//                } else if (rawValue instanceof Iterable<?>) {
//                    val values = new ArrayList<Object>
//    
//                    for (item : rawValue as Iterable<?>) {
//                        if (item instanceof EObject) {
//                            values.add(
//                                normalizeEObject(
//                                    item,
//                                    active
//                                )
//                            )
//                        } else {
//                            values.add(
//                                normalizeScalar(item)
//                            )
//                        }
//                    }
//    
//                    result.put(outputName, values)
//                }
//            } else {
//                if (rawValue instanceof EObject) {
//                    result.put(
//                        outputName,
//                        normalizeReference(
//                            rawValue
//                        )
//                    )
//                } else if (rawValue instanceof Iterable<?>) {
//                    val references = new ArrayList<Object>
//    
//                    for (item : rawValue as Iterable<?>) {
//                        if (item instanceof EObject) {
//                            references.add(
//                                normalizeReference(
//                                    item
//                                )
//                            )
//                        }
//                    }
//    
//                    result.put(
//                        outputName,
//                        references
//                    )
//                }
//            }
//        }
//    
//        /*
//         * Add a convenient path for variable and record-access expressions.
//         */
//        val path = expressionPath(object)
//        if (!path.empty) {
//            result.put("path", path)
//        }
//    
//        /*
//         * Add a canonical literal value when the metamodel stores the value
//         * under a model-specific attribute name.
//         */
//        addCanonicalLiteralValue(
//            object,
//            result
//        )
//    
//        active.remove(object)
//        result
//    }
//    
//    /**
//     * Converts cross-references without recursively expanding the referenced
//     * model object.
//     */
//    private def Map<String, Object> normalizeReference(
//        EObject target
//    ) {
//        val result = linkedMap
//        result.put("kind", "reference")
//        result.put("modelType", target.eClass.name)
//    
//        val targetName = name(target)
//        if (targetName !== null) {
//            result.put("name", targetName)
//        }
//    
//        val step = stepByVariable.get(target)
//    
//        if (step !== null) {
//            result.put("step", step.name)
//            result.put("stepIndex", step.index)
//            result.put("stepSequence", step.sequence)
//        }
//    
//        result
//    }
//    
//    /**
//     * Produces stable semantic kind names for commonly occurring Expressions
//     * language constructs.
//     */
//    private def String normalizedKind(EObject object) {
//        val className = object.eClass.name
//        val lower = className.toLowerCase
//    
//        if (
//            lower.contains("null") &&
//            (
//                lower.contains("expression") ||
//                lower.contains("literal")
//            )
//        ) {
//            return "null"
//        }
//    
//        if (
//            lower.contains("constantstring") ||
//            lower.contains("stringliteral")
//        ) {
//            return "string"
//        }
//    
//        if (
//            lower.contains("constantint") ||
//            lower.contains("integerliteral")
//        ) {
//            return "integer"
//        }
//    
//        if (
//            lower.contains("constantreal") ||
//            lower.contains("realliteral") ||
//            lower.contains("doubleliteral")
//        ) {
//            return "real"
//        }
//    
//        if (
//            lower.contains("constantbool") ||
//            lower.contains("booleanliteral")
//        ) {
//            return "boolean"
//        }
//    
//        if (
//            lower.contains("enum") &&
//            lower.contains("literal")
//        ) {
//            return "enum"
//        }
//    
//        if (
//            lower.contains("vector") ||
//            lower.contains("collection") ||
//            lower.contains("array") ||
//            lower.contains("list")
//        ) {
//            return "list"
//        }
//    
//        if (
//            lower.contains("record") &&
//            !lower.contains("access") &&
//            !lower.contains("assignment")
//        ) {
//            return "record"
//        }
//    
//        if (
//            lower.contains("map") &&
//            lower.contains("entry")
//        ) {
//            return "mapEntry"
//        }
//    
//        if (lower.contains("map")) {
//            return "map"
//        }
//    
//        if (
//            lower.contains("function") ||
//            lower.contains("operation") ||
//            lower.contains("call")
//        ) {
//            return "functionCall"
//        }
//    
//        if (lower.contains("conditional")) {
//            return "conditional"
//        }
//    
//        if (
//            lower.contains("coalesc") ||
//            lower.contains("nullsafe")
//        ) {
//            return "nullCoalescing"
//        }
//    
//        if (
//            lower.contains("recordaccess") ||
//            lower.contains("featureaccess") ||
//            lower.contains("fieldaccess")
//        ) {
//            return "featureAccess"
//        }
//    
//        if (
//            lower.contains("variable") &&
//            lower.contains("expression")
//        ) {
//            return "variable"
//        }
//    
//        if (
//            lower.contains("binary") ||
//            lower.contains("addition") ||
//            lower.contains("multiplication") ||
//            lower.contains("comparison") ||
//            lower.contains("equality") ||
//            lower.contains("and") ||
//            lower.contains("or")
//        ) {
//            return "binary"
//        }
//    
//        if (
//            lower.contains("unary") ||
//            lower.contains("minus") ||
//            lower.contains("not")
//        ) {
//            return "unary"
//        }
//    
//        lowerFirst(className)
//    }
//    
//    /**
//     * Normalizes containment-reference names into a predictable vocabulary.
//     */
//    private def String normalizedReferenceName(
//        EObject owner,
//        String featureName
//    ) {
//        val ownerName = owner.eClass.name.toLowerCase
//        val featureLower = featureName.toLowerCase
//    
//        /*
//         * Collection contents become "items".
//         */
//        if (
//            ownerName.contains("vector") ||
//            ownerName.contains("collection") ||
//            ownerName.contains("array") ||
//            ownerName.contains("list")
//        ) {
//            if (
//                featureLower == "elements" ||
//                featureLower == "element" ||
//                featureLower == "values" ||
//                featureLower == "value" ||
//                featureLower == "expressions" ||
//                featureLower == "expression" ||
//                featureLower == "items" ||
//                featureLower == "item" ||
//                featureLower == "contents" ||
//                featureLower == "content" ||
//                featureLower == "args" ||
//                featureLower == "arguments"
//            ) {
//                return "items"
//            }
//        }
//    
//        /*
//         * Record members become "fields".
//         */
//        if (
//            ownerName.contains("record") &&
//            !ownerName.contains("access")
//        ) {
//            if (
//                featureLower == "fields" ||
//                featureLower == "field" ||
//                featureLower == "assignments" ||
//                featureLower == "assignment" ||
//                featureLower == "members" ||
//                featureLower == "member" ||
//                featureLower == "values" ||
//                featureLower == "entries"
//            ) {
//                return "fields"
//            }
//        }
//    
//        /*
//         * Map collections become "entries".
//         */
//        if (
//            ownerName.contains("map") &&
//            !ownerName.contains("entry")
//        ) {
//            if (
//                featureLower == "entries" ||
//                featureLower == "entry" ||
//                featureLower == "values" ||
//                featureLower == "elements" ||
//                featureLower == "items"
//            ) {
//                return "entries"
//            }
//        }
//    
//        /*
//         * Function parameters become "arguments".
//         */
//        if (
//            ownerName.contains("function") ||
//            ownerName.contains("operation") ||
//            ownerName.contains("call")
//        ) {
//            if (
//                featureLower == "args" ||
//                featureLower == "arg" ||
//                featureLower == "parameters" ||
//                featureLower == "parameter" ||
//                featureLower == "expressions"
//            ) {
//                return "arguments"
//            }
//        }
//    
//        /*
//         * Common operator aliases.
//         */
//        switch featureLower {
//            case "sub":
//                return "operand"
//    
//            case "operand":
//                return "operand"
//    
//            case "left":
//                return "left"
//    
//            case "lhs":
//                return "left"
//    
//            case "right":
//                return "right"
//    
//            case "rhs":
//                return "right"
//    
//            case "condition":
//                return "condition"
//    
//            case "then":
//                return "then"
//    
//            case "thenexpression":
//                return "then"
//    
//            case "iftrue":
//                return "then"
//    
//            case "else":
//                return "else"
//    
//            case "elseexpression":
//                return "else"
//    
//            case "iffalse":
//                return "else"
//    
//            case "key":
//                return "key"
//    
//            case "value":
//                return "value"
//    
//            case "record":
//                return "receiver"
//    
//            case "receiver":
//                return "receiver"
//    
//            case "target":
//                return "receiver"
//    
//            default:
//                return featureName
//        }
//    }
//    
//    private def String normalizedAttributeName(
//        EObject owner,
//        String attributeName
//    ) {
//        val ownerName = owner.eClass.name.toLowerCase
//        val attributeLower = attributeName.toLowerCase
//    
//        if (
//            ownerName.contains("constant") ||
//            ownerName.contains("literal")
//        ) {
//            if (
//                attributeLower == "val" ||
//                attributeLower == "literal" ||
//                attributeLower == "string" ||
//                attributeLower == "integer" ||
//                attributeLower == "real" ||
//                attributeLower == "boolean"
//            ) {
//                return "value"
//            }
//        }
//    
//        if (
//            attributeLower == "op" ||
//            attributeLower == "operator"
//        ) {
//            return "operator"
//        }
//    
//        attributeName
//    }
//    
//    private def Object normalizeScalar(Object rawValue) {
//        if (
//            rawValue === null ||
//            rawValue instanceof String ||
//            rawValue instanceof Number ||
//            rawValue instanceof Boolean
//        ) {
//            return rawValue
//        }
//    
//        if (rawValue instanceof Enum<?>) {
//            return rawValue.toString
//        }
//    
//        rawValue.toString
//    }
//    
//    /**
//     * Adds "value" for primitive, enum and null expressions, even when the
//     * concrete metamodel feature has another name.
//     */
//    private def void addCanonicalLiteralValue(
//        EObject object,
//        Map<String, Object> result
//    ) {
//        val className = object.eClass.name.toLowerCase
//    
//        if (
//            className.contains("null") &&
//            (
//                className.contains("expression") ||
//                className.contains("literal")
//            )
//        ) {
//            result.put("value", null)
//            return
//        }
//    
//        if (
//            className.contains("constant") ||
//            className.contains("literal")
//        ) {
//            if (result.containsKey("value")) {
//                return
//            }
//    
//            val preferredAttributes = #[
//                "value",
//                "val",
//                "literal",
//                "string",
//                "integer",
//                "real",
//                "boolean"
//            ]
//    
//            for (attributeName : preferredAttributes) {
//                val feature = object.eClass.getEStructuralFeature(
//                    attributeName
//                )
//    
//                if (
//                    feature !== null &&
//                    object.eIsSet(feature)
//                ) {
//                    result.put(
//                        "value",
//                        normalizeScalar(
//                            object.eGet(feature)
//                        )
//                    )
//    
//                    return
//                }
//            }
//    
//            /*
//             * Enum literals are frequently stored as cross-references.
//             */
//            val enumFeatures = #[
//                "literal",
//                "enumLiteral",
//                "value"
//            ]
//    
//            for (featureName : enumFeatures) {
//                val rawValue = value(
//                    object,
//                    featureName
//                )
//    
//                if (rawValue instanceof EObject) {
//                    result.put(
//                        "value",
//                        name(rawValue)
//                    )
//    
//                    return
//                }
//            }
//        }
//    }
//    
//    /*
//     * Kept as a compatibility entry point for existing callers.
//     */
//    private def Object serializeEObject(
//        EObject object,
//        Set<EObject> active
//    ) {
//        normalizeEObject(object, active)
//    }
//
////    /** Compact representation intended for downstream generators. */
////    private def Map<String, Object> compactExpression(EObject expression) {
////        val result = compactElement(expression)
////        val path = expressionPath(expression)
////        if (!path.empty) result.put("path", path)
////        result
////    }
////
////    private def Map<String, Object> compactElement(EObject object) {
////        val result = linkedMap
////        if (object !== null) {
////            result.put("kind", lowerFirst(object.eClass.name))
////            result.put("modelType", object.eClass.name)
////            val objectName = name(object)
////            val text = sourceText(object)
////            if (objectName !== null && objectName != text) result.put("name", objectName)
////            if (text !== null && !text.empty) result.put("text", text)
////        }
////        result
////    }
////
////    private def Object serializeEObject(EObject object, Set<EObject> active) {
////        if (object === null) return null
////        if (active.contains(object)) return linkedMap("$ref", name(object))
////        active.add(object)
////        val result = linkedMap
////        result.put("kind", lowerFirst(object.eClass.name))
////        result.put("modelType", object.eClass.name)
////        val text = sourceText(object)
////        if (text !== null && !text.empty) result.put("text", text)
////        for (attribute : object.eClass.EAllAttributes.filter[!derived && object.eIsSet(it)])
////            result.put(attribute.name, jsonScalar(object.eGet(attribute)))
////        for (reference : object.eClass.EAllReferences.filter[object.eIsSet(it)]) {
////            val raw = object.eGet(reference)
////            if (reference.containment) {
////                if (raw instanceof EObject) result.put(reference.name, serializeEObject(raw, active))
////                else if (raw instanceof Iterable<?>) result.put(reference.name,
////                    raw.filter(EObject).map[serializeEObject(it, active)].toList)
////            } else {
////                if (raw instanceof EObject) result.put(reference.name, referenceJson(raw))
////                else if (raw instanceof Iterable<?>) result.put(reference.name,
////                    raw.filter(EObject).map[referenceJson(it)].toList)
////            }
////        }
////        active.remove(object)
////        result
////    }
//
//    private def Map<String, Object> referenceJson(EObject target) {
//        val result = linkedMap
//        result.put("modelType", target.eClass.name)
//        result.put("name", name(target))
//        val step = stepByVariable.get(target)
//        if (step !== null) {
//            result.put("step", step.name)
//            result.put("stepIndex", step.index)
//            result.put("stepSequence", step.sequence)
//        }
//        result
//    }
//
//    private def void visit(EObject object, Set<EObject> visited, Procedure1<EObject> consumer) {
//        if (object !== null && !visited.contains(object)) {
//            visited.add(object)
//            consumer.apply(object)
//            for (child : containmentChildren(object)) {
//                visit(child, visited, consumer)
//            }
//        }
//    }
//
//    private def Iterable<EObject> containmentChildren(EObject object) {
//        object.eClass.EAllContainments.map[object.eGet(it)].flatMap [ raw |
//            if (raw instanceof EObject) #[raw]
//            else if (raw instanceof Iterable<?>) raw.filter(EObject)
//            else #[]
//        ]
//    }
//
//    private def EObject firstEObject(EObject object, List<String> names) {
//        for (candidate : names) {
//            val feature = object.eClass.getEStructuralFeature(candidate)
//            if (feature !== null && object.eIsSet(feature)) {
//                val raw = object.eGet(feature)
//                if (raw instanceof EObject) return raw
//            }
//        }
//        null
//    }
//
//    private def Object value(EObject object, String featureName) {
//        if (object === null) return null
//        val feature = object.eClass.getEStructuralFeature(featureName)
//        if (feature === null) return null
//        object.eGet(feature)
//    }
//
//    private def List<EObject> list(EObject object, String featureName) {
//        val raw = value(object, featureName)
//        if (raw instanceof Iterable<?>) raw.filter(EObject).toList else newArrayList
//    }
//
//    private def Object scalar(EObject object, String featureName) {
//        jsonScalar(value(object, featureName))
//    }
//
//    private def Object jsonScalar(Object value) {
//        if (value === null || value instanceof String || value instanceof Number || value instanceof Boolean) value
//        else if (value instanceof Enum<?>) value.toString
//        else value.toString
//    }
//
//    private def String name(EObject object) {
//        if (object === null) return null
//        val raw = value(object, "name")
//        if (raw === null) sourceText(object) else raw.toString
//    }
//
//    private def String sourceText(EObject object) {
//        if (object === null) return null
//        val node = NodeModelUtils.getNode(object)
//        if (node === null) null else node.text.trim
//    }
//
//    private def String lowerFirst(String value) {
//        if (value === null || value.empty) value else value.substring(0, 1).toLowerCase + value.substring(1)
//    }
//
//    private def Map<String, Object> diagnostic(String severity, String code, String message) {
//        val result = linkedMap
//        result.put("severity", severity)
//        result.put("code", code)
//        result.put("message", message)
//        result
//    }
//
//    private def LinkedHashMap<String, Object> linkedMap() { new LinkedHashMap<String, Object> }
//    private def LinkedHashMap<String, Object> linkedMap(String key, Object value) {
//        val result = linkedMap
//        result.put(key, value)
//        result
//    }
//
//    private static class StepInfo {
//        val String name
//        val String sequence
//        val int index
//        val String modelType
//        new(String name, String sequence, int index, String modelType) {
//            this.name = name
//            this.sequence = sequence
//            this.index = index
//            this.modelType = modelType
//        }
//    }
//}
