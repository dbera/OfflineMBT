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
package nl.esi.comma.project.standard.cli;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.xtext.resource.IResourceServiceProvider.Registry;
import org.eclipse.xtext.resource.ResourceServiceProviderServiceLoader;

import com.google.inject.Provider;
import com.google.inject.Provides;

import nl.asml.matala.server.api.FileHandler;
import nl.asml.matala.server.api.FileServerApi;
import nl.asml.matala.server.api.GeneratorApi;
import nl.asml.matala.server.api.TypesApi;
import nl.asml.matala.server.impl.StandardFileHandler;
import nl.asml.matala.server.impl.FileServerApiImpl;
import nl.asml.matala.server.impl.TypesApiImpl;
import nl.esi.comma.project.standard.StandardProjectRuntimeModule;
import nl.esi.comma.project.standard.cli.server.BpmnTypesSplitter;
import nl.esi.comma.project.standard.cli.server.GeneratorApiImpl;
import nl.esi.comma.project.standard.generator.extension.IStandardProjectGeneratorExtension;
import nl.esi.comma.project.standard.generator.extension.StandardProjectGeneratorExtensionServiceLoader;

class StandardProjectCliModule extends StandardProjectRuntimeModule {
	@Override
	public Registry bindIResourceServiceProvider$Registry() {
		// Enabling discovery of languages via service provider API
		return new ResourceServiceProviderServiceLoader().get();
	}

	public Class<? extends Provider<? extends IStandardProjectGeneratorExtension.Registry>> provideIStandardProjectGeneratorExtension$Registry() {
		return StandardProjectGeneratorExtensionServiceLoader.class;
	}
	
	public Class<? extends GeneratorApi> bindGeneratorApi() {
		return GeneratorApiImpl.class;
	}
	
	public Class<? extends FileServerApi> bindFileServerApi() {
		return FileServerApiImpl.class;
	}
	
	@Provides
	public List<FileHandler> provideFileHandlers() {
		// Returns list with BPMN types splitter handler
		// Note: Order matters. The first handler that can handle a file will be used.
		// StandardFileHandler should be last as it can handle any file.
		List<FileHandler> handlers = new ArrayList<>();
		handlers.add(new BpmnTypesSplitter());
		handlers.add(new StandardFileHandler());
		return handlers;
	}


	public Class<? extends TypesApi> bindTypesApi() {
		return TypesApiImpl.class;
	}

}