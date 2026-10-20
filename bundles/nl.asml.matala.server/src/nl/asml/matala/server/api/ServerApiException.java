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

/** Exception carrying an HTTP status code. */
public class ServerApiException extends Exception {
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