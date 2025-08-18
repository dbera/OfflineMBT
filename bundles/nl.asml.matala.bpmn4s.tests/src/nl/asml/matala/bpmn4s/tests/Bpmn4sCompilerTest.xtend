/**
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
package nl.asml.matala.bpmn4s.tests

import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import nl.asml.matala.bpmn4s.Main
import org.apache.commons.io.FileUtils
import org.junit.jupiter.api.Test
import static extension java.nio.file.Files.*

import static org.junit.jupiter.api.Assertions.*

class Bpmn4sCompilerTest {
    def void testCompilation(String inputFileName, String expectedFileName, boolean simulation) {
        val resourcesDir = Path.of('resources')
        assertTrue(resourcesDir.isDirectory)

        val inputFile = resourcesDir.resolve('''input/«inputFileName».bpmn''')
        assertTrue(inputFile.isReadable, '''Input for «inputFileName» does not exist or cannot be read.''')

        val actualDir = resourcesDir.resolve('''actual/«expectedFileName»''')
        if (actualDir.exists) {
            FileUtils.deleteDirectory(new File(actualDir.toString()))
        }
        actualDir.createDirectories

        Main.compile(inputFile.toString, simulation, actualDir.toString)

        val expectedDir = resourcesDir.resolve('''expected/«expectedFileName»''')
        assertTrue(expectedDir.isDirectory,
            '''Expected output does not exist, please inspect the actual output at «actualDir».''')

        val expectedFiles = Files.walk(expectedDir).filter[isRegularFile].toList.sort
        val actualFiles = Files.walk(actualDir).filter[isRegularFile].toList.sort
        assertEquals(expectedFiles.map[fileName], actualFiles.map[fileName])

        for (expectedFile : expectedFiles) {
            val actualFile = actualFiles.findFirst[it.fileName == expectedFile.fileName]
            assertLinesMatch(expectedFile.lines, actualFile.lines, '''Different content for «expectedFile.fileName»''')
        }
    }

    @Test
    def void testFriesFlatSimulator() {
        testCompilation('fries_flat', 'fries_flat', true);
    }

    @Test
    def void testPrinterSimulator() {
        testCompilation('printer', 'printer_sim', true);
    }

    @Test
    def void testPrinterTests() {
        testCompilation('printer', 'printer_tests', false);
    }
}