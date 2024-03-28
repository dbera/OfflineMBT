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