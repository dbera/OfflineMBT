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

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
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
	private static final String BPMN4S_NAMESPACE = "http://bpmn4s";

	/**
	 * Extracts types content from a BPMN document.
	 * Looks for the bpmn4s:raw element within bpmn4s:dataTypes.
	 */
	public static String extractTypesFromBpmn(Document bpmnDoc) {
		NodeList rawElements = bpmnDoc.getElementsByTagNameNS(BPMN4S_NAMESPACE, "raw");
		if (rawElements.getLength() > 0) {
			Element rawElement = (Element) rawElements.item(0);
			return rawElement.getTextContent();
		}
		return null;
	}

	/**
	 * Injects types content into a BPMN document.
	 * Creates the necessary XML structure if it doesn't exist.
	 */
	public static Document injectTypesIntoBpmn(Document bpmnDoc, String typesContent) {
		Element rawElement = findOrCreateRawElement(bpmnDoc);

		// Clear existing content
		while (rawElement.hasChildNodes()) {
			rawElement.removeChild(rawElement.getFirstChild());
		}

		// Add types content as text node
		rawElement.appendChild(bpmnDoc.createTextNode(typesContent));

		return bpmnDoc;
	}

	/**
	 * Removes types from a BPMN document.
	 * Removes the bpmn4s:raw element.
	 */
	public static Document removeTypesFromBpmn(Document bpmnDoc) {
		NodeList rawElements = bpmnDoc.getElementsByTagNameNS(BPMN4S_NAMESPACE, "raw");
		while (rawElements.getLength() > 0) {
			Element rawElement = (Element) rawElements.item(0);
			rawElement.getParentNode().removeChild(rawElement);
		}
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
		transformer.setOutputProperty("indent", "yes");
		transformer.setOutputProperty("encoding", "UTF-8");

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

	private static Element findOrCreateRawElement(Document bpmnDoc) {
		// Find existing raw element
		NodeList rawElements = bpmnDoc.getElementsByTagNameNS(BPMN4S_NAMESPACE, "raw");
		if (rawElements.getLength() > 0) {
			return (Element) rawElements.item(0);
		}

		// Create new raw element if it doesn't exist
		NodeList dataTypesElements = bpmnDoc.getElementsByTagNameNS(BPMN4S_NAMESPACE, "dataTypes");
		Element dataTypesElement;

		if (dataTypesElements.getLength() == 0) {
			// Need to create dataTypes within extensionElements
			NodeList extensionElements = bpmnDoc.getElementsByTagName("bpmn2:extensionElements");
			Element extElement;
			if (extensionElements.getLength() == 0) {
				// Create extensionElements in the process
				NodeList processes = bpmnDoc.getElementsByTagName("bpmn2:process");
				if (processes.getLength() == 0) {
					throw new RuntimeException("No process element found in BPMN");
				}
				extElement = bpmnDoc.createElementNS("http://www.omg.org/spec/BPMN/20100524/MODEL", "bpmn2:extensionElements");
				processes.item(0).insertBefore(extElement, processes.item(0).getFirstChild());
			} else {
				extElement = (Element) extensionElements.item(0);
			}

			dataTypesElement = bpmnDoc.createElementNS(BPMN4S_NAMESPACE, "bpmn4s:dataTypes");
			extElement.appendChild(dataTypesElement);
		} else {
			dataTypesElement = (Element) dataTypesElements.item(0);
		}

		// Create and append raw element
		Element rawElement = bpmnDoc.createElementNS(BPMN4S_NAMESPACE, "bpmn4s:raw");
		dataTypesElement.appendChild(rawElement);

		return rawElement;
	}

}
