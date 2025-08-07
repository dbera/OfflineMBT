package nl.esi.comma.causalgraph.tests

import java.nio.file.Path
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.transform.Rcg2UcgTransformer
import nl.esi.comma.types.utilities.EcoreUtil3
import org.eclipse.emf.common.util.URI
import org.eclipse.lsat.common.emf.ecore.resource.PersistorFactory
import org.eclipse.xtext.resource.SaveOptions
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import java.nio.file.Files

@ExtendWith(InjectionExtension)
@InjectWith(CausalGraphInjectorProvider)
class Rcg2UcgTransformerTest {
    def protected testTransform(String expected, String... inputs) {
        val persistor = new PersistorFactory().getPersistor(CausalGraph)
        val saveOptions = newHashMap
        SaveOptions.newBuilder.format.options.addTo(saveOptions)

        val rcgs = inputs.map [ input |
            persistor.loadOne(toUri(Path.of('resources','''«input».cg''')))
        ]

        val actualPath = Path.of('resources','''«expected».actual.cg''')
        val actualGraph = new Rcg2UcgTransformer().merge(rcgs)
        EcoreUtil3.unformat(actualGraph)
        persistor.save(toUri(actualPath), saveOptions, actualGraph)

        val expectedPath = Path.of('resources','''«expected».expected.cg''')
        val expectedGraph = persistor.loadOne(toUri(Path.of('resources','''«expected».cg''')))
        EcoreUtil3.unformat(expectedGraph)
        persistor.save(toUri(expectedPath), saveOptions, expectedGraph)

        val expectedContent = EcoreUtil3.serialize(expectedGraph, true)
        val actualContent = EcoreUtil3.serialize(actualGraph, true)
        Assertions.assertEquals(expectedContent, actualContent,
            "Difference(s) found between actual and expected unified causal graphs")

        Files.delete(actualPath)
        Files.delete(expectedPath)
    }

    def protected toUri(Path path) {
        return URI.createURI(path.toUri.toString)
    }

    @Test
    def void test_T1_T2() {
        testTransform('ucg_T1_T2', 'rcg_T1', 'rcg_T2')
    }
}
