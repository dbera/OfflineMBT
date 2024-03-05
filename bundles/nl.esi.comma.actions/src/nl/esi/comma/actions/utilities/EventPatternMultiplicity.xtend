package nl.esi.comma.actions.utilities

class EventPatternMultiplicity {
	public long lower = 1
	public long upper = 1
	
	def boolean isOptional(){
		lower == 0
	}
	
	def boolean isMultiple(){
		upper > 1 || upper == -1
	}
	
	def boolean isOne(){
		lower == 1 && upper == 1
	}
}