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
package nl.asml.matala.server.api;

import java.nio.file.Path;

/**
 * FileHandler interface for reading and writing files.
 * 
 * <p>
 * Implementors can provide custom logic for handling specific file transformations. 
 * The FileServerApi will delegate file operations to the appropriate FileHandler 
 * based on canHandle.
 * 
 * The supplied paths are absolute paths.
 */
public interface FileHandler {

	boolean canHandle(Path path);

	/**
	 * Read the content of a file at the given path. A FileHandler may assume that
	 * the file exists and is readable.
	 */
	byte[] read(Path path) throws ServerApiException;

	void write(Path path, byte[] content) throws ServerApiException;

}