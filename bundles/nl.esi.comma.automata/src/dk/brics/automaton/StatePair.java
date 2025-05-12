/*
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */
package dk.brics.automaton;

/**
 * Pair of states.
 * @author Anders M&oslash;ller &lt;<a href="mailto:amoeller@cs.au.dk">amoeller@cs.au.dk</a>&gt;
 */
public class StatePair {
	State s;
	State s1;
	State s2;
	
	StatePair(State s, State s1, State s2) {
		this.s = s;
		this.s1 = s1;
		this.s2 = s2;
	}
	
	/**
	 * Constructs a new state pair.
	 * @param s1 first state
	 * @param s2 second state
	 */
	public StatePair(State s1, State s2) {
		this.s1 = s1;
		this.s2 = s2;
	}
	
	/**
	 * Returns first component of this pair.
	 * @return first state
	 */
	public State getFirstState() {
		return s1;
	}
	
	/**
	 * Returns second component of this pair.
	 * @return second state
	 */
	public State getSecondState() {
		return s2;
	}
	
	/** 
	 * Checks for equality.
	 * @param obj object to compare with
	 * @return true if <code>obj</code> represents the same pair of states as this pair
	 */
	@Override
	public boolean equals(Object obj) {
		if (obj instanceof StatePair) {
			StatePair p = (StatePair)obj;
			return p.s1 == s1 && p.s2 == s2;
		}
		else
			return false;
	}
	
	/** 
	 * Returns hash code.
	 * @return hash code
	 */
	@Override
	public int hashCode() {
		return s1.hashCode() + s2.hashCode();
	}
}
