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
package nl.esi.comma.causalgraph.conversion

import org.eclipse.xtext.conversion.IValueConverter
import org.eclipse.xtext.conversion.ValueConverterException
import org.eclipse.xtext.nodemodel.INode

class BodyValueConverter implements IValueConverter<String> {
    override toString(String value) throws ValueConverterException {
        return if (value !== null) '«' + value.replace('»', '»»') + '»';
    }

    override toValue(String string, INode node) throws ValueConverterException {
        return if (string === null) {
            null;
        } else if (string.length >= 2) {
            string.substring(1, string.length - 1).replace('»»', '»')
        } else {
            ''
        }
    }
}