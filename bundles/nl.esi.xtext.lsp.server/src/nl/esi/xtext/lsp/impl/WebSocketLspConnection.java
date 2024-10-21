package nl.esi.xtext.lsp.impl;

import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.nio.charset.StandardCharsets;

import org.java_websocket.WebSocket;

public class WebSocketLspConnection implements Closeable {
	
	private static final String SEPARATOR = "\r\n\r\n";

	private final PipedInputStream inputStream;
	private final PipedOutputStream localStream;
	private final OutputStream remoteStream;

	public static WebSocketLspConnection wrap(WebSocket webSocket) throws IOException {
		Object attachment = webSocket.getAttachment();
		if (attachment instanceof WebSocketLspConnection conn) {
			return conn;
		} else if (attachment != null) {
			new IOException("Web-socket cannot be wrapped as attachment is already set: " + attachment.getClass());
		}
		WebSocketLspConnection connection = new WebSocketLspConnection(webSocket);
		webSocket.setAttachment(connection);
		return connection;
	}

	private WebSocketLspConnection(WebSocket webSocket) throws IOException {
		this.inputStream = new PipedInputStream() {
			@Override
			public void close() throws IOException {
				try {
					super.close();
				} finally {
					if (webSocket.isOpen()) {
						webSocket.close();
					}
				}
			}
		};
		this.localStream = new PipedOutputStream(inputStream);
		this.remoteStream = new ByteArrayOutputStream() {
			@Override
			public void flush() throws IOException {
				super.flush();
				String message = new String(toByteArray(), StandardCharsets.UTF_8);
				reset();

				int separatorIndex = message.indexOf(SEPARATOR);
				if (separatorIndex > 0) {
					message = message.substring(separatorIndex + SEPARATOR.length());
				}
				webSocket.send(message);
			}

			@Override
			public void close() throws IOException {
				try {
					super.close();
				} finally {
					if (webSocket.isOpen()) {
						webSocket.close();
					}
				}
			}
		};
	}

	public void onMessage(String message) throws IOException {
		localStream.write(("Content-Length: " + message.length() + SEPARATOR).getBytes(StandardCharsets.UTF_8));
		localStream.write(message.getBytes(StandardCharsets.UTF_8));
		localStream.flush();
	}

	public InputStream getInputStream() {
		return inputStream;
	}

	public OutputStream getOutputStream() {
		return remoteStream;
	}

	@Override
	public void close() throws IOException {
		try {
			getOutputStream().close();
		} finally {
			getInputStream().close();
		}
	}
}