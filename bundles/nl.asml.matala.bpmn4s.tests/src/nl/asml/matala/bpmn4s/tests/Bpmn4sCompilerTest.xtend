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
    def void testCompilation(String fileName) {
        val resourcesDir = Path.of('resources').toRealPath
        assertTrue(resourcesDir.isDirectory)
        println("Test-resources directory: " + resourcesDir)

        val inputFile = resourcesDir.resolve('''input/«fileName».bpmn''')
        assertTrue(inputFile.isReadable, '''Input for «fileName» does not exist or cannot be read.''')

        val actualDir = resourcesDir.resolve('''actual/«fileName»''')
        if (actualDir.exists) {
            FileUtils.deleteDirectory(actualDir.toFile)
        }
        actualDir.createDirectories

        val startTime = System.currentTimeMillis
        Main.compile(inputFile.toString, actualDir.toString)
        println('''Compilation of «fileName».bpmn took «(System.currentTimeMillis - startTime) / 1000.0» seconds.''')

        val expectedDir = resourcesDir.resolve('''expected/«fileName»''')
        assertTrue(expectedDir.isDirectory,
            '''Expected output does not exist, please inspect the actual output at «actualDir».''')

        val expectedFiles = expectedDir.listRegularFiles
        val actualFiles = actualDir.listRegularFiles
        assertEquals(expectedFiles.keySet, actualFiles.keySet, '''Different file set''')

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
            val relativePath = path.relativize(file)
            files.put(relativePath.toString, file)
        }
        return files;
    }

    @Test
    def void testFriesFlat() {
        testCompilation('fries_flat');
    }

    @Test
    def void testFriesSub() {
        testCompilation('fries_sub');
    }

    @Test
    def void testFriesComp() {
        testCompilation('fries_comp');
    }

    @Test
    def void testPrinter() {
        testCompilation('printer');
    }

    @Test
    def void testPrinterWithPriorities() {
        testCompilation('printer_prio');
    }

    @Test
    def void testImaging() {
        testCompilation('imaging');
    }
}