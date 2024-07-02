/*
 * Copyright (c) 2021 Contributors to the Eclipse Foundation
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.comma.project.standard.ui.handler;

import java.util.logging.Logger;

import org.eclipse.core.resources.IFile;
import org.eclipse.debug.ui.ILaunchShortcut;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IFileEditorInput;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.PlatformUI;
import org.eclipse.xtext.builder.EclipseOutputConfigurationProvider;
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2;
import org.eclipse.xtext.generator.IGenerator2;
import org.eclipse.xtext.ui.resource.IResourceSetProvider;
import org.eclipse.xtext.validation.IResourceValidator;

import com.google.inject.Inject;
import com.google.inject.Provider;



class LaunchShortcut implements ILaunchShortcut {
	private static final Logger LOGGER = Logger.getLogger(LaunchShortcut.class.getName());

	@Inject
	private IGenerator2 generator;

	@Inject
	private Provider<EclipseResourceFileSystemAccess2> fileAccessProvider;

	@Inject
	private IResourceSetProvider resourceSetProvider;

	@Inject
	public void setOutputConfigurationProvider(EclipseOutputConfigurationProvider outputConfigurationProvider) {
		this.outputConfigurationProvider = outputConfigurationProvider;
	}
	private EclipseOutputConfigurationProvider outputConfigurationProvider;

	@Inject
	private IResourceValidator validator;
	
	@Override
	public void launch(ISelection selection, String mode) {
		LOGGER.info("launching from selection: " + selection + " in mode: " + mode);
		IStructuredSelection sel = (IStructuredSelection) selection;
		for (Object file : sel.toArray()) {
			IFile f = (IFile) file;
			generateThenLaunch(f, mode);
		}
	}

	@Override
	public void launch(IEditorPart editor, String mode) {
		LOGGER.info("launching from editor: " + editor.getTitle() + " in mode: " + mode);
		generateThenLaunch(((IFileEditorInput) editor.getEditorInput()).getFile(), mode);
	}

	private void generateThenLaunch(IFile projectFile, String mode) {
		IWorkbenchWindow workbench = PlatformUI.getWorkbench().getActiveWorkbenchWindow();
		var job = new ProjectUIGeneratorJob(projectFile, generator, fileAccessProvider.get(), resourceSetProvider,
				outputConfigurationProvider, validator, workbench.getShell(), this, mode);
		job.schedule();
	}
}