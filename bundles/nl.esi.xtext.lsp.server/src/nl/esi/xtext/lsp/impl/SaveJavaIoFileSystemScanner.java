package nl.esi.xtext.lsp.impl;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.util.IAcceptor;
import org.eclipse.xtext.util.IFileSystemScanner.JavaIoFileSystemScanner;

public class SaveJavaIoFileSystemScanner extends JavaIoFileSystemScanner {
	@Override
	public void scan(URI root, IAcceptor<URI> acceptor) {
		if (root.isFile()) {
			super.scan(root, acceptor);
		}
	}
}
