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
		try {
			gen.runGeneration(monitor);
		} catch (Exception e) {
			e.printStackTrace();
			return new Status(IStatus.ERROR, "nl.esi.comma.project.Project", e.getLocalizedMessage(), e);
		}
		return Status.OK_STATUS;
	}
}
