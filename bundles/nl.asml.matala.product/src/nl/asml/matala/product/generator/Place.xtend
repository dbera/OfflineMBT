package nl.asml.matala.product.generator

import nl.esi.comma.types.types.TypeDecl

class Place {
	public var bname = new String
	public var name = new String
	public var type = PType::IN
	public var TypeDecl custom_type
	new (String b, String n, PType t, TypeDecl ctype) {
		bname = b
		name = n
		type = t
		custom_type = ctype
	}
}
