package nl.asml.matala.product.lsp.editor;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URI;
import java.util.concurrent.TimeUnit;

import org.eclipse.lsp4e.server.StreamConnectionProvider;

import nl.esi.xtext.lsp.client.WebSocketLspClient;

public class ProductStreamConnectionProvider implements StreamConnectionProvider {
	private WebSocketLspClient lspClient;

	@Override
	public void start() throws IOException {
		try {
			lspClient = new WebSocketLspClient(URI.create("ws://localhost:5008"));
			if (!lspClient.connectBlocking(60, TimeUnit.SECONDS)) {
				lspClient = null;
				throw new IOException("Failed to connect within a reasonable time.");
			}
		} catch (InterruptedException e) {
			throw new IOException("Failed to connect within a reasonable time.", e);
		}
	}

	@Override
	public InputStream getInputStream() {
		return lspClient == null ? null : lspClient.getInputStream();
	}

	@Override
	public OutputStream getOutputStream() {
		return lspClient == null ? null : lspClient.getOutputStream();
	}

	@Override
	public InputStream getErrorStream() {
		return null;
	}

	@Override
	public void stop() {
		if (lspClient != null) {
			lspClient.close();
			lspClient = null;
		}
	}
}
