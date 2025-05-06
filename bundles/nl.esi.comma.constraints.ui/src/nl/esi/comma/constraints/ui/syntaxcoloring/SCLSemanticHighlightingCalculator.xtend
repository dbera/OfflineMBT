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

import nl.esi.comma.constraints.constraints.ActSequenceDef
import nl.esi.comma.constraints.constraints.Composition
import nl.esi.comma.constraints.constraints.ConstraintsPackage
import nl.esi.comma.constraints.constraints.Ref
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.RefStep
import nl.esi.comma.constraints.constraints.StepSequenceDef
import nl.esi.comma.constraints.constraints.Templates
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.ide.editor.syntaxcoloring.DefaultSemanticHighlightingCalculator
import org.eclipse.xtext.ide.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.util.CancelIndicator

class SCLSemanticHighlightingCalculator extends DefaultSemanticHighlightingCalculator implements ISemanticHighlightingCalculator {
	val char c = '_'
	override provideHighlightingFor(XtextResource resource, IHighlightedPositionAcceptor acceptor, CancelIndicator cancelIndicator) {
		var rootObject = resource.getParseResult().getRootASTElement();
		
		//highlight step-seq/act-seq definitions
		for (actSeqDef : EcoreUtil2.getAllContentsOfType(rootObject, ActSequenceDef)) {
			for (node : NodeModelUtils.findNodesForFeature(actSeqDef, ConstraintsPackage.Literals.ACT_SEQUENCE_DEF__NAME)) {
				acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.ACT_SEQ_DEF);
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
			}
			var index = 0
			for (node : NodeModelUtils.findNodesForFeature(actSeqDef, ConstraintsPackage.Literals.ACT_SEQUENCE_DEF__ACT_LIST)) {
				var n = NodeModelUtils.findNodesForFeature(actSeqDef.actList.get(index), ConstraintsPackage.Literals.ACT__ACT).get(0)
				if (actSeqDef.actList.get(index).act.act.toString.equals("Observable")) {
					acceptor.addPosition(node.getOffset(), n.getLength(), SCLHighlightingConfiguration.OBSERVABLE);
				} else {
					acceptor.addPosition(node.getOffset(), n.getLength(), SCLHighlightingConfiguration.TRIGGER);
				}
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text.trim //TODO to be fix in grammar, why there is a space at front of the Act
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
				index++
			}
		}
		
		for (stepSeqDef : EcoreUtil2.getAllContentsOfType(rootObject, StepSequenceDef)) {
			for (node : NodeModelUtils.findNodesForFeature(stepSeqDef, ConstraintsPackage.Literals.STEP_SEQUENCE_DEF__NAME)) {
				acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.STEP_SEQ_DEF);
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
			}
			var index = 0
			for (node : NodeModelUtils.findNodesForFeature(stepSeqDef, ConstraintsPackage.Literals.STEP_SEQUENCE_DEF__STEP_LIST)) {
				if (stepSeqDef.stepList.get(index).act.toString.equals("Observable")) {
					acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.OBSERVABLE);
				} else {
					acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.TRIGGER);
				}
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
				index++
			}
		}
		//highlight all step/act/step-seq/act-seq references
		for (ref : EcoreUtil2.getAllContentsOfType(rootObject, Ref)) {
			for (node : NodeModelUtils.findNodesForFeature(ref, ConstraintsPackage.Literals.REF_STEP__STEP)) {
				if (ref instanceof RefStep) {
					if (ref.step.act.toString.equals("Observable")){
						acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.OBSERVABLE);
					} else {
						acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.TRIGGER);
					}
				}
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
			}
			for (node : NodeModelUtils.findNodesForFeature(ref, ConstraintsPackage.Literals.REF_ACTION__ACT)) {
				if (ref instanceof RefAction) {
					var n = NodeModelUtils.findNodesForFeature(ref.act, ConstraintsPackage.Literals.ACT__ACT).get(0)
					if (ref.act.act.act.toString.equals("Observable")){
						acceptor.addPosition(node.getOffset(), n.getLength(), SCLHighlightingConfiguration.OBSERVABLE);
					} else {
						acceptor.addPosition(node.getOffset(), n.getLength(), SCLHighlightingConfiguration.TRIGGER);
					}
				}
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text.trim //TODO to be fix in grammar, why there is a space at front in the action ref
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
			}
			for (node : NodeModelUtils.findNodesForFeature(ref, ConstraintsPackage.Literals.REF_ACT_SEQUENCE__SEQ)) {
				acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.ACT_SEQ_DEF);
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
			}
			for (node : NodeModelUtils.findNodesForFeature(ref, ConstraintsPackage.Literals.REF_STEP_SEQUENCE__SEQ)) {
				acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.STEP_SEQ_DEF);
				//Comment this part if the underscore coloring is slow
				if (node.text.contains('_')){
					var s = node.text
					for (var i = 0; i < s.length(); i++) {
						if (s.charAt(i).equals(c)){
							acceptor.addPosition(node.getOffset()+i, 1, SCLHighlightingConfiguration.UNDERSCORE);
						}
					}
				}
			}
		}
		//highlight constraint name
		for (constraint : EcoreUtil2.getAllContentsOfType(rootObject, Templates)){
			for (node : NodeModelUtils.findNodesForFeature(constraint, ConstraintsPackage.Literals.TEMPLATES__NAME)){
				acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.CONSTRAINT_REF);
			}
		}
		//highlight constraint ref in Composition
		for (composition : EcoreUtil2.getAllContentsOfType(rootObject, Composition)){
			for (node : NodeModelUtils.findNodesForFeature(composition, ConstraintsPackage.Literals.COMPOSITION__TEMPLATES)){
				acceptor.addPosition(node.getOffset(), node.getLength(), SCLHighlightingConfiguration.CONSTRAINT_REF);
			}
		}
		super.provideHighlightingFor(resource, acceptor, cancelIndicator)
	}
}