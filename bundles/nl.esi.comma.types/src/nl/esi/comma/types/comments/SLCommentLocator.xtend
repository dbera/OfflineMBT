package nl.esi.comma.types.comments

import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.nodemodel.ICompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.TerminalRule
import org.eclipse.xtext.nodemodel.INode

class SLCommentLocator {
	
	def static String getSLComment(EObject obj){
		if(obj === null) return ""
		
		var ICompositeNode n = NodeModelUtils.getNode(obj)
		if(n === null) return ""
		
		var int endLine = n.endLine
		var next = getNextLeafNode(n)
		while(next !== null && endLine == next.startLine){
			var EObject gr = next.grammarElement
			if(gr instanceof TerminalRule ){
				if (gr.name.equals("SL_COMMENT")){
					return next.text.trim.substring(2)
				}
			}
			next = getNextLeafNode(next)
		}
		
		""
	}
	
	def static private getNextLeafNode(INode n){
		var next = n.nextSibling
		if(next !== null){
			if(next instanceof ICompositeNode){
				next = next.leafNodes.get(0)
			}
		}
		next
	}
}