/*
 * generated by Xtext 2.25.0
 */
package nl.esi.comma.behavior.scl.ui;

import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalCreator;

import nl.esi.comma.types.ide.contentassist.TypesIdeContentProposalCreator;

/**
 * Use this class to register components to be used within the Eclipse IDE.
 */
public class SclUiModule extends AbstractSclUiModule {

	public SclUiModule(AbstractUIPlugin plugin) {
		super(plugin);
	}

	public  Class<? extends IdeContentProposalCreator> bindIdeContentProposalCreator() {
        return TypesIdeContentProposalCreator.class;
    }
}
