package nl.esi.comma.scenarios.generator.causalgraph

import java.util.ArrayList
import nl.esi.comma.scenarios.scenarios.Scenarios
import org.eclipse.xtext.generator.IFileSystemAccess2

class CausalGraphComparison {
	
	/*def generateCausalGraphComparisonReport(Scenarios srcScn, Scenarios dstScn, IFileSystemAccess2 fsa, String taskName, boolean visualize) {
		var srcList = new ArrayList<Scenarios>
		var dstList = new ArrayList<Scenarios>
		srcList.add(srcScn)
		dstList.add(dstScn)
		if (visualize) {
			generateDiffGraph(srcScn, dstScn, fsa, taskName, visualize)
		}
	}*/
	
	def generateCausalGraphComparisonReportWithSCN(Scenarios srcScn, Scenarios dstScn, Scenarios scn, 
	    IFileSystemAccess2 fsa, String taskName, boolean visualize, double sensitivity, boolean ignoreOverlap, 
	    boolean ignoreStepContext, boolean genDot, long SCNDur, long cgDur, GenerateCausalGraphResult srcResult, GenerateCausalGraphResult dstResult,
	    String configFP, String assemFP, String prefix, String defaultName) 
	{
        if (visualize) {
            generateDiffGraphWithSCN(srcScn, dstScn, scn, fsa, taskName, 
                                    visualize, sensitivity, ignoreOverlap, 
                                    ignoreStepContext, genDot, SCNDur, cgDur, srcResult, dstResult,
                                    configFP, assemFP, prefix, defaultName)
        } //else generateDiffGraphWithSCN(srcScn, dstScn, scn, fsa, taskName, visualize, sensitivity, ignoreOverlap)
	}
	
	// TODO Deprecate
	/*def generateDiffGraph(Scenarios srcScn, Scenarios dstScn, IFileSystemAccess2 fsa, String taskName, boolean visualize){
		(new GenerateCausalGraph).generateDiffCG(fsa, srcScn, dstScn, taskName, visualize, 0.5)
		//println()
	}*/
	
	def generateDiffGraphWithSCN(Scenarios srcScn, Scenarios dstScn, Scenarios scn, IFileSystemAccess2 fsa, String taskName, 
	    boolean visualize, double sensitivity, boolean ignoreOverlap, boolean ignoreStepContext, boolean genDot, long scnDur, 
	    long cgDur, GenerateCausalGraphResult srcResult, GenerateCausalGraphResult dstResult,
	    String configFP, String assemFP, String prefix, String defaultName){
        (new GenerateCausalGraph).generateDiffCG(fsa, srcScn, dstScn, scn, taskName, visualize, sensitivity, ignoreOverlap, 
        	ignoreStepContext, genDot, scnDur, cgDur, srcResult, dstResult, configFP, assemFP, prefix, defaultName
        )
        //println()
    }
}