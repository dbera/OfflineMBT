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
package nl.asml.matala.server.impl;

import java.io.ByteArrayInputStream;
import java.io.IOException;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.resource.XtextResourceSet;

import nl.asml.matala.server.api.ServerApiException;
import nl.asml.matala.server.api.TypesApi;
import nl.asml.matala.server.types.outline.TypesOutlineGenerator;
import nl.esi.xtext.common.lang.utilities.EcoreUtil3;
import nl.esi.xtext.common.lang.utilities.EcoreUtil3.ValidationException;
import nl.esi.xtext.types.types.TypesModel;

/**
 *  Concrete implementation of the TypesApi interface for handling types-related operations.
 * 
 */
public class TypesApiImpl implements TypesApi {

	@Override
	public String getOutline(String types, String typeName) throws ServerApiException {
		try {
			var resourceSet = new XtextResourceSet();
			var resource = resourceSet.createResource(URI.createURI("inmemory.types"));
			resource.load(new ByteArrayInputStream(types.getBytes()), null);
			EcoreUtil3.validate(resource); //load and resolve cross references
			var typesModel = resource.getContents().stream().filter(TypesModel.class::isInstance)
					.map(TypesModel.class::cast).findFirst()
					.orElseThrow(() -> new ServerApiException(500, "No types model found"));
			return TypesOutlineGenerator.toJson(TypesOutlineGenerator.getOutline(typesModel, typeName));
			
		} catch (IOException e) {
			throw new ServerApiException(500, "Failed to parse types: " + e.getMessage());
		} catch (ValidationException e) {
			throw new ServerApiException(501, "Validation error: " + e.getMessage());
		}
	}
}