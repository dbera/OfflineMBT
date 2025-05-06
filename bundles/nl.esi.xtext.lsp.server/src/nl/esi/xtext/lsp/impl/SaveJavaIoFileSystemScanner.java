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
