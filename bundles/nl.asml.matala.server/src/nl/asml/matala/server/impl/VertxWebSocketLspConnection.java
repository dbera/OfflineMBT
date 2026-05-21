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

import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicBoolean;

import io.vertx.core.http.ServerWebSocket;

/**
 * Bridges a Vert.x {@link ServerWebSocket} to Xtext LSP4j's stream-based API.
 *
 * <p>Architecture:
 * <pre>
 *   Client → WebSocket → onMessage() → PipedOutputStream → PipedInputStream → LSP4j reader
 *   Client ← WebSocket ← writeTextMessage() ← flush() ← ByteArrayOutputStream ← LSP4j writer
 * </pre>
 *
 * <p>Uses a 64KB pipe buffer to minimize blocking when LSP messages are large.
 * Close-once semantics prevent double-close issues.
 */
public class VertxWebSocketLspConnection implements Closeable {

    private static final String SEPARATOR = "\r\n\r\n";
    private static final int PIPE_BUFFER_SIZE = 64 * 1024;

    private final PipedInputStream inputStream;
    private final PipedOutputStream localStream;
    private final OutputStream remoteStream;
    private final AtomicBoolean closed = new AtomicBoolean(false);

    /**
     * Create a new LSP connection wrapping the given WebSocket.
     *
     * @param webSocket the Vert.x WebSocket to wrap
     * @return a new connection (one per WebSocket — do not call multiple times)
     * @throws IOException if the piped streams cannot be created
     */
    public static VertxWebSocketLspConnection wrap(ServerWebSocket webSocket) throws IOException {
        return new VertxWebSocketLspConnection(webSocket);
    }

    private VertxWebSocketLspConnection(ServerWebSocket webSocket) throws IOException {
        this.inputStream = new PipedInputStream(PIPE_BUFFER_SIZE) {
            @Override
            public void close() throws IOException {
                try {
                    super.close();
                } finally {
                    closeWebSocket(webSocket);
                }
            }
        };
        this.localStream = new PipedOutputStream(inputStream);
        this.remoteStream = new ByteArrayOutputStream() {
            @Override
            public void flush() throws IOException {
                super.flush();
                if (closed.get()) return;

                byte[] data = toByteArray();
                reset();
                if (data.length == 0) return;

                String message = new String(data, StandardCharsets.UTF_8);
                int separatorIndex = message.indexOf(SEPARATOR);
                if (separatorIndex > 0) {
                    message = message.substring(separatorIndex + SEPARATOR.length());
                }
                webSocket.writeTextMessage(message);
            }

            @Override
            public void close() throws IOException {
                try {
                    super.close();
                } finally {
                    closeWebSocket(webSocket);
                }
            }
        };
    }

    /**
     * Feed an incoming WebSocket message into the LSP input pipe.
     * Prepends the required Content-Length header for the LSP protocol.
     *
     * <p><b>Warning:</b> This method may block if the pipe buffer is full.
     * Do not call from the Vert.x event loop — use {@code vertx.executeBlocking()}.
     *
     * @param message the raw JSON-RPC message from the client
     * @throws IOException if the pipe is broken (connection closed)
     */
    public void onMessage(String message) throws IOException {
        byte[] payload = message.getBytes(StandardCharsets.UTF_8);
        localStream.write(("Content-Length: " + payload.length + SEPARATOR).getBytes(StandardCharsets.UTF_8));
        localStream.write(payload);
        localStream.flush();
    }

    public InputStream getInputStream() {
        return inputStream;
    }

    public OutputStream getOutputStream() {
        return remoteStream;
    }

    /**
     * Close the connection. Safe to call multiple times.
     */
    @Override
    public void close() throws IOException {
        if (!closed.compareAndSet(false, true)) return;
        try {
            localStream.close();
        } finally {
            remoteStream.close();
        }
    }

    private static void closeWebSocket(ServerWebSocket ws) {
        if (!ws.isClosed()) {
            ws.close();
        }
    }
}