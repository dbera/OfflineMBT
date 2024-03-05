package nl.esi.comma.automata.internal;

import java.util.ArrayList;
import java.util.List;

import dk.brics.automaton.State;

public class Path {
	public final ArrayList<Transition> transitions;
	
	Path() {
		this.transitions = new ArrayList<Transition>();
	}
	
	Path(List<Path> paths) {
		this.transitions = new ArrayList<Transition>();
		paths.forEach(p -> this.transitions.addAll(p.transitions));
	}
	
	Path(ArrayList<Transition> transitions) {
		this.transitions = transitions;
	}
	
	void append(List<Transition> transitions) {
		this.transitions.addAll(transitions);
	}
	
	void append(Path path) {
		this.transitions.addAll(path.transitions);
	}
	
	void append(Transition transition) {
		this.transitions.add(transition);
	}
	
	Path pathTill(State state) {
		for (int i = 0; i < this.transitions.size(); i++) {
			if (this.transitions.get(i).target == state) {
				return new Path(new ArrayList<>(this.transitions.subList(0, i + 1)));
			}
		}
		
		return null;
	}
	
	Path pathFrom(State state) {
		for (int i = 0; i < this.transitions.size(); i++) {
			if (this.transitions.get(i).source == state) {
				return new Path(new ArrayList<>(this.transitions.subList(i, this.transitions.size())));
			}
		}
		
		return null;
	}
	
	boolean hasTarget(State state) {
		for (var transition : this.transitions) {
			if (transition.target == state) {
				return true;
			}
		}
		
		return false;
	}
	
	Path removeLastTranition() {
		var sublist = transitions.subList(0, transitions.size() - 1);
		return new Path(new ArrayList<Transition>(sublist));
	}
	
	Path sliceAfter(Transition transition) {
		var sublist = transitions.subList(transitions.indexOf(transition) + 1, transitions.size());
		return new Path(new ArrayList<Transition>(sublist));
	}
	
	boolean startsWith(Path other) {
		if (other.transitions.size() > this.transitions.size()) return false;
		for (var i = 0; i < other.transitions.size(); i++) {
			if (this.transitions.get(i) != other.transitions.get(i)) {
				return false;
			}
		}
	
		return true;
	}
	
	Path combine(List<Transition> transitions) {
		@SuppressWarnings("unchecked")
		var t = (ArrayList<Transition>) this.transitions.clone();
		t.addAll(transitions);
		return new Path(t);
	}
	
	Path combine(Path other) {
		return this.combine(other.transitions);
	}
	
	Path combine(Transition transition) {
		@SuppressWarnings("unchecked")
		var t = (ArrayList<Transition>) this.transitions.clone();
		t.add(transition);
		return new Path(t);
	}
	
	public State getSource() {
		return this.transitions.get(0).source;
	}
	
	State getTarget() {
		return this.transitions.get(this.transitions.size() - 1).target;
	}
	
	Transition lastTransition() {
		return this.transitions.get(this.transitions.size() - 1);
	}

	@Override 
    public String toString() {
		return String.join(",", this.transitions.toString());
    }
}
