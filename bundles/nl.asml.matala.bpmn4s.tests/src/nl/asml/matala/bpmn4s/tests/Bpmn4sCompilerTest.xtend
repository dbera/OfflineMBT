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

import java.nio.file.Path
import java.util.Map
import java.util.TreeMap
import nl.asml.matala.bpmn4s.Main
import org.apache.commons.io.FileUtils
import org.junit.jupiter.api.Test

import static org.junit.jupiter.api.Assertions.*

import static extension java.nio.file.Files.*

class Bpmn4sCompilerTest {
    def void testCompilation(String inputFileName, String expectedFileName, boolean simulation) {
        val resourcesDir = Path.of('resources').toRealPath
        assertTrue(resourcesDir.isDirectory)
        println("Test-resources directory: " + resourcesDir)

        val inputFile = resourcesDir.resolve('''input/«inputFileName».bpmn''')
        assertTrue(inputFile.isReadable, '''Input for «inputFileName» does not exist or cannot be read.''')

        val actualDir = resourcesDir.resolve('''actual/«expectedFileName»''')
        if (actualDir.exists) {
            FileUtils.deleteDirectory(actualDir.toFile)
        }
        actualDir.createDirectories

        Main.compile(inputFile.toString, simulation, actualDir.toString)

        val expectedDir = resourcesDir.resolve('''expected/«expectedFileName»''')
        assertTrue(expectedDir.isDirectory,
            '''Expected output does not exist, please inspect the actual output at «actualDir».''')

        val expectedFiles = expectedDir.listRegularFiles
        val actualFiles = actualDir.listRegularFiles
        assertEquals(expectedFiles.keySet, actualFiles.keySet)

        for (expectedFileEntry : expectedFiles.entrySet) {
            val expectedFile = expectedFileEntry.value
            val actualFile = actualFiles.get(expectedFileEntry.key)
            assertLinesMatch(expectedFile.lines, actualFile.lines, '''Different content for «expectedFile.toString»''')
        }
        FileUtils.deleteDirectory(actualDir.toFile)
    }

    private def Map<String, Path> listRegularFiles(Path path) {
        val files = new TreeMap()
        for (file : path.walk.filter[isRegularFile].toList) {
            files.put(file.relativize(path).toString, file)
        }
        return files;
    }

    @Test
    def void testFriesFlat() {
        testCompilation('fries_flat', 'fries_flat', true);
    }

    @Test
    def void testFriesSub() {
        testCompilation('fries_sub', 'fries_sub', true);
    }

    @Test
    def void testFriesComp() {
        testCompilation('fries_comp', 'fries_comp', true);
    }

    @Test
    def void testPrinter() {
        testCompilation('printer', 'printer', true);
    }
}