package nl.esi.comma.abstracttestspecification.generator.to.bpmn;

import java.util.List;

public class DataInstanceDescriptor extends ElementDescriptor{

	 public String dataStore;
	 public String producer;
	 public String context;
	 public List<String> consumers;
	
	 public DataInstanceDescriptor(String id,String lane,String original, String producerName, String context, List<String> consumers) {
		 super(id,lane);   
		 this.dataStore = original;
	     this.producer = producerName;
	     this.context = context;
	     this.consumers = consumers;
	    }

}
