package nl.asml.matala.generator.bpmn

import nl.esi.comma.project.standard.generator.^extension.IStandardProjectGeneratorExtension
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import static extension nl.esi.xtext.common.lang.generator.FileSystemAccessUtil.*

class FromConcreteToBpmn extends AbstractGenerator implements IStandardProjectGeneratorExtension {
    override doGenerate(Resource conTspecRes, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        // Find and load the abstract tspec for this concrete tspec
        val absTspecFsa = fsa.createFolderAccess(FOLDER_ABSTRACT_TSPEC)
        val absTspecURI = conTspecRes.URI.trimFileExtension.appendFileExtension('atspec')
        val absTspecRes = absTspecFsa.loadResource(absTspecURI.lastSegment, conTspecRes.resourceSet)

        // Generate bpmn for atspec
        val fromAbstractToBpmn = new FromAbstractToBpmn()
        fromAbstractToBpmn.doGenerate(absTspecRes, absTspecFsa, ctx)
    }
}