
package nl.esi.comma.causalgraph.ui.handlers;

import static org.eclipse.lsat.common.queries.QueryableIterable.from;

import java.io.IOException;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.e4.core.di.annotations.CanExecute;
import org.eclipse.e4.core.di.annotations.Evaluate;
import org.eclipse.e4.core.di.annotations.Execute;
import org.eclipse.e4.core.di.annotations.Optional;
import org.eclipse.e4.ui.services.IServiceConstants;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.lsat.common.emf.common.util.URIHelper;
import org.eclipse.lsat.common.emf.ecore.resource.Persistor;
import org.eclipse.lsat.common.emf.ecore.resource.PersistorFactory;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.dialogs.SaveAsDialog;

import jakarta.inject.Named;
import nl.esi.comma.causalgraph.causalGraph.CausalGraph;
import nl.esi.comma.causalgraph.transform.Rcg2UcgTransformer;

public class Rcg2UcgHandler {
	@Evaluate
	@CanExecute
	public boolean canExecute(@Optional @Named(IServiceConstants.ACTIVE_SELECTION) IStructuredSelection selection) {
		if (selection == null || selection.size() < 2) {
			return false;
		}
		return from((Iterable<?>) selection).forAll(e -> e instanceof IFile f && "cg".equals(f.getFileExtension()));
	}

	@Execute
	public void execute(@Named(IServiceConstants.ACTIVE_SELECTION) IStructuredSelection selection,
			@Named(IServiceConstants.ACTIVE_SHELL) Shell shell) {
		List<IFile> selectedFiles = from((Iterable<?>) selection).objectsOfKind(IFile.class).asList();

		SaveAsDialog saveAsDialog = new SaveAsDialog(shell);
		if (saveAsDialog.open() != SaveAsDialog.OK) {
			return;
		}
		IPath saveIPath = saveAsDialog.getResult();
		if (!"cg".equals(saveIPath.getFileExtension())) {
			saveIPath = saveIPath.addFileExtension("cg");
		}
		IFile saveIFile = ResourcesPlugin.getWorkspace().getRoot().getFile(saveIPath);

		try {
			mergeRcs2Ucs(selectedFiles, saveIFile);
		} catch (Exception e) {
			MessageDialog.openError(shell, "Merge failed", e.getLocalizedMessage());
		}
	}

	public static void mergeRcs2Ucs(List<IFile> inputs, IFile output) throws IOException, CoreException {
		Persistor<CausalGraph> persistor = new PersistorFactory().getPersistor(CausalGraph.class);
		CausalGraph[] rcgs = new CausalGraph[inputs.size()];
		for (int i = 0; i < inputs.size(); i++) {
			rcgs[i] = persistor.loadOne(URIHelper.asURI(inputs.get(i)));
		}

		CausalGraph ucg = new Rcg2UcgTransformer().merge(rcgs);
		persistor.save(URIHelper.asURI(output), ucg);
		output.refreshLocal(IResource.DEPTH_ZERO, null);
	}
}