package nl.asml.matala.product.generator

import java.util.ArrayList
import nl.asml.matala.product.generator.Constraint
import nl.asml.matala.product.generator.PType

class ArcExpression 
{
	public var type = PType.IN
	public var t = new String
	public var p = new String
	public var expTxt = new String
	public var constraints = new ArrayList<Constraint>
	
	new(String _t, String _p, String _expTxt, PType _type, ArrayList<Constraint> _constraints) {
		t = _t
		p = _p
		expTxt = _expTxt
		type = _type
		constraints = _constraints
	}
	
	def areEqual(String _t, String _p, PType _type) {
		if(t.equals(_t) && p.equals(_p) && type.equals(_type)) return true
		else return false
	}
}