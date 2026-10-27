package nl.esi.comma.testspecification.generator.json

import nl.esi.comma.testspecification.testspecification.TestDefinition
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

/**
 * Independent facade for generating JSON from a parsed TestDefinition.
 *
 * This class deliberately does not rely on Guice injection because generator
 * extensions may be instantiated by the Eclipse extension registry.
 */
class TestspecificationJsonGenerator {

    val TestspecificationJsonSerializer serializer

    new() {
        serializer = new TestspecificationJsonSerializer
    }

    def void generate(
        TestDefinition testDefinition,
        Resource sourceResource,
        IFileSystemAccess2 fsa
    ) {
        if (testDefinition !== null) {
            val sourceName = sourceResource.URI
                .trimFileExtension
                .lastSegment

            fsa.generateFile(
                sourceName + ".json",
                serializer.serialize(
                    testDefinition,
                    sourceName
                )
            )
        }
    }
}
