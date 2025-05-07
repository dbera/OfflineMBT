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

import org.eclipse.swt.SWT
import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor
import org.eclipse.xtext.ui.editor.utils.TextStyle

class SCLHighlightingConfiguration extends DefaultHighlightingConfiguration implements IHighlightingConfiguration {
	public static final String STEP_SEQ = "step-seq"
	public static final String ACT_SEQ = "act-seq"
	public static final String ACT = "act"
	public static final String STEP = "step"
	public static final String STEP_SEQ_DEF = "step-sequence-def"
	public static final String ACT_SEQ_DEF = "act-sequence-def"
	public static final String REF = "ref"
	public static final String TRIGGER = "ref-trigger"
	public static final String OBSERVABLE = "ref_observable"
	public static final String CONSTRAINT_REF = "constraint-ref"
	public static final String CONSTRAINT_ID = "constraint-id"
	public static final String UNDERSCORE = "underscore"
	
	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor)
		acceptor.acceptDefaultHighlighting(STEP_SEQ, "step-seq", greyTextStyle());
		acceptor.acceptDefaultHighlighting(ACT_SEQ, "act-seq", greyTextStyle());
		acceptor.acceptDefaultHighlighting(ACT, "act", greyTextStyle());
		acceptor.acceptDefaultHighlighting(STEP, "step", greyTextStyle());
		acceptor.acceptDefaultHighlighting(ACT_SEQ_DEF, "act-sequence-def", seqTextStyle())
		acceptor.acceptDefaultHighlighting(STEP_SEQ_DEF, "step-sequence-def", seqTextStyle())
		acceptor.acceptDefaultHighlighting(REF, "ref", seqTextStyle())
		acceptor.acceptDefaultHighlighting(TRIGGER, "ref_trigger", triggerRefTextStyle())
		acceptor.acceptDefaultHighlighting(OBSERVABLE, "ref_observable", observableRefTextStyle())
		acceptor.acceptDefaultHighlighting(CONSTRAINT_REF, "constraint-ref", constraintRefTextStyle())
		acceptor.acceptDefaultHighlighting(CONSTRAINT_ID, "constraint", constraintTextStyle())
		acceptor.acceptDefaultHighlighting(UNDERSCORE, "underscore", underscoreStyle())
	}
	
	def underscoreStyle() {
		var textStyle = new TextStyle
		textStyle.setColor(new RGB(255, 255, 255))
		return textStyle;
	}
	
	def greyTextStyle() {
		var textStyle = new TextStyle
		textStyle.setColor(new RGB(192, 192, 192))
		return textStyle;
	}
	
	def seqTextStyle() {
		var textStyle = new TextStyle
		textStyle.setColor(new RGB(10, 20, 214)) //0,0,139
		return textStyle;
	}
	
	def constraintRefTextStyle() {
		var textStyle = new TextStyle
		textStyle.setColor(new RGB(128, 0, 0))
		return textStyle
	}
	
	def triggerRefTextStyle() {
		var textStyle = new TextStyle
		textStyle.setColor(new RGB(255,69,0))
		return textStyle
	}
	
	def observableRefTextStyle() {
		var textStyle = new TextStyle
		textStyle.setColor(new RGB(34,139,34))
		return textStyle
	}
	
	def constraintTextStyle() {
		var textStyle = new TextStyle
		textStyle.style = SWT.BOLD
		textStyle.setColor(new RGB(30,144,255))
		return textStyle
	}
}