package nl.esi.comma.scenarios.generator.causalgraph;

public class GenerateCausalGraphResult {
	public final CharSequence graphModel;
	public final CausalFootprint footprint;
	public final CausalGraph causalGraph;
	
	public GenerateCausalGraphResult(CharSequence graphModel, CausalFootprint footprint, CausalGraph causalGraph) {
		this.graphModel = graphModel;
		this.footprint = footprint;
		this.causalGraph = causalGraph;
	}
}
