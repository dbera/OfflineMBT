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
package nl.esi.comma.causalgraph.formatting

import com.google.inject.Inject
import nl.esi.comma.causalgraph.services.CausalGraphGrammarAccess
import org.eclipse.xtext.formatting.impl.AbstractDeclarativeFormatter
import org.eclipse.xtext.formatting.impl.FormattingConfig

class CausalGraphFormatter extends AbstractDeclarativeFormatter {
    @Inject
    @Extension
    var CausalGraphGrammarAccess grammarAccess;

    override protected configureFormatting(FormattingConfig it) {
        autoLinewrap = 120

        // Comments
        setLinewrap(0, 1, 2).before(SL_COMMENTRule)
        setLinewrap(0, 1, 2).before(ML_COMMENTRule)
        setLinewrap(0, 1, 1).after(ML_COMMENTRule)

        for (pair : findKeywordPairs("{", "}")) {
            setNoSpace().before(pair.first);
            setNoSpace().after(pair.first);
            setNoSpace().before(pair.second);
        }
        for (pair : findKeywordPairs("(", ")")) {
            setNoSpace().before(pair.first);
            setNoSpace().after(pair.first);
            setNoSpace().before(pair.second);
        }
        for (pair : findKeywordPairs("[", "]")) {
            setNoSpace().before(pair.first);
            setNoSpace().after(pair.first);
            setNoSpace().before(pair.second);
        }
        for (keyword : findKeywords(",",":")) {
            setNoSpace().before(keyword);
        }

        // TODO: Grammar formatting
        setLinewrap(1,1,2).after(requirementDeclRule)
        setLinewrap(1,1,2).after(scenarioDeclRule)

        setLinewrap(1,1,2).after(causalGraphAccess.nameAssignment_4)
        setLinewrap(1,1,2).after(causalGraphAccess.typeAssignment_8)
        setLinewrap(1,1,2).after(causalGraphAccess.languageAssignment_9_2)
        setLinewrap(1,1,2).after(causalGraphAccess.headerAssignment_10_2)

        setLinewrap(1,1,2).before(causalGraphAccess.typesAssignment_11_2)
        setLinewrap(1,1,2).after(typeDeclRule)
        setIndentation(causalGraphAccess.typesKeyword_11_0, causalGraphAccess.functionsKeyword_12_0)
        setLinewrap(1,1,2).after(functionDeclRule)
        setIndentation(causalGraphAccess.functionsKeyword_12_0, causalGraphAccess.variablesKeyword_13_0)
        setLinewrap(1,1,2).after(variableRule)
        setIndentation(causalGraphAccess.variablesKeyword_13_0, nodeAccess.nodeKeyword_0)
        setLinewrap(1,1,2).after(nodeRule)
        setLinewrap(1,1,2).after(nodeAccess.nameAssignment_1)
        setIndentation(nodeAccess.nameAssignment_1, nodeAccess.nodeKeyword_0)
        setLinewrap(1,1,2).after(nodeRule)
   }
}