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
package nl.esi.comma.project.standard.test.util;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;

import nl.esi.comma.project.standard.util.BpmnTypesUtil;

/**
 * Test cases for BpmnTypesUtil.
 * Tests the extraction and injection of type definitions in BPMN files.
 */
public class BpmnTypesUtilTest {

	private Document simplifiedBpmnDoc;
	private String testTypes;

	@BeforeEach
	public void setUp() throws Exception {
		// Test types content
		testTypes = "enum Size {\n  Small\n  Medium\n  Large\n}\n\nrecord Order {\n  string id\n  Size size\n}";

		// Simplified BPMN document (similar to fries_comp.bpmn structure)
		String bpmnXml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
			"<bpmn2:definitions xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n" +
			"    xmlns:bpmn2=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" \n" +
			"    xmlns:bpmn4s=\"http://bpmn4s\" \n" +
			"    id=\"test-diagram\" \n" +
			"    targetNamespace=\"http://test.io/schema/bpmn\">\n" +
			"  <bpmn2:process id=\"Process_1\" isExecutable=\"false\" name=\"TestProcess\">\n" +
			"    <bpmn2:extensionElements>\n" +
			"      <bpmn4s:dataTypes>\n" +
			"        <bpmn4s:raw>" + testTypes + "</bpmn4s:raw>\n" +
			"      </bpmn4s:dataTypes>\n" +
			"    </bpmn2:extensionElements>\n" +
			"  </bpmn2:process>\n" +
			"</bpmn2:definitions>";

		// Parse the BPMN XML string
		simplifiedBpmnDoc = BpmnTypesUtil.parseXml(bpmnXml.getBytes(java.nio.charset.StandardCharsets.UTF_8));
	}

	@Test
	public void testExtractTypesFromBpmn() {
		// Extract types from the BPMN document
		String extractedTypes = BpmnTypesUtil.extractTypesFromBpmn(simplifiedBpmnDoc);

		// Verify types were extracted correctly
		assertNotNull(extractedTypes, "Extracted types should not be null");
		assertTrue(extractedTypes.contains("enum Size"), "Extracted types should contain 'Size'");
		assertTrue(extractedTypes.contains("record Order"), "Extracted types should contain 'Order'");
		assertEquals(testTypes, extractedTypes, "Extracted types should match original");
	}

	@Test
	public void testInjectTypesIntoBpmn() throws Exception {
		// Create a BPMN without types using multiline string
		String bpmnWithoutTypesXml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
			"<bpmn2:definitions xmlns:bpmn2=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" \n" +
			"    xmlns:bpmn4s=\"http://bpmn4s\" \n" +
			"    id=\"test-diagram\" \n" +
			"    targetNamespace=\"http://test.io/schema/bpmn\">\n" +
			"  <bpmn2:process id=\"Process_1\" isExecutable=\"false\" name=\"TestProcess\">\n" +
			"  </bpmn2:process>\n" +
			"</bpmn2:definitions>";
		
		Document bpmnWithoutTypes = BpmnTypesUtil.parseXml(bpmnWithoutTypesXml.getBytes(java.nio.charset.StandardCharsets.UTF_8));

		// Inject types
		String newTypes = "record User {\n  string name\n}";
		Document modifiedDoc = BpmnTypesUtil.injectTypesIntoBpmn(bpmnWithoutTypes, newTypes);

		// Verify types were injected
		String extractedTypes = BpmnTypesUtil.extractTypesFromBpmn(modifiedDoc);
		assertNotNull(extractedTypes, "Injected types should be extractable");
		assertEquals(newTypes, extractedTypes, "Injected types should match");
	}

	@Test
	public void testRemoveTypesFromBpmn() {
		// Remove types from the BPMN document
		Document modifiedDoc = BpmnTypesUtil.removeTypesFromBpmn(simplifiedBpmnDoc);

		// Verify types were removed
		String extractedTypes = BpmnTypesUtil.extractTypesFromBpmn(modifiedDoc);
		assertNull(extractedTypes, "Removed types should result in null extraction");
	}

	@Test
	public void testIsBpmnFile() {
		// Test with .bpmn files
		assertTrue(BpmnTypesUtil.isBpmnFile(java.nio.file.Paths.get("test.bpmn")), "Should recognize .bpmn files");
		assertTrue(BpmnTypesUtil.isBpmnFile(java.nio.file.Paths.get("test.BPMN")), "Should recognize .BPMN files (uppercase)");
		assertTrue(BpmnTypesUtil.isBpmnFile(java.nio.file.Paths.get("test.Bpmn")), "Should recognize .Bpmn files (mixed case)");

		// Test with non-bpmn files
		assertFalse(BpmnTypesUtil.isBpmnFile(java.nio.file.Paths.get("test.xml")), "Should not recognize .xml files");
		assertFalse(BpmnTypesUtil.isBpmnFile(java.nio.file.Paths.get("test.types")), "Should not recognize .types files");
	}

	@Test
	public void testRoundTripExtractInject() throws Exception {
		// Extract types from original
		String extractedTypes = BpmnTypesUtil.extractTypesFromBpmn(simplifiedBpmnDoc);

		// Remove types
		Document withoutTypes = BpmnTypesUtil.removeTypesFromBpmn(simplifiedBpmnDoc);
		assertNull(BpmnTypesUtil.extractTypesFromBpmn(withoutTypes), "Types should be removed");

		// Inject types back
		Document withTypesAgain = BpmnTypesUtil.injectTypesIntoBpmn(withoutTypes, extractedTypes);
		String reinjectedTypes = BpmnTypesUtil.extractTypesFromBpmn(withTypesAgain);

		// Verify round-trip worked
		assertEquals(extractedTypes, reinjectedTypes, "Types should be identical after round-trip");
	}

	@Test
	public void testXmlConversion() throws Exception {
		// Convert BPMN to bytes
		byte[] bpmnBytes = BpmnTypesUtil.xmlToBytes(simplifiedBpmnDoc);
		assertNotNull(bpmnBytes, "Converted bytes should not be null");
		assertTrue(bpmnBytes.length > 0, "Converted bytes should be non-empty");

		// Parse bytes back to document
		Document parsedDoc = BpmnTypesUtil.parseXml(bpmnBytes);
		assertNotNull(parsedDoc, "Parsed document should not be null");

		// Verify types are still present
		String extractedTypes = BpmnTypesUtil.extractTypesFromBpmn(parsedDoc);
		assertEquals(testTypes, extractedTypes, "Types should be preserved in round-trip conversion");
	}

}
