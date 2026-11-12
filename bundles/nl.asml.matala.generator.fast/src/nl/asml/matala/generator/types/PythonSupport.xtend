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
package nl.asml.matala.generator.types

/** Fixed, reviewed Python helpers. No annotation is interpreted as Python code. */
final class PythonSupport {
    private new() {}

    def static String render() {
        '''
            def _validate_identifier(value: _types_builtins.str) -> _types_builtins.str:
                if not value:
                    return value
                if not value[0].isalpha():
                    raise ValueError("Identifier must start with a letter.")
                if any(char.isspace() for char in value):
                    raise ValueError("Identifier cannot contain spaces.")
                return value


            _TypesIdentifier = _types_typing.Annotated[_types_builtins.str, _types_pydantic.AfterValidator(_validate_identifier)]

        '''.toString
    }
}
