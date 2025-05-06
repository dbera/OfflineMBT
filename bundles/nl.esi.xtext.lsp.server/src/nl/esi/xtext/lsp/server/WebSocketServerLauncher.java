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
package nl.esi.xtext.lsp.server;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetSocketAddress;
import java.util.Objects;
import java.util.function.Function;

import org.eclipse.lsp4j.jsonrpc.Launcher;
import org.eclipse.lsp4j.jsonrpc.MessageConsumer;
import org.eclipse.lsp4j.jsonrpc.messages.Message;
import org.eclipse.lsp4j.services.LanguageClient;
import org.eclipse.xtext.ide.server.LanguageServerImpl;
import org.eclipse.xtext.ide.server.ServerModule;
import org.eclipse.xtext.xbase.lib.ArrayExtensions;
import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.inject.Guice;
import com.google.inject.Injector;

import nl.esi.xtext.lsp.impl.WebSocketLspConnection;

public class WebSocketServerLauncher {
	private static final Logger LOG = LoggerFactory.getLogger(WebSocketServerLauncher.class);

	public static final String HOST = "-host";

	public static final String PORT = "-port";

	public static final String TRACE = "-trace";

	public static final String NO_VALIDATE = "-noValidate";

	public static final int DEFAULT_PORT = 8080;

	public static final String DEFAULT_HOST = "0.0.0.0";

	public static void main(String[] args) {
		new WebSocketServerLauncher().launch(args);
	}

	public void launch(String[] args) {
		Injector injector = Guice.createInjector(getServerModule());

		WebSocketServer server = new WebSocketServer(getSocketAddress(args)) {
			@Override
			public void onStart() {
				LOG.info("Started server socket at {}", getSocketAddress(args));
			}

			@Override
			public void onOpen(WebSocket conn, ClientHandshake handshake) {
				try {
					WebSocketLspConnection connection = WebSocketLspConnection.wrap(conn);

					LanguageServerImpl languageServer = injector.getInstance(LanguageServerImpl.class);
					Launcher.Builder<LanguageClient> launcherBuilder = new Launcher.Builder<LanguageClient>()
							.setLocalService(languageServer)
							.setRemoteInterface(LanguageClient.class)
							.setInput(connection.getInputStream())
							.setOutput(connection.getOutputStream());
					Launcher<LanguageClient> launcher = configureLauncher(launcherBuilder, args).create();
					languageServer.connect(launcher.getRemoteProxy());
					launcher.startListening();
					LOG.info("Started Xtext Language Server for client {}", conn.getRemoteSocketAddress());
				} catch (IOException e) {
					LOG.error("Failed to start Xtext Language Server for client {}: {}", conn.getRemoteSocketAddress(),
							e.getLocalizedMessage(), e);
					conn.close();
				}
			}

			@Override
			public void onMessage(WebSocket conn, String message) {
				try {
					WebSocketLspConnection.wrap(conn).onMessage(message);
				} catch (IOException e) {
					LOG.error("Error in Xtext Language Server for client {} ", conn.getRemoteSocketAddress(), e);
					conn.close();
				}
			}

			@Override
			public void onError(WebSocket conn, Exception exception) {
				LOG.error("Error in Xtext Language Server for client {}: {}", conn.getRemoteSocketAddress(),
						exception.getLocalizedMessage(), exception);
				try {
					WebSocketLspConnection.wrap(conn).close();
				} catch (IOException e) {
					LOG.error("Failed to stop Xtext Language Server for client {}: {}", conn.getRemoteSocketAddress(),
							e.getLocalizedMessage(), e);
				}
			}

			@Override
			public void onClose(WebSocket conn, int code, String reason, boolean remote) {
				if (remote) {
					LOG.info("Xtext Language Server closed by client {}", conn.getRemoteSocketAddress());
				} else {
					LOG.info("Close Xtext Language Server for client {}: {}", conn.getRemoteSocketAddress(), reason);
				}
				try {
					WebSocketLspConnection.wrap(conn).close();
				} catch (IOException e) {
					LOG.error("Failed to stop Xtext Language Server for client {}: {}", conn.getRemoteSocketAddress(),
							e.getLocalizedMessage(), e);
				}
			}
		};
		server.start();
	}

	protected com.google.inject.Module getServerModule() {
		return new ServerModule();
	}

	protected Launcher.Builder<LanguageClient> configureLauncher(Launcher.Builder<LanguageClient> builder, String... args) {
		PrintWriter trace = getTrace(args);
		boolean validate = shouldValidate(args);
		return builder.traceMessages(trace).validateMessages(validate).wrapMessages(null);
	}
	
	/**
	 * Creates a message intercepter wrapper for
	 * {@link Launcher.Builder#wrapMessages(Function)}.
	 * 
	 * @param intercepter the message intercepter
	 * @return a message intercepter wrapper
	 * @see #configureLauncher(org.eclipse.lsp4j.jsonrpc.Launcher.Builder,
	 *      String...)
	 */
	protected final Function<MessageConsumer, MessageConsumer> messageIntercepter(
			Function<Message, Message> intercepter) {
		return cons -> {
			return message -> cons.consume(intercepter.apply(message));
		};
	}

	protected PrintWriter getTrace(String... args) {
		if (ArrayExtensions.contains(args, TRACE)) {
			return new PrintWriter(System.out);
		}
		return null;
	}

	protected boolean shouldValidate(String... args) {
		return !ArrayExtensions.contains(args, NO_VALIDATE);
	}

	protected InetSocketAddress getSocketAddress(String... args) {
		return new InetSocketAddress(getHost(args), getPort(args));
	}

	protected String getHost(String... args) {
		String host = getValue(args, HOST);
		if (host != null) {
			return host;
		} else {
			return DEFAULT_HOST;
		}
	}

	protected int getPort(String... args) {
		String value = getValue(args, PORT);
		if (value != null) {
			try {
				return Integer.parseInt(value);
			} catch (NumberFormatException e) {
				return DEFAULT_PORT;
			}
		}
		return DEFAULT_PORT;
	}

	protected String getValue(String[] args, String argName) {
		for (int i = 0; (i < (args.length - 1)); i++) {
			if (Objects.equals(args[i], argName)) {
				return args[i + 1];
			}
		}
		return null;
	}
}
