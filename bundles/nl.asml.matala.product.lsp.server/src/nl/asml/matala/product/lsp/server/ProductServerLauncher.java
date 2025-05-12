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
package nl.asml.matala.product.lsp.server;

import static nl.esi.xtext.lsp.server.WebSocketServerLauncher.PORT;

import java.util.List;

import com.google.common.collect.Lists;

import nl.esi.xtext.lsp.server.ServerLauncher;

public class ProductServerLauncher extends ServerLauncher {
	public static final String SOCKET = "-socket";

	public static void main(String[] args) {
		// Web-sockets on port 9090 are the default for this server
		List<String> largs = Lists.newArrayList(args);
		if (!largs.contains(SOCKET) && !largs.contains(STDIO)) {
			if (!largs.contains(WEB_SOCKET)) {
				largs.add(WEB_SOCKET);
			}
			if (!largs.contains(PORT)) {
				largs.add(PORT);
				largs.add("9090");
			}
		}
		new ProductServerLauncher().launch(largs.toArray(new String[largs.size()]));
	}
}
