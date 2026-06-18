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
package nl.asml.matala.server;

import static nl.esi.xtext.lsp.server.WebSocketServerLauncher.PORT;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import nl.asml.matala.server.rest.RestServer;
import nl.asml.matala.server.rest.RestServer.ServerStartupException;

/**
 * Launches both:
 * <ul>
 *   <li>REST file server (Vert.x) on the configured REST port (default 2112)</li>
 *   <li>LSP WebSocket server (Java-WebSocket via Xtext) on the configured LSP port (default 9090)</li>
 * </ul>
 *
 * <p>This avoids bridging LSP4j's blocking stream API into Vert.x's event loop.
 * Each server runs in its natural threading model with zero impedance mismatch.
 */
public class ServerLauncher extends nl.esi.xtext.lsp.server.ServerLauncher {
    private static final Logger LOG = LoggerFactory.getLogger(ServerLauncher.class);

    private static final String REST_PORT = "--rest-port";
	private static final String LSP_PORT = "--lsp-port";
	private static final String REPOSITORY_PATH = "--repository-path";
	private static final int DEFAULT_REST_PORT = 9091;
    private static final int DEFAULT_LSP_PORT = 9092;
    private static final String DEFAULT_REPOSITORY_PATH = "models";

    public static void main(String[] args) {
        var launcher = new ServerLauncher();

        // Start REST file server (Vert.x — non-blocking)
        int restPort = getArgValue(args, REST_PORT, DEFAULT_REST_PORT);
        String repositoryPath = getArgString(args, REPOSITORY_PATH, DEFAULT_REPOSITORY_PATH);
        var restServer = new RestServer(restPort, repositoryPath);

        try {
            LOG.info("Starting REST file server on port {}", restPort);
            restServer.start();
            LOG.info("REST file server started successfully");
        } catch (ServerStartupException e) {
            LOG.error("Failed to start REST file server: {}", e.getMessage(), e);
            restServer.stop();
            System.exit(1);
        }

        // Register shutdown hook to clean up REST server on exit
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            LOG.info("Shutting down servers...");
            try {
                restServer.stop();
                LOG.info("REST file server stopped");
            } catch (Exception e) {
                LOG.warn("Error stopping REST server: {}", e.getMessage(), e);
            }
        }, "ServerShutdownHook"));

        // Start LSP WebSocket server (Java-WebSocket — blocking, Xtext-native)
        int lspPort = getArgValue(args, LSP_PORT, DEFAULT_LSP_PORT);
        LOG.info("Starting LSP WebSocket server on port {}", lspPort);
        launcher.launch(new String[]{WEB_SOCKET, PORT, String.valueOf(lspPort)});
    }

    private static int getArgValue(String[] args, String flag, int defaultValue) {
        for (int i = 0; i < args.length - 1; i++) {
            if (flag.equals(args[i])) {
                try {
                    return Integer.parseInt(args[i + 1]);
                } catch (NumberFormatException e) {
                    return defaultValue;
                }
            }
        }
        return defaultValue;
    }

    private static String getArgString(String[] args, String flag, String defaultValue) {
        for (int i = 0; i < args.length - 1; i++) {
            if (flag.equals(args[i])) {
                return args[i + 1];
            }
        }
        return defaultValue;
    }
}