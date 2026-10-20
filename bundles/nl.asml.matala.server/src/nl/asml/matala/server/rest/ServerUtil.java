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
package nl.asml.matala.server.rest;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import nl.asml.matala.server.api.FileServerApi;
import nl.asml.matala.server.api.ServerApiException;

/**
 * File-system-backed implementation of {@link FileServerApi}.
 * All paths are validated to stay within the configured root directory.
 */
public class ServerUtil {
    /**
     * Validates and normalizes a relative path against the root.
     * <ol>
     *   <li>Rejects absolute paths</li>
     *   <li>Resolves against rootPath and normalizes</li>
     *   <li>Ensures result stays within rootPath</li>
     * </ol>
     * @param bPMNServerApiImpl
     *
     * @param relativePath client-supplied relative path
     * @return validated absolute path
     * @throws ServerApiException if the path is invalid or escapes the root
     */
    public static Path validateAndNormalize(Path rootPath, String relativePath) throws ServerApiException {
        if (Path.of(relativePath).isAbsolute()) {
            throw new ServerApiException(403, "Absolute paths are not allowed");
        }

        Path resolved = rootPath.resolve(relativePath).normalize();

        if (!resolved.startsWith(rootPath)) {
            throw new ServerApiException(403, "Path escapes root folder");
        }
        return resolved;
    }

    public static String getMimeType(Path path) {
        try {
            String mimeType = Files.probeContentType(path);
            return mimeType != null ? mimeType : "application/octet-stream";
        } catch (IOException e) {
            return "application/octet-stream";
        }
    }
}