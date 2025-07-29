package nl.esi.comma.causalgraph.conversion

import org.eclipse.xtext.common.services.DefaultTerminalConverters
import org.eclipse.xtext.conversion.IValueConverter
import org.eclipse.xtext.conversion.ValueConverter

class CausalGraphValueConverterService extends DefaultTerminalConverters {
    @ValueConverter(rule = "BODY")
    def IValueConverter<String> getBodyConverter() {
        return new BodyValueConverter();
    }
}