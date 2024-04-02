package nl.esi.comma.constraints.generator.visualize

class AssistantEdge {
	ArrowType type
	String source
	String target
	String label
	
	new(String src, String trg, ArrowType type, String label){
		this.source = src
		this.target = trg
		this.type = type
		this.label = label
	}
	
	def getLabel(){
		return this.label
	}
	
	def setLabel(String l){
		this.label = l
	}
	
	def getSource(){
		return this.source
	}
	
	def getTarget(){
		return this.target
	}
	
	def getType(){
		return this.type
	}

}

enum ArrowType{
	right, //future
	dashedRight,//eventuallyfuture
	left,//precedence
	dashedLeft,//eventuallyprecedence
	both,//vice-versa
	dashedBoth,//eventually vice-versa
	negationRight,//negation
	none,
	rightGrey,
	rightDashedGrey
}