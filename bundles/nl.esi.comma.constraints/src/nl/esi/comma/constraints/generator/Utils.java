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
 
package nl.esi.comma.constraints.generator;

import nl.esi.xtext.types.types.EnumTypeDecl;
import nl.esi.xtext.types.types.MapTypeConstructor;
import nl.esi.xtext.types.types.MapTypeDecl;
import nl.esi.xtext.types.types.RecordFieldKind;
import nl.esi.xtext.types.types.RecordTypeDecl;
import nl.esi.xtext.types.types.SimpleTypeDecl;
import nl.esi.xtext.types.types.Type;
import nl.esi.xtext.types.types.TypeDecl;
import nl.esi.xtext.types.types.VectorTypeConstructor;
import nl.esi.xtext.types.types.VectorTypeDecl;
import nl.esi.xtext.types.utilities.TypeUtilities;
import java.util.stream.Collectors;

class Utils {

    static String defaultValue(Type type, String targetName) {
        // TypeReference | VectorTypeConstructor | MapTypeConstructor
        if (type instanceof VectorTypeConstructor) {
            return TypeUtilities.getTypeName(type) + "[]";
        } else if (type instanceof MapTypeConstructor) {
            return "<" + TypeUtilities.getTypeName(type) + ">" + "{}";
        } else {
            return defaultValue(type.getType(), targetName);
        }
    }

    static String defaultValue(TypeDecl type, String targetName) {
        if (type instanceof SimpleTypeDecl) {
            SimpleTypeDecl t = (SimpleTypeDecl) type;
            if (t.getBase() != null) return defaultValue(t.getBase(), targetName);
            else if (t.getName().equals("int")) return "0";
            else if (t.getName().equals("real")) return "0.0";
            else if (t.getName().equals("bool")) return "True";
            else if (t.getName().equals("string")) return "\"\"";
            else return "\"\""; // Custom types without base (e.g. type DateTime)
        } else if (type instanceof VectorTypeDecl vecType) {
            return "[]";
        } else if (type instanceof EnumTypeDecl) {
            EnumTypeDecl t = (EnumTypeDecl) type;
            return String.format("%s::%s", t.getName(), t.getLiterals().get(0).getName());
        } else if (type instanceof MapTypeDecl mapType) {
            return "{" + 
                    defaultValue(((MapTypeDecl) type).getConstructor().getType(), targetName) + 
                    ":" +
                    defaultValue(((MapTypeDecl) type).getConstructor().getValueType().getType(), targetName) +
                    "}";
        } else if (type instanceof RecordTypeDecl recType) {
            String value = TypeUtilities.getAllFields(recType).stream()
                .filter(f -> !RecordFieldKind.SYMBOLIC.equals(f.getKind()))
                .map(f -> String.format("%s = %s", f.getName(), defaultValue(f.getType(), f.getName())))
                .collect(Collectors.joining(","));
            return String.format("%s {%s}", recType.getName(), value);
        } 
        
        throw new RuntimeException("Not supported");
    }
}
