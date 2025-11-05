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
package nl.esi.comma.abstracttestspecification.tests

import java.nio.file.Files
import java.nio.file.Path
import java.util.Map
import java.util.TreeMap
import nl.esi.comma.abstracttestspecification.generator.to.concrete.FromAbstractToConcrete
import org.apache.commons.io.FileUtils
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.util.CancelIndicator
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.junit.jupiter.api.Assertions.*

import static extension java.nio.file.Files.*

@ExtendWith(InjectionExtension)
@InjectWith(AbstractTestspecificationInjectorProvider)
class FromAbstractToConcreteTest {
    private def void testGenerator(String testcase) {
        val resourcesDir = Path.of('resources').toRealPath
        assertTrue(resourcesDir.isDirectory)
        println("Test-resources directory: " + resourcesDir)

        val inputFile = resourcesDir.resolve('''input/«testcase»/«testcase».atspec''')
        assertTrue(inputFile.isReadable, '''Input «inputFile» does not exist or cannot be read.''')

        val resourceSet = new XtextResourceSet()
        val inputResource = resourceSet.getResource(TestFileSystemAccess.getURI(inputFile), true)
        assertTrue(inputResource.errors.isEmpty, '''Input «testcase» contains errors: «inputResource.errors.join(', ')[message]»''')
        EcoreUtil.resolveAll(inputResource)

        val actualDir = resourcesDir.resolve('''actual/«testcase»''')
        if (actualDir.exists) {
            FileUtils.deleteDirectory(actualDir.toFile)
        }
        actualDir.createDirectories

        new FromAbstractToConcrete().doGenerate(inputResource, new TestFileSystemAccess(actualDir))[CancelIndicator.NullImpl]

        val expectedDir = resourcesDir.resolve('''expected/«testcase»''')
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
        for (file : Files.walk(path).filter[isRegularFile].toList) {
            files.put(file.relativize(path).toString, file)
        }
        return files;
    }

    @Test
    def void testIssue249() {
        testGenerator('issue249');
    }
}