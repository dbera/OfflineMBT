package nl.esi.comma.causalgraph.transform

import java.util.List
import nl.esi.comma.causalgraph.causalGraph.CausalGraph
import nl.esi.comma.causalgraph.causalGraph.GraphType

import static extension nl.esi.comma.causalgraph.utilities.CausalGraphQueries.*

class Rcg2BddUcgTransformer extends Rcg2UcgTransformer {
    override CausalGraph merge(CausalGraph... rcgs) {
        val outputGraph = super.merge(rcgs)
        outputGraph.type = GraphType::BDDUCG

        // TODO: Post-process nodes 1) merging bodies and 2) generating step names

        return outputGraph
    }

    override protected List<NodeGroup> groupNodes(CausalGraph... rcgs) {
        val nodeGroups = super.groupNodes(rcgs)

        // TODO: Re-group nodes, based on LLM matching

        return nodeGroups
    }
}
