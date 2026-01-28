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
package nl.esi.xtext.common.lang.conversion;

import org.eclipse.xtext.conversion.IValueConverter;
import org.eclipse.xtext.conversion.ValueConverterException;
import org.eclipse.xtext.nodemodel.INode;

public class TableCellValueConverter implements IValueConverter<String> {
	@Override
	public String toValue(final String string, final INode node) throws ValueConverterException {
		if (!string.startsWith("|")) {
			throw new ValueConverterException("Expected table cell value to start with |", node, null);
		}
		System.out.println("''" + string + "''");
		for (int index = 0; index < string.length(); index++) {
			if (string.charAt(index) != '\\') {
				continue;
			} else if (index == string.length() - 1) {
				throw new ValueConverterException("Final backslash should be escaped", node, null);
			}
			char escaped = string.charAt(++index);
			if (escaped == '\\' || escaped == '|') {
				continue;
			}
			String msg = String.format("Illegal character sequence '%s' at index %d, backslash should be escaped",
					string.substring(index - 1, index + 1), index);
			throw new ValueConverterException(msg, node, null);
		}
		return string.substring(1).trim().replaceAll("\\\\(.)", "$1");
	}

	@Override
	public String toString(final String value) throws ValueConverterException {
		return "|" + value.replaceAll("(\\\\|\\|)", "\\\\$1");
	}

	public static void main(final String[] args) {
		TableCellValueConverter conv = new TableCellValueConverter();

		String string1 = "|\\ \\\\a Row \\\\ \\|";
		System.out.println(string1);
		String value1 = conv.toValue(string1, null);
		System.out.println(value1);
		String string2 = conv.toString(value1);
		System.out.println(string2);
	}
}
