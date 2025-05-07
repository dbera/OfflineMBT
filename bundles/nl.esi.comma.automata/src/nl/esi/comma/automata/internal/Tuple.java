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
package nl.esi.comma.automata.internal;

class Tuple<U, V> {
	final U a;
    final V b;
 
    Tuple(U a, V b)
    {
        this.a = a;
        this.b = b;
    }
    
    Tuple<U,V> copy() {
    	return new Tuple<U,V>(this.a, this.b);
    }
}