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
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import io.vertx.core.Vertx;
import io.vertx.core.http.HttpServer;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.BodyHandler;
import nl.asml.matala.server.api.FileServerApi;
import nl.asml.matala.server.api.FileServerApi.DirectoryListing;
import nl.asml.matala.server.api.FileServerApi.FileContent;
import nl.asml.matala.server.api.FileServerApi.FileResult;
import nl.asml.matala.server.api.FileServerApi.FileWriteResult;
import nl.asml.matala.server.api.FileServerApi.ServerApiException;
import nl.asml.matala.server.impl.FileServerApiImpl;

/**
 * Vert.x-based REST Server for file operations.
 *
 * <p>Provides HTTP endpoints for:
 * <ul>
 *   <li>GET /files - List directory or read file</li>
 *   <li>POST /files - Create/overwrite file</li>
 *   <li>PUT /files - Update existing file</li>
 * </ul>
 *
 * <p>LSP communication is handled separately by the existing
 * {@code WebSocketServerLauncher} on its own port — no bridging needed.
 *
 * <p>No authentication or authorization is required.
 * Path traversal attacks are prevented by validating paths cannot escape the root folder.
 */
public class RestServer {

    private static final Logger LOG = LoggerFactory.getLogger(RestServer.class);
    private static final String ROOT_PATH = System.getProperty("repository.path", "./models");
    private static final int DEFAULT_PORT = 2112;

    private final Vertx vertx;
    private final int port;
    private final FileServerApi fileServerApi;
    private HttpServer httpServer;

    /**
     * Create a new REST server with default configuration.
     *
     * @param port the port to listen on
     */
    public RestServer(int port) {
        this(port, new FileServerApiImpl(ROOT_PATH));
    }

    /**
     * Create a new REST server with a custom repository path.
     *
     * @param port the port to listen on
     * @param repositoryPath the root directory for file operations
     */
    public RestServer(int port, String repositoryPath) {
        this(port, new FileServerApiImpl(repositoryPath));
    }

    /**
     * Create a new REST server with custom file API.
     *
     * @param port the port to listen on
     * @param fileServerApi the file operations implementation
     */
    public RestServer(int port, FileServerApi fileServerApi) {
        this.port = port > 0 ? port : DEFAULT_PORT;
        this.fileServerApi = fileServerApi;
        this.vertx = Vertx.vertx();
    }

    /**
     * Start the REST server and register all endpoints.
     * This method blocks until the server is listening or startup fails.
     *
     * @throws ServerStartupException if the server fails to start within the timeout period
     */
    public void start() throws ServerStartupException {
        CompletableFuture<Void> startupFuture = new CompletableFuture<>();
        Router router = Router.router(vertx);

        // Body handler for POST/PUT
        router.post("/files").handler(BodyHandler.create());
        router.put("/files").handler(BodyHandler.create());

        // File operation routes
        router.get("/files").handler(this::handleGet);
        router.post("/files").handler(this::handlePost);
        router.put("/files").handler(this::handlePut);

        httpServer = vertx.createHttpServer();
        httpServer.requestHandler(router).listen(port, result -> {
            if (result.succeeded()) {
                LOG.info("REST Server started on port {}", port);
                startupFuture.complete(null);
            } else {
                String message = "Failed to start REST Server on port " + port + ": " + result.cause().getMessage();
                LOG.error(message, result.cause());
                startupFuture.completeExceptionally(result.cause());
            }
        });

        // Wait for server to start (5 second timeout)
        try {
            startupFuture.get(5, TimeUnit.SECONDS);
        } catch (Exception e) {
            stop(); // Clean up on failure
            throw new ServerStartupException("REST Server failed to start within timeout period", e);
        }
    }

    /**
     * Stop the REST server and release resources.
     */
    public void stop() {
        if (httpServer != null) {
            httpServer.close();
        }
        if (vertx != null) {
            vertx.close();
        }
    }

    // ---- HTTP Handlers ----

    private void handleGet(RoutingContext ctx) {
        try {
            String path = ctx.request().getParam("path");
            String extension = ctx.request().getParam("extension");

            if (path == null || path.isEmpty()) {
                path = ".";
            }

            FileResult result = fileServerApi.listOrReadFiles(path, extension);

            switch (result) {
                case DirectoryListing listing -> {
                    var json = new JsonObject();
                    json.addProperty("path", listing.path());
                    json.add("folders", toJsonArray(listing.folders()));
                    json.add("files", toJsonArray(listing.files()));
                    sendJson(ctx, 200, json.toString());
                }
                case FileContent file -> {
                    ctx.response()
                        .putHeader("Content-Type", file.mimeType())
                        .end(io.vertx.core.buffer.Buffer.buffer(file.content()));
                }
            }
        } catch (ServerApiException e) {
            sendError(ctx, e.statusCode, e.getMessage());
        } catch (Exception e) {
            LOG.error("Error handling GET /files: {}", e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
    }

    private void handlePost(RoutingContext ctx) {
        try {
            String path = ctx.request().getParam("path");
            if (path == null || path.isEmpty()) {
                sendError(ctx, 400, "path parameter is required");
                return;
            }

            byte[] content = ctx.body().buffer().getBytes();
            FileWriteResult result = fileServerApi.createFile(path, content);
            sendWriteResult(ctx, 201, result);
        } catch (ServerApiException e) {
            sendError(ctx, e.statusCode, e.getMessage());
        } catch (Exception e) {
            LOG.error("Error handling POST /files: {}", e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
    }

    private void handlePut(RoutingContext ctx) {
        try {
            String path = ctx.request().getParam("path");
            if (path == null || path.isEmpty()) {
                sendError(ctx, 400, "path parameter is required");
                return;
            }

            byte[] content = ctx.body().buffer().getBytes();
            FileWriteResult result = fileServerApi.updateFile(path, content);
            sendWriteResult(ctx, 200, result);
        } catch (ServerApiException e) {
            sendError(ctx, e.statusCode, e.getMessage());
        } catch (Exception e) {
            LOG.error("Error handling PUT /files: {}", e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
    }

    // ---- Response Helpers ----

    private void sendWriteResult(RoutingContext ctx, int statusCode, FileWriteResult result) {
        var json = new JsonObject();
        json.addProperty("path", result.path());
        json.addProperty("message", result.message());
        json.addProperty("success", result.success());
        sendJson(ctx, statusCode, json.toString());
    }

    private void sendJson(RoutingContext ctx, int statusCode, String json) {
        ctx.response()
            .setStatusCode(statusCode)
            .putHeader("Content-Type", "application/json")
            .end(json);
    }

    private void sendError(RoutingContext ctx, int statusCode, String message) {
        var json = new JsonObject();
        json.addProperty("error", message);
        sendJson(ctx, statusCode, json.toString());
    }

    private static JsonArray toJsonArray(List<String> items) {
        JsonArray array = new JsonArray();
        items.forEach(array::add);
        return array;
    }

    // ---- Entry Point ----

    public static void main(String[] args) throws IOException, ServerStartupException {
        int port = args.length > 0 ? Integer.parseInt(args[0]) : DEFAULT_PORT;
        RestServer server = new RestServer(port);
        server.start();
        Runtime.getRuntime().addShutdownHook(new Thread(server::stop));
    }

    /**
     * Exception thrown when the REST server fails to start.
     */
    public static class ServerStartupException extends Exception {
        /**
		 * 
		 */
		private static final long serialVersionUID = 1L;

		public ServerStartupException(String message) {
            super(message);
        }

        public ServerStartupException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}