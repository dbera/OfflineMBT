package nl.esi.comma.abstracttestspecification.generator.to.bpmn;

import java.util.List;

public class DatastoreDescriptor extends ElementDescriptor {

	public List<String> consumers;
	public String producer;

	public DatastoreDescriptor(String id,String lane, String producer, List<String> consumers) {
    	super(id,lane);
        this.producer = producer;
        this.consumers = consumers;
    }
}