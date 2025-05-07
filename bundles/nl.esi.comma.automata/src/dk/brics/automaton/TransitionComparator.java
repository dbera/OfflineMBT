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

import java.io.Serializable;
import java.util.Comparator;

class TransitionComparator implements Comparator<Transition>, Serializable {

	static final long serialVersionUID = 10001;

	boolean to_first;
	
	TransitionComparator(boolean to_first) {
		this.to_first = to_first;
	}
	
	/** 
	 * Compares by (min, reverse max, to) or (to, min, reverse max). 
	 */
	public int compare(Transition t1, Transition t2) {
		if (to_first) {
			if (t1.to != t2.to) {
				if (t1.to == null)
					return -1;
				else if (t2.to == null)
					return 1;
				else if (t1.to.number < t2.to.number)
					return -1;
				else if (t1.to.number > t2.to.number)
					return 1;
			}
		}
		if (t1.min < t2.min)
			return -1;
		if (t1.min > t2.min)
			return 1;
		if (t1.max > t2.max)
			return -1;
		if (t1.max < t2.max)
			return 1;
		if (!to_first) {
			if (t1.to != t2.to) {
				if (t1.to == null)
					return -1;
				else if (t2.to == null)
					return 1;
				else if (t1.to.number < t2.to.number)
					return -1;
				else if (t1.to.number > t2.to.number)
					return 1;
			}
		}
		return 0;
	}
}
