package nl.esi.comma.types.generator.dezyne

import org.eclipse.xtend.lib.annotations.Accessors

class DezyneTargetTypeSpec {
	
	@Accessors(PUBLIC_GETTER) String targetTypeName
	@Accessors(PUBLIC_GETTER) boolean isTypeDef
	@Accessors( PUBLIC_GETTER) String signatureName
	
	String dezyneTypeName;
	
	new(String name, boolean isTypeDef, String interfaceName){
		this.targetTypeName = name
		this.isTypeDef = isTypeDef
		this.signatureName = interfaceName
	}
	new(String name, boolean isTypeDef, String interfaceName, String dezyneTypeName){
		this.targetTypeName = name
		this.isTypeDef = isTypeDef
		this.signatureName = interfaceName
//		this.dezyneTypeName = dezyneTypeName
	}
	
	def String getTargetTypeName() {
   		return this.targetTypeName;
  	}
  
  	def void setTargetTypeName(String targetTypeName) {
    	this.targetTypeName = targetTypeName;
  	}

  	def boolean getIsTypeDef() {
   		return this.isTypeDef;
  	}
  	
  	def String getSignatureName() {
   		return this.signatureName;
  	}
  
	def String getDezyneTypeName() {
   		return this.dezyneTypeName;
  	}
  
  	def void setDezyneTypeName(String dezyneTypeName) {
    	this.dezyneTypeName = dezyneTypeName;
  	}
  	
}
