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

import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.core.runtime.jobs.Job;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.xtext.builder.EclipseOutputConfigurationProvider;
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2;
import org.eclipse.xtext.generator.IGenerator2;
import org.eclipse.xtext.ui.resource.IResourceSetProvider;
import org.eclipse.xtext.validation.IResourceValidator;

public class ProjectUIGeneratorJob extends Job {
	
	final private ProjectUIGenerator gen;

	public ProjectUIGeneratorJob(IFile file, IGenerator2 generator, EclipseResourceFileSystemAccess2 fileAccessProvider,
			IResourceSetProvider resourceSetProvider, EclipseOutputConfigurationProvider outputConfigurationProvider,
			IResourceValidator validator, Shell activeShell, LaunchShortcut launchShortcut, String mode) {
		super("Generate project");
		gen = new ProjectUIGenerator(file, generator, fileAccessProvider, resourceSetProvider, outputConfigurationProvider, validator, activeShell, launchShortcut, mode);		
	}

	@Override
	protected IStatus run(IProgressMonitor monitor) {
		List<String> errors = gen.runGeneration(monitor);

		if (!errors.isEmpty()) {
			String message = "";
			for (String e : errors) {
				message += e + System.lineSeparator();
			}
			return new Status(IStatus.ERROR, "nl.esi.comma.project.Project", message);
		}
		
		gen.launch();
		return new Status(IStatus.OK, "nl.esi.comma.project.Project", "");
	}

}
