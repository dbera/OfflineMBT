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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

import nl.asml.matala.server.api.FileHandler;
import nl.asml.matala.server.api.ServerApiException;

/**
 * File system implementation of {@link FileHandler}.
 * Provides simple read and write operations for files on the filesystem.
 * 
 * Note: This handler receives already-normalized paths from FileServerApi,
 * so no additional path validation is performed here.
 */
public class StandardFileHandler implements FileHandler {

	/** Maximum file size to read (100 MB). Prevents DoS attacks via large file requests. */
	private static final long MAX_FILE_SIZE = 100 * 1024 * 1024; // 100 MB

	@Override
	public boolean canHandle(Path path) {
		// Can handle any path (already validated by FileServerApi)
		return true;
	}

	@Override
	public byte[] read(Path path) throws ServerApiException {
		try {
			long fileSize = Files.size(path);
			if (fileSize > MAX_FILE_SIZE) {
				throw new ServerApiException(413,
						"File too large (max " + (MAX_FILE_SIZE / (1024 * 1024)) + " MB)");
			}

			return Files.readAllBytes(path);
		} catch (IOException e) {
			throw new ServerApiException(500, "I/O error reading file: " + path.getFileName(), e);
		}
	}

	@Override
	public void write(Path path, byte[] content) throws ServerApiException {
		try {
			Files.createDirectories(path.getParent());
			Files.write(path, content, StandardOpenOption.CREATE, StandardOpenOption.WRITE,
					StandardOpenOption.TRUNCATE_EXISTING);
		} catch (IOException e) {
			throw new ServerApiException(500, "I/O error writing file: " + path.getFileName(), e);
		}
	}
}
