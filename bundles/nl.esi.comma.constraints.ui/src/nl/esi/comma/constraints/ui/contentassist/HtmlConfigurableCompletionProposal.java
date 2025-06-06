/*
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
package nl.esi.comma.constraints.ui.contentassist;

import org.eclipse.jface.internal.text.html.BrowserInformationControl;
import org.eclipse.jface.resource.JFaceResources;
import org.eclipse.jface.text.AbstractReusableInformationControlCreator;
import org.eclipse.jface.text.IInformationControl;
import org.eclipse.jface.text.IInformationControlCreator;
import org.eclipse.jface.text.contentassist.IContextInformation;
import org.eclipse.jface.viewers.StyledString;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal;

@SuppressWarnings("restriction")
public class HtmlConfigurableCompletionProposal extends ConfigurableCompletionProposal {

	public HtmlConfigurableCompletionProposal(String proposal, int replacementOffset, int replacementLength, int length,
			Image image, StyledString displayString, IContextInformation contextInformation,
			String additionalProposalInfo) {
		super(proposal, replacementOffset, replacementLength, length, image, displayString, contextInformation,
				additionalProposalInfo);
	}

	@Override
	public IInformationControlCreator getInformationControlCreator() {
		return new AbstractReusableInformationControlCreator() {
			public IInformationControl doCreateInformationControl(Shell parent) {
				// this method implicitly initializes variable fgScrollBarSize
				BrowserInformationControl.isAvailable(parent);

				return new BrowserInformationControl(parent, JFaceResources.DIALOG_FONT, true);
			}
		};
	}
}
