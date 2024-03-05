package nl.esi.comma.signature.generator.dezyne

import nl.esi.comma.signature.interfaceSignature.Command

class CommandReturnedParameter {
	public Command Command;
	public CharSequence returnDataType;
	public CharSequence TypeName;
	public boolean isExternDataType = false;
	new (Command c, CharSequence typeName){
		this.Command = c;
		this.TypeName = typeName;
	}
}
