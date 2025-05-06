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
package nl.esi.comma.project.standard.ui.handler;

import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.net.URL;
import java.text.MessageFormat;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.operation.IRunnableWithProgress;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.ui.progress.IProgressService;

abstract public class AbstractTemplateHandler extends AbstractHandler {

	private static final String INFO_EXISTS_MESSAGE = "Template was not created since \"{0}\" already exists.";
	private static final String INFO_EXISTS_TITLE = "Template already exists";
	private static final String ERROR_MESSAGE = "Error while importing template.";

	private String templateLocation;
	private String templateOutput;

	public AbstractTemplateHandler(String templateLocation, String templateOutput) {
		this.templateLocation = templateLocation;
		this.templateOutput = templateOutput;
	}

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		ISelection selection = HandlerUtil.getCurrentSelection(event);

		if (selection != null & selection instanceof IStructuredSelection) {
			IStructuredSelection structuredSelection = (IStructuredSelection) selection;
			Object firstElement = structuredSelection.getFirstElement();
			if (firstElement instanceof IFile) {
				IFile file = (IFile) firstElement;
				IProject project = file.getProject();
				IFile template = project.getFile(templateOutput);
				if (!template.exists()) {
					IWorkbench wb = PlatformUI.getWorkbench();
					IProgressService ps = wb.getProgressService();
					try {
						ps.busyCursorWhile(new IRunnableWithProgress() {
							@Override
							public void run(IProgressMonitor pm) throws InvocationTargetException {
								try {
									URL url = new URL(templateLocation);
									InputStream inputStream = url.openConnection().getInputStream();
									template.create(inputStream, false, pm);
								} catch (Exception e) {
									Logger.getGlobal().log(Level.SEVERE, ERROR_MESSAGE, e.getCause());
								}
							}
						});
					} catch (InvocationTargetException e) {
						Logger.getGlobal().log(Level.SEVERE, ERROR_MESSAGE, e.getCause());
					} catch (InterruptedException e) {
						Thread.currentThread().interrupt();
					}
				} else {
					MessageDialog.openInformation(HandlerUtil.getActiveShell(event), INFO_EXISTS_TITLE,
							MessageFormat.format(INFO_EXISTS_MESSAGE, templateOutput));
				}
			}
		}
		return null;
	}
}
