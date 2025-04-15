package nl.esi.comma.project.standard.generator

import java.io.BufferedReader
import java.io.InputStreamReader
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.comma.types.utilities.EcoreUtil3.*
import static extension nl.esi.comma.types.utilities.FileSystemAccessUtil.*

class PetriNetToAbstractTspecGenerator extends AbstractGenerator {
    val String pythonExe;

    new() {
        this('python.exe')
    }

    new(String pythonExe) {
        this.pythonExe = pythonExe
    }

    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        doGenerate(res.resourceSet, res.URI, fsa, ctx)
    }

    def void doGenerate(ResourceSet rst, URI uri, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        val process = Runtime.getRuntime().exec(#[
            pythonExe,
            uri.toPath,
            '-no_sim=TRUE',
            '-tsdir=' + fsa.rootURI.toPath
        ])

        var BufferedReader i = new BufferedReader(new InputStreamReader(process.getInputStream()))
        var String line = null
        while ((line = i.readLine()) !== null) {
            System.err.println(line)
        }
        process.destroyForcibly

        // Refresh the files-system to detect the generated files
        fsa.refresh
    }
}
