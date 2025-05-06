/**
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
