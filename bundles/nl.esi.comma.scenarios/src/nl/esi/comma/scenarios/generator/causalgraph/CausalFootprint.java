package nl.esi.comma.scenarios.generator.causalgraph;

import java.util.HashMap;
import java.util.List;

import nl.esi.comma.scenarios.scenarios.Activity;
import nl.esi.comma.scenarios.scenarios.Scenarios;

public class CausalFootprint {
	public final HashMap<String, HashMap<String, Integer>> table = new HashMap<String, HashMap<String, Integer>>(); 
	public final HashMap<String, Integer> occurences = new HashMap<String, Integer>();

	public CausalFootprint(List<Scenarios> scenariosList) {
		computeTable(scenariosList);
	}
	
	private void computeTable(List<Scenarios> scenariosList) {
		for (var scenarios : scenariosList) {
			for (var scenario : scenarios.getSpecFlowScenarios()) {
				Activity previous = null;
				for (var event : scenario.getEvents()) {
					if (previous != null) {
						addDirectlyFollows(previous, event);
					}
					previous = event;
				}
			}
		}
	}

	private void addDirectlyFollows(Activity activityA, Activity activityB) {
		addActivity(activityA);
		addOccurence(activityA);
		addActivity(activityB);
		var entry = table.get(activityA.getName());
		entry.put(activityB.getName(), entry.get(activityB.getName()) + 1);
	}
	
	private void addOccurence(Activity activity) {
		var name = activity.getName();
		if (!occurences.containsKey(name)) occurences.put(name, 0);
		occurences.put(name, occurences.get(name) + 1);
	}
	
	private void addActivity(Activity activity) {
		var name = activity.getName();
		if (!table.containsKey(name)) {
			var map = new HashMap<String, Integer>();
			map.put(name, 0);
			for (var entry : table.entrySet()) {
				map.put(entry.getKey(), 0);
				entry.getValue().put(name, 0);
			}
			table.put(name, map);
		}
	}
}
