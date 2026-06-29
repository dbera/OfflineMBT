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

import java.util.List;

/**
 * FileServerApi interface for backend file operations.
 * 
 * <p>All paths are relative to the root folder and cannot escape it.
 * This interface is JSON-free; serialization is handled by the REST layer.
 */
public interface FileServerApi {

    /**
     * List files and folders in a directory, or read a file.
     *
     * @param path relative path within the root folder
     * @param extension optional file extension filter (e.g., ".bpmn")
     * @return {@link DirectoryListing} for directories or {@link FileContent} for files
     * @throws ServerApiException if the path is invalid or access is denied
     */
    FileResult listOrReadFiles(String path, String extension) throws ServerApiException;

    /**
     * Create or overwrite a file.
     *
     * @param path relative file path within the root folder
     * @param content file content to write
     * @return result containing the file path and status
     * @throws ServerApiException if the path is invalid or write fails
     */
    FileWriteResult createFile(String path, byte[] content) throws ServerApiException;

    /**
     * Update/replace an existing file.
     *
     * @param path relative file path within the root folder
     * @param content file content to write
     * @return result containing the file path and status
     * @throws ServerApiException if the file is not found or write fails
     */
    FileWriteResult updateFile(String path, byte[] content) throws ServerApiException;

    // ---- Result Types ----

    /** Sealed result type for {@link #listOrReadFiles}. */
    sealed interface FileResult permits DirectoryListing, FileContent {}

    /** Directory listing with folders and files relative to the listed path. */
    record DirectoryListing(String path, List<String> folders, List<String> files) implements FileResult {}

    /** File content with MIME type. */
    record FileContent(String path, byte[] content, String mimeType) implements FileResult {}

    /** Result of a file write operation. */
    record FileWriteResult(String path, String message, boolean success) {}

    /** Exception carrying an HTTP status code. */
    class ServerApiException extends Exception {
        private static final long serialVersionUID = 1L;
        public final int statusCode;

        public ServerApiException(int statusCode, String message) {
            super(message);
            this.statusCode = statusCode;
        }

        public ServerApiException(int statusCode, String message, Throwable cause) {
            super(message, cause);
            this.statusCode = statusCode;
        }
    }
}