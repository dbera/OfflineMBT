package nl.esi.comma.project.standard.generator

import nl.asml.matala.bpmn4s.Main
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.FileSystemAccessUtil.*

class Bpmn4sToPspecGenerator extends AbstractGenerator {
    val boolean simulation;

    new() {
        this(false)
    }

    new(boolean simulation) {
        this.simulation = simulation
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        doGenerate(res.resourceSet, res.URI, fsa, ctx)
    }

    /**
     * FIXME: nl.asml.matala.bpmn4s.Main should implement Xtext generator API
     */
    def void doGenerate(ResourceSet rst, URI uri, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        // Temporary generate the file to ensure that folders exist
        val pspecPath = uri.trimFileExtension.appendFileExtension('ps').lastSegment
        fsa.generateFile(pspecPath, '// TODO: Generate content')

        // Generate the pspec file from the bpmn file
        Main.compile(uri.toPath, simulation, fsa.rootURI.toPath)

        // Refresh the files-system to detect the generated files
        fsa.refresh
    }
}
