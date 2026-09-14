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

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.inject.Injector;

import io.vertx.core.Vertx;
import io.vertx.core.http.HttpServer;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.BodyHandler;
import nl.asml.matala.server.api.FileContent;
import nl.asml.matala.server.api.FileServerApi;
import nl.asml.matala.server.api.FileServerApi.DirectoryListing;
import nl.asml.matala.server.api.FileServerApi.FileResult;
import nl.asml.matala.server.api.FileWriteResult;
import nl.asml.matala.server.api.GeneratorApi;
import nl.asml.matala.server.api.GeneratorApi.GenerationTarget;
import nl.asml.matala.server.api.ServerApiException;
import nl.asml.matala.server.api.TypesApi;
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
    private static final String FILES_ENDPOINT = "/files";
    private static final String BPMN_ENDPOINT = "/generate";
    private static final String TYPES_OUTLINE_ENDPOINT = "/types/outline";
    private static final int DEFAULT_PORT = 2112;

    private final Vertx vertx;
    private final int port;
    private final Path tempPath;
    
    private HttpServer httpServer;
    private final GeneratorApi generatorApi;
    private final FileServerApi fileServerApi;
	private final TypesApi typesApi;

    /**
     * Create a new REST server with a custom repository path.
     *
     * @param port the port to listen on
     * @param repositoryPath the root directory for file operations
     */
    public RestServer(int port, String modelPath, String tempPath, Injector injector) {
        this.port = port > 0 ? port : DEFAULT_PORT;
        this.fileServerApi = injector.getInstance(FileServerApi.class);
        if(this.fileServerApi instanceof FileServerApiImpl fileServerApiImpl) {
			fileServerApiImpl.init(modelPath);
		}
        this.generatorApi = injector.getInstance(GeneratorApi.class);
        this.typesApi = injector.getInstance(TypesApi.class);
        this.tempPath = Path.of(tempPath);
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
        router.post(FILES_ENDPOINT).handler(BodyHandler.create());
        router.put(FILES_ENDPOINT).handler(BodyHandler.create());

        // File operation routes
        router.get(FILES_ENDPOINT).handler(this::handleFilesGet);
        router.post(FILES_ENDPOINT).handler(this::handleFilesPost);
        router.put(FILES_ENDPOINT).handler(this::handleFilesPut);

		// Handle processing of project files
        if (generatorApi != null) {
			router.post(BPMN_ENDPOINT).handler(this::handleGeneratePost);
		}
        
        if (typesApi != null) {
        	router.post(TYPES_OUTLINE_ENDPOINT).handler(BodyHandler.create());
			router.post(TYPES_OUTLINE_ENDPOINT).handler(this::handleTypesOutline);
        }

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

    private void handleFilesGet(RoutingContext ctx) {
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
            LOG.error("Error handling GET {}: {}", FILES_ENDPOINT, e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
    }

    private void handleFilesPost(RoutingContext ctx) {
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
            LOG.error("Error handling POST {}: {}", FILES_ENDPOINT, e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
    }

    private void handleFilesPut(RoutingContext ctx) {
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
            LOG.error("Error handling PUT {}: {}", FILES_ENDPOINT, e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
    }
    
	private void handleGeneratePost(RoutingContext ctx) {
        try {
            String path = ctx.request().getParam("path");
            if (path == null || path.isEmpty()) {
                sendError(ctx, 400, "path parameter is required");
                return;
            }
            String taskName = ctx.request().getParam("taskName");
            if (taskName == null || taskName.isEmpty()) {
                sendError(ctx, 400, "taskName parameter is required");
                return;
            }
            String outputPath = ctx.request().getParam("outputPath");
            if (outputPath == null || outputPath.isEmpty()) {
                sendError(ctx, 400, "outputPath parameter is required");
                return;
            }
            
            var absOutputPath = this.tempPath.resolve(outputPath);

            String target = ctx.request().getParam("target");
            if (target == null || target.isEmpty()) {
                sendError(ctx, 400, "target parameter is required");
                return;
            }
            GenerationTarget targetEnum;
			try {
				targetEnum = GenerationTarget.valueOf(target.toUpperCase());
			} catch (Exception e) {
                sendError(ctx, 400, "target parameter must be one of " + String.join(",", Arrays.stream( GenerationTarget.values()).map(Object::toString).toList()));
                return;
			}

            byte[] content = ctx.body().buffer().getBytes();
            FileWriteResult result = generatorApi.generate(absOutputPath, path, content, taskName, targetEnum );
            sendWriteResult(ctx, 201, result);
        } catch (ServerApiException e) {
            sendError(ctx, e.statusCode, e.getMessage());
        } catch (Exception e) {
            LOG.error("Error handling POST {}: {}", FILES_ENDPOINT, e.getMessage(), e);
            sendError(ctx, 500, "Internal server error");
        }
	}

	private void handleTypesOutline(RoutingContext ctx) {
        String typeName = ctx.request().getParam("typeName");
        try {
        	var types = new String(ctx.body().buffer().getBytes(), StandardCharsets.UTF_8);
        	var result = typesApi.getOutline(types, typeName);
        	sendJson(ctx, 200, result);
        } catch (ServerApiException e) {
            sendError(ctx, e.statusCode, e.getMessage());
		} catch (Exception e) {
			LOG.error("Error handling POST {}: {}", TYPES_OUTLINE_ENDPOINT, e.getMessage(), e);
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