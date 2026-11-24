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
package nl.asml.matala.product.validation

import java.util.Collections
import java.util.List
import nl.esi.xplus.extensions.types.RecordFieldKind
import nl.esi.xtext.types.types.RecordField
import nl.esi.xtext.types.types.RecordTypeDecl
import nl.esi.xtext.types.types.TypesPackage
import org.eclipse.emf.ecore.EPackage
import org.eclipse.xtext.validation.AbstractDeclarativeValidator
import org.eclipse.xtext.validation.Check

import static extension nl.esi.xplus.extensions.types.TypesExtensionUtil.*
import static extension nl.esi.xtext.types.utilities.TypeUtilities.*
import static extension org.eclipse.lsat.common.xtend.Queries.*

/**
 * Additional validations on top of the types language that are active whenever the product language is active.
 * <p>
 * This validator is not language specific, so it is invoked for every resource that contains types model elements
 * (e.g. *.types files), as soon as the product injector has been created (see ProductRuntimeModule).
 * </p>
 */
class ProductTypesValidator extends AbstractDeclarativeValidator {
    override protected List<EPackage> getEPackages() {
        return #[TypesPackage.eINSTANCE]
    }

    override isLanguageSpecific() {
        return false
    }

    @Check
    def checkRecordFieldAnnotations(RecordField field) {
        val symbolic = field.annotations.findFirst[name == 'symbolic']
        val mixed = field.annotations.findFirst[name == 'mixed']
        val suppress = field.annotations.findFirst[name == 'suppress']

        if (symbolic !== null && mixed !== null) {
            warning('''Symbolic annotation has no effect for record field '«field.FQN»' as mixed has precedence''',
                symbolic, null)
        }
        if ((symbolic !== null || mixed !== null) && suppress !== null) {
            error('''«(mixed ?: symbolic).name.toFirstUpper» record field '«field.FQN»' cannot be supressed''',
                suppress, null)
        }
    }

    @Check
    def checkRecordAnnotations(RecordTypeDecl typeDecl) {
        if (!typeDecl.isContext) {
            return
        }
        typeDecl.fields.forEach [ field, index |
            if (field.kind !== RecordFieldKind.CONCRETE) {
                error('''Context type «typeDecl.name» can only contain concrete fields''',
                    TypesPackage.Literals.RECORD_TYPE_DECL__FIELDS, index)
            }
            if (Collections.singleton(field).closure[subFields].exists[kind !== RecordFieldKind.CONCRETE]) {
                error('''All nested fields of context field '«field.FQN»' should be concrete''',
                    TypesPackage.Literals.RECORD_TYPE_DECL__FIELDS, index)
            }
        ]
    }

    private static def getFQN(RecordField rf) '''«rf.recordType.name».«rf.name»'''

    def private static List<RecordField> getSubFields(RecordField field) {
        val typeDecl = field.type.type
        return typeDecl instanceof RecordTypeDecl ? typeDecl.fields : Collections.emptyList
    }
}
