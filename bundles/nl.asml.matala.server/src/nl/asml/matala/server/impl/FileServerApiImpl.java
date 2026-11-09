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
import java.nio.file.*;
import java.util.ArrayList;
import java.util.List;

import nl.asml.matala.server.api.FileContent;
import nl.asml.matala.server.api.FileHandler;
import nl.asml.matala.server.api.FileServerApi;
import nl.asml.matala.server.api.FileWriteResult;
import nl.asml.matala.server.api.ServerApiException;

/**
 * File-system-backed implementation of {@link FileServerApi}.
 * All paths are validated to stay within the configured root directory.
 */
public class FileServerApiImpl implements FileServerApi {

    /** Root directory — all client paths are resolved relative to this. */
    private Path rootPath;

    /** Maximum file size to read (100 MB). Prevents DoS attacks via large file requests. */
    private static final long MAX_FILE_SIZE = 100 * 1024 * 1024; // 100 MB

	private final List<FileHandler> handlers = new ArrayList<>();


    @Override
    public void init(String rootPath, List<FileHandler> handlers) {
		this.handlers.addAll(handlers);
		this.rootPath = Path.of(rootPath).toAbsolutePath().normalize();
	}

    @Override
    public FileResult listOrReadFiles(String path, String extension) throws ServerApiException {
        var normalizedPath = validateAndNormalize(path);

        try {
            if (!Files.exists(normalizedPath)) {
                throw new ServerApiException(404, "Path not found");
            }

            if (Files.isRegularFile(normalizedPath)) {
                long fileSize = Files.size(normalizedPath);
                if (fileSize > MAX_FILE_SIZE) {
                    throw new ServerApiException(413, "File too large (max " + (MAX_FILE_SIZE / (1024 * 1024)) + " MB)");
                }
                
                // Find the first handler that can handle this path
                byte[] content = null;
                for (FileHandler handler : handlers) {
                    if (handler.canHandle(normalizedPath)) {
                        content = handler.read(normalizedPath);
                        break;
                    }
                }
                
                if (content == null) {
                    throw new ServerApiException(500, "No handler available to read file");
                }
                
                String mimeType = getMimeType(normalizedPath);
                return new FileContent(path, content, mimeType);
            }

            if (Files.isDirectory(normalizedPath)) {
                var folders = new ArrayList<String>();
                var files = new ArrayList<String>();

                try (var stream = Files.newDirectoryStream(normalizedPath)) {
                    for (Path entry : stream) {
                        String name = entry.getFileName().toString();
                        if (Files.isDirectory(entry)) {
                            folders.add(name);
                        } else if (extension == null || name.endsWith(extension)) {
                            files.add(name);
                        }
                    }
                }
                return new DirectoryListing(path, List.copyOf(folders), List.copyOf(files));
            }

            throw new ServerApiException(400, "Invalid path");
        } catch (IOException e) {
            throw new ServerApiException(500, "I/O error reading path", e);
        }
    }

    @Override
    public FileWriteResult createFile(String path, byte[] content) throws ServerApiException {
        var normalizedPath = validateAndNormalize(path);

        // Find the first handler that can handle this path
        FileHandler handler = null;
        for (FileHandler h : handlers) {
            if (h.canHandle(normalizedPath)) {
                handler = h;
                break;
            }
        }
        
        if (handler == null) {
            throw new ServerApiException(500, "No handler available to write file");
        }
        
        handler.write(normalizedPath, content);
        return new FileWriteResult(path, "File created successfully", true);
    }

    @Override
    public FileWriteResult updateFile(String path, byte[] content) throws ServerApiException {
        var normalizedPath = validateAndNormalize(path);

        if (!Files.isRegularFile(normalizedPath)) {
            throw new ServerApiException(404, "File not found");
        }

        // Find the first handler that can handle this path
        FileHandler handler = null;
        for (FileHandler h : handlers) {
            if (h.canHandle(normalizedPath)) {
                handler = h;
                break;
            }
        }
        
        if (handler == null) {
            throw new ServerApiException(500, "No handler available to write file");
        }
        
        handler.write(normalizedPath, content);
        return new FileWriteResult(path, "File updated successfully", true);
    }

    // ---- Internal Helpers ----

    /**
     * Validates and normalizes a relative path against the root.
     * <ol>
     *   <li>Rejects absolute paths</li>
     *   <li>Resolves against rootPath and normalizes</li>
     *   <li>Ensures result stays within rootPath</li>
     * </ol>
     *
     * @param relativePath client-supplied relative path
     * @return validated absolute path
     * @throws ServerApiException if the path is invalid or escapes the root
     */
    private Path validateAndNormalize(String relativePath) throws ServerApiException {
        if (Path.of(relativePath).isAbsolute()) {
            throw new ServerApiException(403, "Absolute paths are not allowed");
        }

        Path resolved = rootPath.resolve(relativePath).normalize();

        if (!resolved.startsWith(rootPath)) {
            throw new ServerApiException(403, "Path escapes root folder");
        }
        return resolved;
    }

    private static String getMimeType(Path path) {
        try {
            String mimeType = Files.probeContentType(path);
            return mimeType != null ? mimeType : "application/octet-stream";
        } catch (IOException e) {
            return "application/octet-stream";
        }
    }
}