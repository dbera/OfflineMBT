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
package nl.esi.comma.constraints.ui.syntaxcoloring

import org.eclipse.xtext.ide.editor.syntaxcoloring.DefaultAntlrTokenToAttributeIdMapper

class SCLAntlrTokenToAttributeIdMapper extends DefaultAntlrTokenToAttributeIdMapper {
	
	override protected calculateId(String tokenName, int tokenType) {
		if (tokenName.equals("\'step-seq\'")){
			return SCLHighlightingConfiguration.STEP_SEQ
		}
		
		if (tokenName.equals("\'act-seq\'")){
			return SCLHighlightingConfiguration.ACT_SEQ
		}
		
		if (tokenName.equals("\'step\'")){
			return SCLHighlightingConfiguration.STEP
		}
		
		if (tokenName.equals("\'act\'")){
			return SCLHighlightingConfiguration.ACT
		}
		if (tokenName.equals("\'constraint-id\'")){
			return SCLHighlightingConfiguration.CONSTRAINT_ID
		}
		super.calculateId(tokenName, tokenType)
	}
}