package nl.esi.comma.testspecification.abstspec.generator;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import nl.esi.comma.testspecification.testspecification.Binding;
import nl.esi.comma.testspecification.testspecification.TSJsonArray;
import nl.esi.comma.testspecification.testspecification.TSJsonBool;
import nl.esi.comma.testspecification.testspecification.TSJsonFloat;
import nl.esi.comma.testspecification.testspecification.TSJsonLong;
import nl.esi.comma.testspecification.testspecification.TSJsonMember;
import nl.esi.comma.testspecification.testspecification.TSJsonObject;
import nl.esi.comma.testspecification.testspecification.TSJsonString;
import nl.esi.comma.testspecification.testspecification.TSJsonValue;

public class BindingComparator implements Comparator<Binding>{
	
	CompareTSJsonValues compareTsjson = new CompareTSJsonValues();
	
	@Override
	public int compare(Binding o1, Binding o2) {
		return compareTsjson.compare(o1.getJsonvals(), o2.getJsonvals());
	}
}

class CompareTSJsonValues implements Comparator<TSJsonValue>{
	
	@Override 
    public int compare(TSJsonValue o1, TSJsonValue o2) {
        if (o1 instanceof TSJsonString && o2 instanceof TSJsonString) {
        	String v1 = ((TSJsonString) o1).getValue();
        	String v2 = ((TSJsonString) o2).getValue();
        	return v1.compareTo(v2);
        }
        if (o1 instanceof TSJsonBool && o2 instanceof TSJsonBool) {
        	boolean v1 = ((TSJsonBool) o1).isValue();
        	boolean v2 = ((TSJsonBool) o2).isValue();
	        return Boolean.compare(v1, v2);
        }
        if (o1 instanceof TSJsonFloat && o2 instanceof TSJsonFloat) {
        	double v1 = ((TSJsonFloat) o1).getValue();
        	double v2 = ((TSJsonFloat) o2).getValue();
        	return Double.compare(v1, v2);
        }
        if (o1 instanceof TSJsonLong && o2 instanceof TSJsonLong) {
        	double v1 = ((TSJsonFloat) o1).getValue();
        	double v2 = ((TSJsonFloat) o2).getValue();
        	return Double.compare(v1, v2);
        }
        if (o1 instanceof TSJsonObject && o2 instanceof TSJsonObject){
        	Map<String, List<TSJsonMember>> v1 = ((TSJsonObject) o1).getMembers().stream().collect(Collectors.groupingBy(TSJsonMember::getKey));
        	Map<String, List<TSJsonMember>> v2 = ((TSJsonObject) o2).getMembers().stream().collect(Collectors.groupingBy(TSJsonMember::getKey));
        	if(!v1.keySet().equals(v2.keySet())) return -1;
        	for (String k1 : v1.keySet()) {
        		if (v1.get(k1).size() != 1) return -1;
        		if (v2.get(k1).size() != 1) return -1;
        		TSJsonMember i1 = v1.get(k1).getFirst();
        		TSJsonMember i2 = v2.get(k1).getFirst();
        		return this.compare(i1.getValue(), i2.getValue());
            }
        }
        if (o1 instanceof TSJsonArray && o2 instanceof TSJsonArray){
        	List<TSJsonValue> a1 = ((TSJsonArray) o1).getValues().stream().collect(Collectors.toList());
        	List<TSJsonValue> a2 = ((TSJsonArray) o2).getValues().stream().collect(Collectors.toList());
                for (TSJsonValue i1 : a1) {
                    var somethingEqual = false;
                    for (TSJsonValue i2 : a2) {
                    	if (compare(i1,i2) == 0){
                    	    somethingEqual = true; break;
                    	}
                    }
                    if (!somethingEqual) return -1;
                }
                return 0;
        }
        return -1;
    }
}
