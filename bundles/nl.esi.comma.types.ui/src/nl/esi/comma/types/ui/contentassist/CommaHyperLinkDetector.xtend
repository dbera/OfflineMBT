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
package nl.esi.comma.types.ui.contentassist

import com.google.inject.Inject
import com.google.inject.Provider
import nl.esi.xtext.common.lang.base.Import
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.jface.text.IRegion
import org.eclipse.jface.text.ITextViewer
import org.eclipse.jface.text.Region
import org.eclipse.jface.text.hyperlink.IHyperlink
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.nodemodel.ILeafNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.ui.editor.hyperlinking.DefaultHyperlinkDetector
import org.eclipse.xtext.ui.editor.hyperlinking.XtextHyperlink
import org.eclipse.xtext.ui.editor.model.IXtextDocument
import org.eclipse.xtext.util.concurrent.IUnitOfWork

class CommaHyperLinkDetector extends DefaultHyperlinkDetector {

	@Inject Provider<XtextHyperlink> hyperlinkProvider;

	override IHyperlink[] detectHyperlinks(ITextViewer textViewer, IRegion region, boolean canShowMultipleHyperlinks) { 
		val hyperlinks = super.detectHyperlinks(textViewer, region, canShowMultipleHyperlinks);
		if (hyperlinks === null) {
			return createHyperLinks(textViewer, region);
		}
		return hyperlinks;
	} 

	def IHyperlink[] createHyperLinks(ITextViewer textViewer, IRegion region) {		
		(textViewer.document as IXtextDocument).priorityReadOnly(new IUnitOfWork<IHyperlink[], XtextResource>() {
						
			override IHyperlink[] exec(XtextResource resource) throws Exception {
				val parseResult = resource.getParseResult();
				
				val leaf = NodeModelUtils.findLeafNodeAtOffset(parseResult.getRootNode(), region.getOffset());
				if (leaf !== null) {
					if (leaf.getSemanticElement() instanceof Import && leaf.getGrammarElement() instanceof RuleCall) {	
						val res = EcoreUtil2.getResource(resource, (leaf.getSemanticElement() as Import).importURI)
						return createHyperLinksFor(res as XtextResource, leaf, res.getContents().get(0));
					}
				}
				return null;
			}
		})

	}

	def createHyperLinksFor(XtextResource from, ILeafNode sourceNode, EObject target) {
		val uriConverter = from.getResourceSet().getURIConverter();		
		val uri = EcoreUtil.getURI(target);
		val normalized = if (uri.isPlatformResource()) uri else uriConverter.normalize(uri);
		
		val textRegion = sourceNode.getTextRegion();
		val region = new Region(textRegion.getOffset(), textRegion.getLength());

		val hyperLink = hyperlinkProvider.get();
		hyperLink.setHyperlinkRegion(region);
		hyperLink.setURI(normalized);
		hyperLink.setHyperlinkText("Open editor");
		if (hyperLink !== null) #[hyperLink] else #[]
	}

}
