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

import static com.google.common.collect.Maps.uniqueIndex;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.OperationCanceledException;
import org.eclipse.core.runtime.SubMonitor;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.operation.IRunnableWithProgress;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.xtext.builder.EclipseOutputConfigurationProvider;
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2;
import org.eclipse.xtext.diagnostics.Severity;
import org.eclipse.xtext.generator.IGenerator2;
import org.eclipse.xtext.generator.OutputConfiguration;
import org.eclipse.xtext.ui.resource.IResourceSetProvider;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;

import com.google.common.base.Function;

import nl.esi.comma.project.standard.generator.StandardProjectGenerator;

/**
 * CommaSuite Project Generator class used by UI implementations. (i.e.
 * {@link LaunchShortcut and @link GenerationHandler})
 * 
 */
public class ProjectUIGenerator implements IRunnableWithProgress {
	
	protected static final String ERROR_RESOURCE_TITLE = "CommaSuite workflow terminated";

	protected static final String ERROR_RESOURCE_TEXT = "The CommaSuite workflow was terminated because the file %s still contains errors.";

	protected final IFile file;
	protected final IProject project;
	protected final Shell shell;
	protected final IGenerator2 generator;
	protected final EclipseResourceFileSystemAccess2 fsa;
	protected final IResourceSetProvider resourceSetProvider;
	protected final EclipseOutputConfigurationProvider outputConfigurationProvider;
	protected final IResourceValidator validator;
	
	final private LaunchShortcut launch;
	final String mode;
	
	public ProjectUIGenerator(IFile file, IGenerator2 generator, EclipseResourceFileSystemAccess2 fileAccessProvider,
			IResourceSetProvider resourceSetProvider, EclipseOutputConfigurationProvider outputConfigurationProvider, IResourceValidator validator,
			Shell activeShell, LaunchShortcut launchShortcut, String mode) {		
		this.file = file;
		this.project = file.getProject();
		this.shell = activeShell;

		this.outputConfigurationProvider = outputConfigurationProvider;
		this.generator = generator;
		this.fsa = fileAccessProvider;
		this.resourceSetProvider = resourceSetProvider;
		this.validator = validator;
		
		this.mode = mode;
		this.launch = launchShortcut;
	}

	public void launch() {
		Display.getDefault().syncExec(new Runnable() {
			public void run() {
			}
		});
	}

	@Override
	public void run(IProgressMonitor monitor) {
		runGeneration(monitor);
		monitor.done();
		
	}
	
	public List<String> runGeneration(IProgressMonitor monitor) {
		SubMonitor subMonitor = SubMonitor.convert(monitor, 3);
		Map<String, OutputConfiguration> outputConfigurations = getOutputConfigurations(file.getProject());
		final List<String> errors = new ArrayList<>();
		
		try {
		
			URI uri = URI.createPlatformResourceURI(file.getFullPath().toString(), true);
			Resource res = resourceSetProvider.get(project).getResource(uri, true);			
			
			if(containsErrors(res, subMonitor)) {				
				MessageDialog.openError(shell, ERROR_RESOURCE_TITLE , String.format(ERROR_RESOURCE_TEXT, res.getURI().lastSegment()));
				return errors;
			}

			fsa.setProject(project);
			fsa.setMonitor(subMonitor);
			fsa.setOutputConfigurations(outputConfigurations);
			
			if (subMonitor.isCanceled()) {
				throw new OperationCanceledException();
			}
			
			var generator = (StandardProjectGenerator) this.generator;
			generator.doGenerate(res, fsa, null);

		} catch (Exception e) {
			errors.add(this.getClass().getSimpleName() + e.getMessage() + e.getStackTrace());
		}
		return errors;
	}

	private boolean containsErrors(Resource resource, IProgressMonitor monitor) {
		monitor.beginTask("Validating", 1);
		List<Issue> issues = validator.validate(resource, CheckMode.ALL, getCancelIndicator(monitor));		
		for(Issue issue : issues) {
			if(issue.getSeverity().equals(Severity.ERROR)) {
				return true;
			}
		}
		return false;
	}

	protected Map<String, OutputConfiguration> getOutputConfigurations(IProject project) {
		Set<OutputConfiguration> configurations = outputConfigurationProvider.getOutputConfigurations(project);
		return uniqueIndex(configurations, new Function<OutputConfiguration, String>() {
			@Override
			public String apply(OutputConfiguration from) {
				return from.getName();
			}
		});
		
	}
	
	protected CancelIndicator getCancelIndicator(final IProgressMonitor monitor) {
		return new CancelIndicator() {
			@Override
			public boolean isCanceled() {
				return monitor.isCanceled();
			}
		};
	}
}
