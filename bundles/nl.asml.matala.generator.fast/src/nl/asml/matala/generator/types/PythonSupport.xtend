/* Copyright (c) 2026 TNO-ESI
 * SPDX-License-Identifier: MIT
 */
package nl.asml.matala.generator.types

/** Fixed, reviewed Python helpers. No annotation is interpreted as Python code. */
final class PythonSupport {
    private new() {}

    def static String render() {
        '''
            def validate_identifier(value: str) -> str:
                if not value:
                    return value
                if not value[0].isalpha():
                    raise ValueError("Identifier must start with a letter.")
                if any(char.isspace() for char in value):
                    raise ValueError("Identifier cannot contain spaces.")
                return value


            Identifier = Annotated[str, AfterValidator(validate_identifier)]

        '''.toString
    }
}
