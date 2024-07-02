package nl.esi.comma.constraints.dashboard;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

public class DashboardHelper {
	public static byte[] getHTML(String report) throws IOException {
		var in = DashboardHelper.class.getClassLoader().getResourceAsStream("constraints_dashboard.html");
		var bytes = in.readAllBytes();
		
		// Find where the %REPORT% is
		var placeholder = "\"%REPORT%\"".getBytes(StandardCharsets.UTF_8);
		var placeholderStart = 0;
		var placeholderIndex = 0;
		for (int i = 0; i < bytes.length; i++) {
			if (bytes[i] == placeholder[placeholderIndex]) {
				if (placeholderIndex == 0) {
					placeholderStart = i;
				} else if (placeholderIndex == placeholder.length - 1) {
					break;
				}
				
				placeholderIndex++;
			} else {
				placeholderIndex = 0;
			}
		}
		
		var stream = new ByteArrayOutputStream();
	    stream.write(Arrays.copyOfRange(bytes, 0, placeholderStart));
	    stream.write(report.getBytes());
	    stream.write(Arrays.copyOfRange(bytes, placeholderStart + placeholder.length, bytes.length));
		return stream.toByteArray();
	}

}
