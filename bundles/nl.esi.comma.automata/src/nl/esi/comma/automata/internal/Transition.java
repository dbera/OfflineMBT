package nl.esi.comma.automata.internal;

import dk.brics.automaton.State;

public class Transition {
    public final State source;
    private final dk.brics.automaton.Transition transition;
    public final State target;

    Transition(State source, dk.brics.automaton.Transition transition, boolean pickFirstCharOnly) {
        this.source = source;
        this.transition = transition;
        this.target = transition.getDest();
    }
    
    Transition(State source, dk.brics.automaton.Transition transition) {
        this(source, transition, false);
    }
    
    public char getMin() {
    	return this.transition.getMin();
    }
    
    boolean isLoop() {
    	return this.source == this.target;
    }
    
    public char getMax() {
    	return this.transition.getMax();
    }

    @Override
    public int hashCode() {
        return this.source.hashCode() * this.transition.hashCode();
    }
    
    @Override
    public boolean equals(Object o) {
        var obj = (Transition) o;
        return this.transition.equals(obj.transition) && this.source.equals(obj.source);
    }
    
    @Override 
    public String toString() {
    	return this.source.toString().split(" ")[1] +
    			this.transition.toString().split(" ")[0] + 
    			this.target.toString().split(" ")[1];
    }
}