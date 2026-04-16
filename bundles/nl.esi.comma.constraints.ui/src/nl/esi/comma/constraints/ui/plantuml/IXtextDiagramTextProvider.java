package nl.esi.comma.constraints.ui.plantuml;

import java.util.Collection;
import java.util.Collections;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.jface.text.TextSelection;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.ui.IEditorPart;
import org.eclipse.xtext.nodemodel.ILeafNode;
import org.eclipse.xtext.nodemodel.util.NodeModelUtils;
import org.eclipse.xtext.ui.editor.XtextEditor;
import org.eclipse.xtext.ui.editor.model.IXtextDocument;

import net.sourceforge.plantuml.eclipse.utils.DiagramTextProvider;

public interface IXtextDiagramTextProvider extends DiagramTextProvider {
	@Override
	default boolean supportsSelection(ISelection selection) {
		return selection instanceof StructuredSelection || selection instanceof TextSelection;
	}
	
	@Override
	default boolean supportsEditor(IEditorPart editorPart) {
		return editorPart instanceof XtextEditor;
	}
	
	@Override
	default String getDiagramText(IEditorPart editorPart, ISelection selection) {
		if (editorPart instanceof XtextEditor xtextEditor && selection instanceof TextSelection textSelection) {
			IXtextDocument document = xtextEditor.getDocument();
			if (document == null) {
				return null;
			}
			int offset = textSelection.getOffset();
			EObject semanticObject = document.readOnly(resource -> {
				ILeafNode node = NodeModelUtils.findLeafNodeAtOffset(resource.getParseResult().getRootNode(), offset);
				if (node != null) {
					return NodeModelUtils.findActualSemanticObjectFor(node);
				}
				return null;
			});
			if (semanticObject != null) {
				return getDiagramText(Collections.singleton(semanticObject));
			}
		}
		return null;
	}
	
	String getDiagramText(Collection<EObject> selection);
}
