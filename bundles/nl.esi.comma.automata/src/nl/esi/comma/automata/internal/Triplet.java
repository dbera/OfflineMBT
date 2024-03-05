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