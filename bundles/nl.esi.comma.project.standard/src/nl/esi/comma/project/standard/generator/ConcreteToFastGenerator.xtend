package nl.esi.comma.project.standard.generator

import nl.esi.comma.testspecification.generator.TestspecificationGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

class ConcreteToFastGenerator extends AbstractGenerator {
    override doGenerate(Resource res, IFileSystemAccess2 fsa, IGeneratorContext ctx) {
        (new TestspecificationGenerator()).doGenerate(res, fsa, ctx)
    }
}