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
package nl.esi.comma.project.standard.cli.server;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

import org.w3c.dom.Document;

import nl.asml.matala.server.api.FileHandler;
import nl.asml.matala.server.api.ServerApiException;
import nl.esi.comma.project.standard.util.BpmnTypesUtil;

/**
 * FileHandler implementation for BPMN files with embedded types.
 * Delegates the actual splitting/merging logic to BpmnTypesUtil.
 * 
 * - Handles files with .bpmn extension (case-insensitive)
 * - On read: Looks for a corresponding .types file and injects its content into the BPMN
 * - On write: Extracts the types from BPMN and writes them to a .types file
 */
public class BpmnTypesSplitter implements FileHandler {

	@Override
	public boolean canHandle(Path path) {
		// Return true if the file has .bpmn extension (case-insensitive)
		return BpmnTypesUtil.isBpmnFile(path);
	}

	@Override
	public byte[] read(Path path) throws ServerApiException {
		try {
			// Read the BPMN file as XML
			byte[] bpmnContent = Files.readAllBytes(path);
			Document bpmnDoc = BpmnTypesUtil.parseXml(bpmnContent);

			// Look for corresponding .types file (takes precedence)
			Path typesPath = BpmnTypesUtil.getTypesPath(path);
			String typesContent = null;
			if (Files.exists(typesPath)) {
				typesContent = new String(Files.readAllBytes(typesPath), StandardCharsets.UTF_8);
				bpmnDoc = BpmnTypesUtil.injectTypesIntoBpmn(bpmnDoc, typesContent);
				return BpmnTypesUtil.xmlToBytes(bpmnDoc);
			}

			// Check if BPMN already contains types (backward compatibility)
			String existingTypes = BpmnTypesUtil.extractTypesFromBpmn(bpmnDoc);
			if (existingTypes != null) {
				// Types already exist in BPMN, return as-is
				return bpmnContent;
			}

			// No types file and no embedded types, inject placeholder
			String typesFileName = typesPath.getFileName().toString();
			typesContent = "/* \n" +
				"   " + typesFileName + " not found!\n" +
				"   Copy paste or edit types here \n" +
				"   then save the bpmn file.\n" +
				"*/\n";
			bpmnDoc = BpmnTypesUtil.injectTypesIntoBpmn(bpmnDoc, typesContent);

			return BpmnTypesUtil.xmlToBytes(bpmnDoc);
		} catch (ServerApiException e) {
			throw e;
		} catch (Exception e) {
			throw new ServerApiException(500, "Error reading BPMN file: " + e.getMessage(), e);
		}
	}

	@Override
	public void write(Path path, byte[] content) throws ServerApiException {
		try {
			// Parse the BPMN content
			Document bpmnDoc = BpmnTypesUtil.parseXml(content);

			// Extract types from raw element
			String typesContent = BpmnTypesUtil.extractTypesFromBpmn(bpmnDoc);

			// If types were found, write them to .types file
			if (typesContent != null && !typesContent.trim().isEmpty()) {
				Path typesPath = BpmnTypesUtil.getTypesPath(path);
				Files.write(typesPath, typesContent.getBytes(StandardCharsets.UTF_8),
						StandardOpenOption.CREATE, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING);

				// Remove types from BPMN
				bpmnDoc = BpmnTypesUtil.removeTypesFromBpmn(bpmnDoc);
			}

			// Write the BPMN back to file
			byte[] modifiedBpmn = BpmnTypesUtil.xmlToBytes(bpmnDoc);
			Files.write(path, modifiedBpmn,
					StandardOpenOption.CREATE, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING);
		} catch (ServerApiException e) {
			throw e;
		} catch (Exception e) {
			throw new ServerApiException(500, "Error writing BPMN file: " + e.getMessage(), e);
		}
	}

}