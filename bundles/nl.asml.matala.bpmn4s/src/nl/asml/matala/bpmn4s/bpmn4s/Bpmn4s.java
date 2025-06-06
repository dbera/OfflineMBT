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
package nl.asml.matala.bpmn4s.bpmn4s;

import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;


class MsgQueue extends Element {
	MsgQueue() {
		super(ElementType.MSGQUEUE);
	}
}


// Element
//	|---- ActionNode
//	|		|---- Component
//	|		|---- Activity
//	|		|---- Task
//	|		|---- Event
//	|		|---- Gate
//	|---- DataNode
//	|		|---- DataStore
//	|		|---- MsgQueue
//	|---- 
//

public class Bpmn4s {
	
	public String name = "";
	public AbstractMap<String, Element> 		elements	= new HashMap<String, Element>();
	public List<Edge> 							edges 		= new ArrayList<Edge>();
	public AbstractMap<String, Bpmn4sDataType> 	dataSchema  = new HashMap<String, Bpmn4sDataType>();
	public int depthLimit = 100;
	private int numOfTests = 1;
	
	public Boolean isNode (String id) {
		return elements.containsKey(id);
	}
	
	public Boolean isComponent(String id) {
		return elements.containsKey(id) && elements.get(id).getType() == ElementType.COMPONENT;
	}
	
	public Boolean isComponent(Element elem) {
		return elem.getType() == ElementType.COMPONENT;
	}
	
	public Boolean isActivity(String id) {
		return elements.containsKey(id) && elements.get(id).getType().equals(ElementType.ACTIVITY);
	}
	
	public Boolean isTask(String id) {
		return elements.containsKey(id) && elements.get(id).getType().equals(ElementType.TASK);
	}
	
	public Boolean isRunTask(String id) {
		return elements.containsKey(id) && elements.get(id).getSubType().equals(ElementType.RUN_TASK);
	}

	public Boolean isAssertTask(String id) {
		return elements.containsKey(id) && elements.get(id).getSubType().equals(ElementType.ASSERT_TASK);
	}
	
	public Boolean isComposeTask(String id) {
		return elements.containsKey(id) && elements.get(id).getSubType().equals(ElementType.COMPOSE_TASK);
	}	
	
	public Boolean isExecutionTask(String id) {
		return isRunTask(id) || isAssertTask(id) || isComposeTask(id);
	}

	public Boolean isAnyTask(String id) {
		return isTask(id) || isRunTask(id) || isAssertTask(id) || isComposeTask(id);
	}
	
	public Boolean isEvent(String id) {
		return elements.containsKey(id) && (elements.get(id).getType().equals(ElementType.START_EVENT) ||
				elements.get(id).getType().equals(ElementType.END_EVENT)); 
	}
	
	public boolean isStartEvent(String id) {
		return elements.containsKey(id) && (elements.get(id).getType().equals(ElementType.START_EVENT)); 
	}
	
	public boolean isEndEvent(String id) {
		return elements.containsKey(id) && (elements.get(id).getType().equals(ElementType.END_EVENT)); 
	}
		
	public Boolean isGate(String name) {
		return elements.containsKey(name) && (elements.get(name).getType().equals(ElementType.AND_GATE) ||
				elements.get(name).getType().equals(ElementType.XOR_GATE)); 
	}
	
	public Boolean isXor(String id) {
		return isNode(id) && elements.get(id).getType().equals(ElementType.XOR_GATE); 
	}
	
	public Boolean isForkGate(String id) {
		return isGate(id) && elements.get(id).getFlowOutputs().size() > 1; 
	}
	
	public Boolean isMergeGate(String id) {
		return isGate(id) && elements.get(id).getFlowInputs().size() > 1; 
	}

	public Boolean isAnd(String name) {
		return isNode(name) && elements.get(name).getType().equals(ElementType.AND_GATE); 
	}
	
	public Boolean isData (String id) {
		return elements.get(id) != null && 
				(elements.get(id).getType() == ElementType.DATASTORE || 
				 elements.get(id).getType() == ElementType.MSGQUEUE);
	}
	
	public Boolean isReferenceData (String id) {
		return isData(id) && getElementById(id).isReferenceData();
	}
	
	public Element getElementById(String id) {
		return elements.get(id);
	}
	
	public void setName(String _name) {
		name = _name;
	}
	
	public String getName() {
		return name;
	}
	
	public void addElement (String id, Element elem) {
		this.elements.put(id, elem);
	}
	
	public void addEdge(Edge e) {
		edges.add(e);
	}
	
	public void associateFlowEdge(Edge e) {
		if (elements.containsKey(e.getSrc())) {
			Element node = elements.get(e.getSrc());
			node.flowOutputs.add(e);
		}
		if (elements.containsKey(e.getTar())) {
			Element node = elements.get(e.getTar());
			node.flowInputs.add(e);
		}
	}
	
	public void associateDataEdge(Edge e) {
		if (elements.containsKey(e.getSrc())) {
			Element node = elements.get(e.getSrc());
			node.dataOutputs.add(e);
		}
		if (elements.containsKey(e.getTar())) {
			Element node = elements.get(e.getTar());
			node.dataInputs.add(e);
		}
	}
	
	@Override
	public String toString() {
		String result = String.format("A bpmn4s model named '%s'.\n", name);
		result += String.format("The model has %s elements:", elements.size());
		for (Element value: elements.values()) {
			result += String.format("\n%s", value.toString());
		}
		return result;
	}
	
	
	public Element getStartEvent(Element c) {
		return getEvent(c, ElementType.START_EVENT);
	}
	
	public Element getEndEvent(Element c) {
		return getEvent(c, ElementType.END_EVENT);
	}
	
	private Element getEvent(Element c, ElementType et) {
		for (Element e: this.elements.values()) {
			if(e.getType() == et && e.getParent() == c.getId()){
				return e;
			}
		}
		return null; 
	}

	public void setDepthLimit (int limit) {
		this.depthLimit = limit;
	}
	
	public int getDepthLimit() {
		return depthLimit;
	}
	
	public void setNumOfTests(int numOfTests) {
		this.numOfTests  = numOfTests;
	}
	
	public int getNumOfTests() {
		return this.numOfTests;
	}
	
	public boolean componentDefinesContext (String id) {
		return this.isComponent(id) && this.getElementById(id).context.isDefined();
	}
}
