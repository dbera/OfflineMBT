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