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
package nl.esi.comma.expressions.functions;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.impl.URIHandlerImpl;

import nl.esi.comma.expressions.generator.LibraryToExprGenerator;

/**
 * Singleton registry that holds generated {@code .expr} function declarations
 * for Java library classes as in-memory resources.
 *
 * <p>When {@link #addLibrary(Class)} is called, it uses
 * {@link LibraryToExprGenerator} to generate the {@code .expr} content for the
 * given library class and stores it under a synthetic URI of the form:
 * <pre>
 *   inmemory:/expr/&lt;fully.qualified.ClassName&gt;.expr
 * </pre>
 *
 * <p>The registered URIs are consumed by
 * {@link nl.esi.comma.expressions.scoping.ExpressionsImportUriGlobalScopeProvider}
 * so that every Xtext resource set automatically sees the function declarations
 * without the developer having to add an explicit {@code import} statement.
 *
 * <p>A custom {@link URIHandler} is provided via {@link #getURIHandler()} so
 * that Xtext's {@code ResourceSet} can load these in-memory URIs without any
 * file-system access.
 */
public final class InMemoryExprResourceRegistry {

    /** Scheme used for all in-memory expr URIs. */
    public static final String SCHEME = "inmemory";

    /** Path prefix used for all in-memory expr URIs. */
    private static final String PATH_PREFIX = "/expr/";

    private final Map<URI, String> registry = new LinkedHashMap<>();

    private final URIHandlerImpl uriHandler = new InMemoryURIHandler(this);

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Generates the {@code .expr} content for all public static methods of
     * {@code libraryClass} and stores it under a synthetic in-memory URI.
     *
     * <p>Calling this method multiple times with the same class is idempotent.
     *
     * @param libraryClass the Java class to register
     * @return the URI under which the content was registered
     */
 	public URI addLibrary(Class<?> libraryClass) {
        URI uri = uriFor(libraryClass);
        registry.computeIfAbsent(uri, k -> LibraryToExprGenerator.generate(libraryClass));
        return uri;
    }

    /**
     * Returns an unmodifiable view of all registered in-memory URIs.
     *
     * @return set of URIs (insertion order preserved)
     */
	public Set<URI> getRegisteredURIs() {
        return Collections.unmodifiableSet(registry.keySet());
    }

    /**
     * Returns the generated {@code .expr} content for the given URI, or
     * {@code null} if the URI is not registered.
     *
     * @param uri the in-memory URI
     * @return the expr content string, or {@code null}
     */
	public String getContent(URI uri) {
        return registry.get(uri);
    }

    /**
     * Returns {@code true} if the given URI is handled by this registry.
     *
     * @param uri the URI to check
     * @return {@code true} if the URI scheme is {@value #SCHEME}
     */
	public boolean handles(URI uri) {
        return SCHEME.equals(uri.scheme());
    }

    /**
     * Returns the shared {@link URIHandler} that delegates reads for
     * {@value #SCHEME} URIs to this registry. Register it in a
     * {@code ResourceSet} via:
     * <pre>{@code
     *   resourceSet.getURIConverter().getURIHandlers().add(0, registry.getURIHandler());
     * }</pre>
     *
     * @return a URI handler backed by this registry
     */
	public URIHandlerImpl getURIHandler() {
        return uriHandler;
    }

    // -------------------------------------------------------------------------
    // URI helpers
    // -------------------------------------------------------------------------

    /**
     * Returns the canonical in-memory URI for a library class.
     *
     * @param libraryClass the library class
     * @return the URI, e.g. {@code inmemory:/expr/com.example.MyFunctions.expr}
     */
    public static URI uriFor(Class<?> libraryClass) {
        return URI.createURI(SCHEME + ":" + PATH_PREFIX + libraryClass.getName() + ".expr");
    }

    // -------------------------------------------------------------------------
    // Inner URIHandler
    // -------------------------------------------------------------------------

    /**
     * Xtext {@link URIHandler} that serves in-memory expr content from the
     * registry as an {@link InputStream}.
     */
    public static final class InMemoryURIHandler extends URIHandlerImpl {

        private final InMemoryExprResourceRegistry owner;

        InMemoryURIHandler(InMemoryExprResourceRegistry owner) {
            this.owner = owner;
        }

        @Override
        public boolean canHandle(URI uri) {
            return owner.handles(uri);
        }

        @Override
        public InputStream createInputStream(URI uri, Map<?, ?> options) throws IOException {
            String content = owner.getContent(uri);
            if (content == null) {
                throw new IOException("No in-memory expr resource registered for URI: " + uri);
            }
            return new ByteArrayInputStream(content.getBytes(StandardCharsets.UTF_8));
        }

        @Override
        public OutputStream createOutputStream(URI uri, Map<?, ?> options) throws IOException {
            throw new UnsupportedOperationException("In-memory expr resources are read-only");
        }

        @Override
        public boolean exists(URI uri, Map<?, ?> options) {
            return owner.handles(uri) && owner.getContent(uri) != null;
        }

        @Override
        public Map<String, ?> getAttributes(URI uri, Map<?, ?> options) {
            return Collections.emptyMap();
        }
    }
}
