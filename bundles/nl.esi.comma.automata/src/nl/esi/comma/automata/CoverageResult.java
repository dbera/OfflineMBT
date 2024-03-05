package nl.esi.comma.automata;

public class CoverageResult {
	
	public final double stateCoverage;
	public final double transitionCoverage;
	
	public CoverageResult(double stateCoverage, double transitionCoverage) {
		this.stateCoverage = stateCoverage;
		this.transitionCoverage = transitionCoverage;
	}
}
