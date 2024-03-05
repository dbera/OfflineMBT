package nl.esi.comma.automata;

import nl.esi.comma.automata.internal.Path;

public class AlignResult {
	public enum Status {FULLY_ACCEPTED, PARTIAL_ACCEPTED, NOT_ACCEPTED}
	
	public final Status status;
	public final String accepted;
	public final String notAccepted;
	public final String scenario;
	public final Path path;
	
	public AlignResult(Status status, String accepted, String notAccepted, String scenario, Path path) {
		this.status = status;
		this.accepted = accepted;
		this.notAccepted = notAccepted;
		this.path = path;
		this.scenario = scenario;
	}
	
	public int pathTransitionsSize() {
		return path.transitions.size();
	}
}
