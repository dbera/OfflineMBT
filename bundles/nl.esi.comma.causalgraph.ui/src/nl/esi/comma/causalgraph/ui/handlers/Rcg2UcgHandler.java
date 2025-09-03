
package nl.esi.comma.causalgraph.ui.handlers;

import static nl.esi.comma.causalgraph.utilities.CausalGraphQueries.getGraphType;
import static org.eclipse.lsat.common.queries.IterableQueries.product;
import static org.eclipse.lsat.common.queries.QueryableIterable.from;
import static org.eclipse.lsat.common.util.IteratorUtil.map;
import static org.eclipse.lsat.common.util.IteratorUtil.min;

import java.util.List;
import java.util.function.Function;

import org.apache.commons.lang3.tuple.Pair;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.ResourcesPlugin;
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
import org.eclipse.lsat.common.util.IterableUtil;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.dialogs.SaveAsDialog;

import jakarta.inject.Named;
import nl.esi.comma.causalgraph.causalGraph.CausalGraph;
import nl.esi.comma.causalgraph.causalGraph.GraphType;
import nl.esi.comma.causalgraph.transform.Rcg2BddUcgTransformer;

public class Rcg2UcgHandler {
	private static final GraphType OUTPUT_GRAPH_TYPE = GraphType.BDDUCG;
	
	@Evaluate
	@CanExecute
	public boolean canExecute(@Optional @Named(IServiceConstants.ACTIVE_SELECTION) IStructuredSelection selection) {
		if (selection == null || selection.size() < 2) {
			return false;
		}
		return from((Iterable<?>) selection)
				.forAll(e -> e instanceof IFile f && GraphType.RCG.equals(getGraphType(f.getFileExtension())));
	}

	@Execute
	public void execute(@Named(IServiceConstants.ACTIVE_SELECTION) IStructuredSelection selection,
			@Named(IServiceConstants.ACTIVE_SHELL) Shell shell) {
		List<IFile> selectedFiles = from((Iterable<?>) selection).objectsOfKind(IFile.class).asList();
		try {
			Persistor<CausalGraph> persistor = new PersistorFactory().getPersistor(CausalGraph.class);
			String mergedGraphName = "";
			CausalGraph[] rcgs = new CausalGraph[selectedFiles.size()];
			for (int i = 0; i < selectedFiles.size(); i++) {
				rcgs[i] = persistor.loadOne(URIHelper.asURI(selectedFiles.get(i)));
				if (i > 0) {
					mergedGraphName += "__";
				}
				mergedGraphName += rcgs[i].getName();
			}

			SaveAsDialog saveAsDialog = new SaveAsDialog(shell);
			IPath commonPath = getCommonPath(selectedFiles);
			if (commonPath != null) {
				saveAsDialog.setOriginalFile(ResourcesPlugin.getWorkspace().getRoot()
						.getFile(commonPath.append(mergedGraphName).addFileExtension(OUTPUT_GRAPH_TYPE.getName())));
			} else {
				saveAsDialog.setOriginalName(mergedGraphName);
			}
			if (saveAsDialog.open() != SaveAsDialog.OK) {
				return;
			}
			IPath saveIPath = saveAsDialog.getResult();
			if (!OUTPUT_GRAPH_TYPE.equals(getGraphType(saveIPath.getFileExtension()))) {
				saveIPath = saveIPath.addFileExtension(OUTPUT_GRAPH_TYPE.getName());
			}
			IFile saveIFile = ResourcesPlugin.getWorkspace().getRoot().getFile(saveIPath);

			CausalGraph saveGraph = new Rcg2BddUcgTransformer().merge(rcgs);
			persistor.save(URIHelper.asURI(saveIFile), saveGraph);
			saveIFile.refreshLocal(IResource.DEPTH_ZERO, null);
		} catch (Exception e) {
			e.printStackTrace();
			MessageDialog.openError(shell, "Merge failed", e.getLocalizedMessage());
		}
	}

	private static IPath getCommonPath(Iterable<IFile> files) {
		Function<Pair<IFile, IFile>, Integer> matcher = pair -> pair.getKey().getFullPath()
				.matchingFirstSegments(pair.getValue().getFullPath());
		Integer matchingFirstSegments = min(map(product(files, files).iterator(), matcher), 0);
		return matchingFirstSegments > 0 ? IterableUtil.first(files).getFullPath().uptoSegment(matchingFirstSegments)
				: null;
	}
}