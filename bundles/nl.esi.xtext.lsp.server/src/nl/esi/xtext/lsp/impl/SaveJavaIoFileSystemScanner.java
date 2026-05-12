/*
 * Copyright (c) 2024, 2026 TNO-ESI
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 */
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
