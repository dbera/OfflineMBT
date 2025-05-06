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

class Triplet<U, V, T> {
	final U a;
    final V b;
    final T c; 
 
    Triplet(U a, V b, T c)
    {
        this.a = a;
        this.b = b;
        this.c = c;
    }
    
    Triplet<U,V,T> copy() {
    	return new Triplet<U,V,T>(this.a, this.b, this.c);
    }
}