package nl.esi.comma.causalgraph.generator;

import java.util.Arrays;
import java.util.stream.Collectors;

public class StringHelper 
{
	String makeCaps(String input) {
	    if (input == null || input.isEmpty()) {
	        return null;
	    }

	    return Arrays.stream(input.split("\\s+"))
	      .map(word -> Character.toUpperCase(word.charAt(0)) + word.substring(1))
	      .collect(Collectors.joining(" "));
	}
}
