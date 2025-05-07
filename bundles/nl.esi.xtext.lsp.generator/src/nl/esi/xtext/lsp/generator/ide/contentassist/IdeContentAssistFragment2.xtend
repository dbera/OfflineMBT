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
package nl.esi.xtext.lsp.generator.ide.contentassist

import com.google.inject.Inject
import java.util.List
import org.eclipse.xtext.AbstractRule
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.Grammar
import org.eclipse.xtext.xtext.generator.XtextGeneratorNaming
import org.eclipse.xtext.xtext.generator.model.FileAccessFactory
import org.eclipse.xtext.xtext.generator.model.GuiceModuleAccess
import org.eclipse.xtext.xtext.generator.model.TypeReference
import org.eclipse.xtext.xtext.generator.ui.contentAssist.ContentAssistFragment2

import static extension org.eclipse.xtext.GrammarUtil.*

class IdeContentAssistFragment2 extends ContentAssistFragment2 {
    @Inject
    extension XtextGeneratorNaming

    @Inject
    FileAccessFactory fileAccessFactory

    override protected getProposalProviderClass(Grammar g) {
        return new TypeReference(
            g.genericIdeBasePackage + ".contentassist." + g.simpleName + "IdeProposalProvider"
        )
    }

    override protected getGenProposalProviderClass(Grammar g) {
        return new TypeReference(
            g.genericIdeBasePackage + ".contentassist.Abstract" + g.simpleName + "IdeProposalProvider"
        )
    }

    override protected getGenProposalProviderSuperClass(Grammar g) {
        val superGrammar = g.usedGrammars.head
        if(inheritImplementation && superGrammar !== null && superGrammar.name != 'org.eclipse.xtext.common.Terminals') {
            superGrammar.proposalProviderClass
        } else {
            getDefaultGenProposalProviderSuperClass
        }
    }

    override protected getDefaultGenProposalProviderSuperClass() {
        new TypeReference("org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider")
    }

    override generate() {
        if (projectConfig.genericIde.manifest !== null) {
            projectConfig.genericIde.manifest.requiredBundles += "org.eclipse.xtext.ide"
            projectConfig.genericIde.manifest.requiredBundles += projectConfig.runtime.name + ';visibility:=reexport'
        }

        new GuiceModuleAccess.BindingFactory()
                .addTypeToType(
                    new TypeReference("org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider"),
                    grammar.getProposalProviderClass
                ).contributeTo(language.ideGenModule);

        if (projectConfig.genericIde.srcGen !== null) {
            // generate the 'Abstract...IdeProposalProvider'
            generateGenJavaProposalProvider
        }

        if (isGenerateStub && projectConfig.genericIde.src !== null) {
            if (generateXtendStub) {
                generateXtendProposalProviderStub

                if (projectConfig.eclipsePlugin.manifest !== null) {
                    projectConfig.eclipsePlugin.manifest.requiredBundles += 'org.eclipse.xtext.xbase.lib;bundle-version="'+projectConfig.runtime.xbaseLibVersionLowerBound+'"'
                    projectConfig.eclipsePlugin.manifest.requiredBundles += 'org.eclipse.xtend.lib;resolution:=optional'
                }
            } else {
                generateJavaProposalProviderStub
            }
        }

        if (projectConfig.genericIde.manifest !== null) {
            projectConfig.genericIde.manifest.exportedPackages += grammar.proposalProviderClass.packageName
        }

        // Creating UI delegation bindings to IDE
        if (projectConfig.eclipsePlugin.manifest !== null) {
            projectConfig.eclipsePlugin.manifest.requiredBundles += "org.eclipse.xtext.ui"
            projectConfig.eclipsePlugin.manifest.requiredBundles += projectConfig.runtime.name + ';visibility:=reexport'
            projectConfig.eclipsePlugin.manifest.requiredBundles += projectConfig.genericIde.name
        }

        new GuiceModuleAccess.BindingFactory()
                .addTypeToType(
                    new TypeReference("org.eclipse.xtext.ui.editor.contentassist.IContentProposalProvider"),
                    new TypeReference("org.eclipse.xtext.ui.editor.contentassist.UiToIdeContentProposalProvider")
                ).contributeTo(language.eclipsePluginGenModule);

        // The UI module does not include the bindings of the IDE module, so add these as well
        new GuiceModuleAccess.BindingFactory()
                .addTypeToType(
                    new TypeReference("org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider"),
                    grammar.getProposalProviderClass
                ).contributeTo(language.eclipsePluginGenModule);

    }

    override generateXtendProposalProviderStub() {
        fileAccessFactory.createXtendFile(grammar.proposalProviderClass, '''
            /**
             * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#content-assist
             * on how to customize the content assistant.
             */
            class «grammar.proposalProviderClass.simpleName» extends «grammar.genProposalProviderClass» {
            }
        ''').writeTo(projectConfig.genericIde.src)
    }

    override protected generateJavaProposalProviderStub() {
        fileAccessFactory.createJavaFile(grammar.proposalProviderClass, '''
            /**
             * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#content-assist
             * on how to customize the content assistant.
             */
            public class «grammar.proposalProviderClass.simpleName» extends «grammar.genProposalProviderClass» {
            }
        ''').writeTo(projectConfig.genericIde.src)
    }

    override protected generateGenJavaProposalProvider(List<Assignment> assignments, List<AbstractRule> rules, TypeReference genClass, TypeReference superClass) {
        fileAccessFactory.createGeneratedJavaFile(genClass) => [

            typeComment = '''
                /**
                 * Represents a generated, default implementation of superclass {@link «superClass»}.
                 */
            '''

            content = '''
                public «IF isGenerateStub»abstract «ENDIF»class «genClass.simpleName» extends «superClass» {
                    // Placeholder for abstract implementation
                }
            '''
            writeTo(projectConfig.genericIde.srcGen)
        ]
    }
}