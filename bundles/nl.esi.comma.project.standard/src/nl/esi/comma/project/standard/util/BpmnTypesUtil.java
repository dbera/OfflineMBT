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
package nl.esi.comma.project.standard.util;

import java.io.IOException;
import java.nio.file.Path;
import java.util.NoSuchElementException;
import java.util.Optional;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 * Standalone utility for splitting and merging BPMN and types definitions.
 * This class has no dependencies on FileHandler or ServerApiException,
 * making it suitable for use in projects that don't have those dependencies.
 */
public class BpmnTypesUtil {

	private static final String BPMN_EXTENSION = ".bpmn";
	private static final String TYPES_EXTENSION = ".types";
	private static final String BPMN4S_DATATYPES = "bpmn4s:dataTypes";
	private static final String BPMN4S_RAW = "bpmn4s:raw";
	private static final String BPMN2_EXTENSIONELEMENTS = "bpmn2:extensionElements";
	private static final String BPMN2_PROCESS = "bpmn2:process";

	/**
	 * Checks if a BPMN document contains types content.
	 * Looks for the bpmn4s:dataTypes element and checks if it has children.
	 */
	public static boolean hasTypes(Document bpmnDoc) {
		return findAnyElement(bpmnDoc, BPMN4S_DATATYPES).map(Node::hasChildNodes).orElse(false);
	}

	/**
	 * Extracts types content from a BPMN document.
	 * Looks for the bpmn4s:raw element within bpmn4s:dataTypes.
	 */
	public static String extractTypesFromBpmn(Document bpmnDoc) {
		return findAnyElement(bpmnDoc, BPMN4S_RAW).map(Node::getTextContent).orElse(null);
	}

	/**
	 * Injects types content into a BPMN document.
	 * Creates the necessary XML structure if it doesn't exist.
	 */
	public static Document injectTypesIntoBpmn(Document bpmnDoc, String typesContent) {
		Element rawElement = findAnyElement(bpmnDoc, BPMN4S_RAW).orElseGet(() -> createRawElement(bpmnDoc));
		removeAllChildren(rawElement);
		// Add types content as text node
		rawElement.appendChild(bpmnDoc.createTextNode(typesContent));

		return bpmnDoc;
	}

	/**
	 * Removes types from a BPMN document.
	 * Removes the bpmn4s:raw element.
	 */
	public static Document removeTypesFromBpmn(Document bpmnDoc) {
		findAnyElement(bpmnDoc, BPMN4S_DATATYPES).ifPresent(BpmnTypesUtil::removeAllChildren);

		return bpmnDoc;
	}

	/**
	 * Parses XML content into a DOM Document.
	 */
	public static Document parseXml(byte[] content) throws SAXException, IOException, ParserConfigurationException {
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true);
		DocumentBuilder builder = factory.newDocumentBuilder();
		return builder.parse(new java.io.ByteArrayInputStream(content));
	}

	/**
	 * Converts a DOM Document to bytes.
	 */
	public static byte[] xmlToBytes(Document doc) throws Exception {
		TransformerFactory factory = TransformerFactory.newInstance();
		Transformer transformer = factory.newTransformer();
		transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
		transformer.setOutputProperty(OutputKeys.INDENT, "no");
		transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");

		java.io.ByteArrayOutputStream output = new java.io.ByteArrayOutputStream();
		transformer.transform(new DOMSource(doc), new StreamResult(output));
		return output.toByteArray();
	}

	/**
	 * Gets the corresponding .types file path for a .bpmn file.
	 */
	public static Path getTypesPath(Path bpmnPath) {
		String fileName = bpmnPath.getFileName().toString();
		String baseName = fileName.substring(0, fileName.length() - BPMN_EXTENSION.length());
		return bpmnPath.getParent().resolve(baseName + TYPES_EXTENSION);
	}

	/**
	 * Checks if a file path has the BPMN extension (case-insensitive).
	 */
	public static boolean isBpmnFile(Path path) {
		String fileName = path.getFileName().toString().toLowerCase();
		return fileName.endsWith(BPMN_EXTENSION.toLowerCase());
	}

	// ---- Internal Helpers ----
	
	/** Create and append raw element */
	private static Element createRawElement(Document bpmnDoc) {
		Element rawElement = bpmnDoc.createElement(BPMN4S_RAW);
		Element dataTypesElement = findAnyElement(bpmnDoc, BPMN4S_DATATYPES)
				.orElseGet(() -> createDataTypesElement(bpmnDoc));
		dataTypesElement.appendChild(rawElement);
		return rawElement;
	}

	private static Element createDataTypesElement(Document bpmnDoc) {
		// Need to create dataTypes within extensionElements
		Element extensionElement = findAnyElement(bpmnDoc, BPMN2_EXTENSIONELEMENTS).orElseGet(() -> {
			// Create and prepend new extension element
			Element newElement = bpmnDoc.createElement(BPMN2_EXTENSIONELEMENTS);
			Element processElement = findAnyElement(bpmnDoc, BPMN2_PROCESS)
					.orElseThrow(() -> new NoSuchElementException("No process element found in BPMN"));
			processElement.insertBefore(newElement, processElement.getFirstChild());
			return newElement;
		});

		Element dataTypesElement = bpmnDoc.createElement(BPMN4S_DATATYPES);
		extensionElement.appendChild(dataTypesElement);
		return dataTypesElement;
	}
	
	private static Optional<Element> findAnyElement(Document bpmnDoc, String tagName) {
		NodeList elements = bpmnDoc.getElementsByTagName(tagName);
		if (elements.getLength() > 0) {
			return Optional.of((Element) elements.item(0));
		}
		return Optional.empty();
	}
	
	private static void removeAllChildren(Node node) {
		while (node.hasChildNodes()) {
			node.removeChild(node.getFirstChild());
		}
	}
}
