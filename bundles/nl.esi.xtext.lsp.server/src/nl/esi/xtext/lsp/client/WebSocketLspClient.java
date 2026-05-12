/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package nl.esi.xtext.lsp.client;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import nl.esi.xtext.lsp.impl.WebSocketLspConnection;

public class WebSocketLspClient extends WebSocketClient {
	private static final Logger LOG = LoggerFactory.getLogger(WebSocketLspClient.class);

	private WebSocketLspConnection connection;

	public WebSocketLspClient(URI serverUri) {
		super(serverUri);
	}

	public InputStream getInputStream() {
		return connection == null ? null : connection.getInputStream();
	}

	public OutputStream getOutputStream() {
		return connection == null ? null : connection.getOutputStream();
	}

	@Override
	public void onOpen(ServerHandshake handshake) {
		LOG.info("The language client is connected: {}", handshake);
		try {
			this.connection = WebSocketLspConnection.wrap(this);
		} catch (IOException e) {
			LOG.error("Error in language client.", e);
		}
	}

	@Override
	public void onMessage(String message) {
		try {
			connection.onMessage(message);
		} catch (IOException | NullPointerException e) {
			LOG.error("Error in language client.", e);
		}
	}

	@Override
	public void onError(Exception exception) {
		LOG.error("Error in language client.", exception);
	}

	@Override
	public void onClose(int code, String reason, boolean remote) {
		if (remote) {
			LOG.info("Language client closed by server. {}", reason);
		} else {
			LOG.info("Close language client. {}", reason);
			try {
				connection.close();
			} catch (IOException | NullPointerException e) {
				LOG.error("Error in language client.", e);
			}
		}
	}
}
