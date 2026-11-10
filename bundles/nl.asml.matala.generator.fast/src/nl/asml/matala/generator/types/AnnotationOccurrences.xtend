/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.util.EcoreUtil
import nl.esi.xtext.common.lang.base.Annotatable
import nl.esi.xtext.common.lang.utilities.AnnotationUtil

/**
 * Preserve annotation occurrences, including zero-argument annotations.
 * Values are decoded by the existing AnnotationUtil, one occurrence at a time.
 * No source text, regular-expression annotation parsing, or AST mutation.
 *
 * The supplied archive omits the Common Lang generated annotation interfaces.
 * This small bridge therefore discovers the direct, many-valued annotation
 * containment through EMF metadata instead of inventing Java accessor names.
 * It requires annotation names to be scalar string attributes of each annotation.
 */
final class AnnotationOccurrences {
    private new() {}

    static class Occurrence {
        public val String name
        public val Map<String, Object> values

        new(String name, Map<String, Object> values) {
            this.name = name
            this.values = values
        }
    }

    def static List<Occurrence> read(Annotatable owner, Set<String> supported) {
        val feature = annotationFeature(owner)
        val annotations = children(owner, feature)
        val result = new ArrayList<Occurrence>()
        var int index = 0
        while (index < annotations.size()) {
            val annotation = annotations.get(index)
            val name = annotationName(annotation, supported)
            if (name !== null) {
                // Work on a detached copy so AnnotationUtil sees exactly ONE
                // occurrence, even when it otherwise returns only the first match.
                val isolated = EcoreUtil.copy(owner)
                val copies = children(isolated, feature)
                val selected = copies.get(index)
                for (other : copies) {
                    if (other !== selected) EcoreUtil.remove(other)
                }
                val decoded = AnnotationUtil.getAnnotationValues(isolated, name)
                result.add(new Occurrence(name, new LinkedHashMap<String, Object>(decoded)))
            }
            index++
        }
        result
    }

    def private static EReference annotationFeature(Annotatable owner) {
        // Prefer the conventional feature name, then the annotation element type.
        val named = owner.eClass().getEStructuralFeature("annotations")
        if (named instanceof EReference) {
            if (named.containment && named.many) return named
        }
        val candidates = owner.eClass().EAllContainments.filter[
            many && EReferenceType.name == "Annotation"
        ].toList
        if (candidates.size() == 1) return candidates.head
        throw new IllegalArgumentException(
            "Cannot identify the annotation containment of " + owner.eClass().name +
            "; provide the Common Lang metamodel to bind this bridge to typed accessors"
        )
    }

    def private static List<EObject> children(EObject owner, EReference feature) {
        val value = owner.eGet(feature)
        if (!(value instanceof List<?>))
            throw new IllegalArgumentException("Expected an annotation list")
        val result = new ArrayList<EObject>()
        for (item : value as List<?>) {
            if (!(item instanceof EObject))
                throw new IllegalArgumentException("Expected annotation model objects")
            result.add(item as EObject)
        }
        result
    }

    def private static String annotationName(EObject annotation, Set<String> supported) {
        // Names such as name/id differ between generated metamodel versions.
        // A recognized scalar name is enough; argument values are contained nodes,
        // not attributes of the annotation itself.
        var String match = null
        for (attribute : annotation.eClass().EAllAttributes) {
            if (!attribute.many) {
                val value = annotation.eGet(attribute)
                if (value instanceof String) {
                    if (supported.contains(value)) {
                        if (match !== null && match != value)
                            throw new IllegalArgumentException("Ambiguous annotation name")
                        match = value
                    }
                }
            }
        }
        match
    }
}
