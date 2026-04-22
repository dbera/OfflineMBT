package nl.asml.matala.testutils

import java.nio.file.Path
import java.util.Map
import java.util.TreeMap
import org.apache.commons.io.FileUtils
import org.apache.commons.io.FilenameUtils
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.util.CancelIndicator

import static org.junit.jupiter.api.Assertions.*

import static extension java.nio.file.Files.*

class XtextGeneratorTest {
    static def void regressionTest(AbstractGenerator generator, String fileName) {
        regressionTest(generator, fileName, "")
    }

    static def void regressionTest(AbstractGenerator generator, String fileName, String variant) {
        val resourcesDir = Path.of('resources').toRealPath
        assertTrue(resourcesDir.isDirectory)
        println("Test-resources directory: " + resourcesDir)

        val baseName = FilenameUtils.getBaseName(fileName)
        val inputFile = resourcesDir.resolve('''input/«baseName»/«fileName»''')
        assertTrue(inputFile.isReadable, '''Input «inputFile» does not exist or cannot be read.''')

        val resourceSet = new XtextResourceSet()
        val inputResource = resourceSet.getResource(TestFileSystemAccess.getURI(inputFile), true)
        assertTrue(inputResource.errors.isEmpty, '''Input «inputFile» contains errors: «inputResource.errors.join(', ')[message]»''')
        EcoreUtil.resolveAll(inputResource)

        val actualDir = resourcesDir.resolve('''actual/«baseName»«variant»''')
        if (actualDir.exists) {
            FileUtils.deleteDirectory(actualDir.toFile)
        }
        actualDir.createDirectories

        generator.doGenerate(inputResource, new TestFileSystemAccess(actualDir))[CancelIndicator.NullImpl]

        val expectedDir = resourcesDir.resolve('''expected/«baseName»«variant»''')
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

    private static def Map<String, Path> listRegularFiles(Path path) {
        val files = new TreeMap()
        for (file : path.walk.filter[isRegularFile].toList) {
            val relativePath = path.relativize(file)
            files.put(relativePath.toString, file)
        }
        return files;
    }
}