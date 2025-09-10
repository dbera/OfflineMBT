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
        for (pair : findKeywordPairs("[", "]")) {
            setNoSpace().before(pair.first);
            setNoSpace().after(pair.first);
            setNoSpace().before(pair.second);
        }
        for (keyword : findKeywords(",", ":")) {
            setNoSpace().before(keyword);
        }

        // TODO: Grammar formatting
        setLinewrap(1,1,2).after(importRule)

        setLinewrap(1,2,2).after(requirementDeclRule)
        setLinewrap(1,1,1).before(requirementDeclAccess.descriptionKeyword_2_1_0)

        setLinewrap(1,2,2).before(scenarioDeclRule)
        setLinewrap(1,2,2).after(scenarioDeclRule)
        setLinewrap(1,1,1).before(scenarioDeclAccess.requirementsKeyword_3)
        setLinewrap(1,1,1).before(scenarioDeclAccess.descriptionKeyword_6_0)

        setLinewrap(1,2,2).before(causalGraphRule)
        setLinewrap(1,2,2).after(causalGraphRule)
        setLinewrap(1,1,2).before(causalGraphAccess.languageKeyword_6_0)
        setLinewrap(1,2,2).before(causalGraphAccess.headerKeyword_7_0)
        setLinewrap(1,2,2).before(causalGraphAccess.typesKeyword_8_0)
        setLinewrap(1,1,1).before(typeDeclRule)
        setLinewrap(1,2,2).before(causalGraphAccess.functionsKeyword_9_0)
        setLinewrap(1,1,1).before(functionDeclRule)
        setLinewrap(1,2,2).before(causalGraphAccess.variablesKeyword_10_0)
        setLinewrap(1,1,1).before(variableRule)
        setLinewrap(1,2,2).before(causalGraphAccess.initializationsKeyword_11_0)
        setLinewrap(1,1,1).before(assignmentActionRule)
        setLinewrap(1,2,2).before(causalGraphAccess.edgesKeyword_13_0)
        setLinewrap(1,1,1).before(edgeRule)

        setLinewrap(1,2,2).before(nodeRule)
        setLinewrap(1,2,2).after(nodeRule)
        setLinewrap(1,1,2).before(nodeAccess.stepNameKeyword_3)
        setLinewrap(1,1,2).before(nodeAccess.stepTypeKeyword_7_0)
        setLinewrap(1,1,2).before(nodeAccess.stepParametersKeyword_8_0)
        setLinewrap(1,1,2).before(nodeAccess.stepBodyKeyword_9_0)

        setLinewrap(1,2,2).before(scenarioStepRule)
        setLinewrap(1,2,2).after(scenarioStepRule)
        setLinewrap(1,1,2).before(scenarioStepAccess.stepArgumentsKeyword_4_1_0)
        setLinewrap(1,1,2).before(scenarioStepAccess.stepVariablesKeyword_4_2_0)
        setLinewrap(1,1,2).before(scenarioStepAccess.stepBodyKeyword_4_3_0)

        setIndentationIncrement.after(requirementDeclAccess.requirementKeyword_0)
        setIndentationDecrement.after(requirementDeclRule)
        setIndentationIncrement.after(scenarioDeclAccess.scenarioKeyword_0)
        setIndentationDecrement.after(scenarioDeclRule)
        setIndentationIncrement.after(causalGraphAccess.graphKeyword_3)
//        setIndentationIncrement.after(nodeAccess.nodeKeyword_0)
//        setIndentationDecrement.after(nodeRule)
//        setIndentationIncrement.after(scenarioStepAccess.scenarioKeyword_0)
//        setIndentationDecrement.after(scenarioStepRule)
        setIndentationDecrement.before(causalGraphAccess.edgesKeyword_13_0)
        setIndentationIncrement.after(causalGraphAccess.edgesKeyword_13_0)
   }
}