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
/*
 * generated by Xtext 2.19.0
 */
package nl.esi.comma.constraints.ui

import nl.esi.comma.constraints.ui.syntaxcoloring.SCLAntlrTokenToAttributeIdMapper
import nl.esi.comma.constraints.ui.syntaxcoloring.SCLHighlightingConfiguration
import nl.esi.comma.constraints.ui.syntaxcoloring.SCLSemanticHighlightingCalculator
import nl.esi.comma.types.ide.contentassist.TypesIdeContentProposalCreator
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalCreator
import org.eclipse.xtext.ide.editor.syntaxcoloring.AbstractAntlrTokenToAttributeIdMapper
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.ui.editor.hover.IEObjectHoverProvider
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfiguration

/**
 * Use this class to register components to be used within the Eclipse IDE.
 */
@FinalFieldsConstructor
class ConstraintsUiModule extends AbstractConstraintsUiModule {
	
	def Class<? extends IEObjectHoverProvider> bindIEObjectHoverProvider() {
		ConstraintsEObjectHoverProvider
	}
	
	def Class<? extends IHighlightingConfiguration> bindIHighlightingConfiguration(){
		SCLHighlightingConfiguration
	}
	
	def Class<? extends AbstractAntlrTokenToAttributeIdMapper> bindMapper(){
		SCLAntlrTokenToAttributeIdMapper
	}
	
	def Class<? extends ISemanticHighlightingCalculator> bindHighlightingCalculator(){
		SCLSemanticHighlightingCalculator
	}

    def Class<? extends IdeContentProposalCreator> bindIdeContentProposalCreator() {
        return TypesIdeContentProposalCreator
    }
}
