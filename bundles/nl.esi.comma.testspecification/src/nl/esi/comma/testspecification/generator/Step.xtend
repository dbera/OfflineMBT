package nl.esi.comma.testspecification.generator

import java.util.ArrayList
import java.util.List
import java.util.HashSet

class Step {
	public var String id = new String
	public var String type = new String
	public var String inputFile = new String
	public var List<KeyValue> parameters = new ArrayList<KeyValue>
	public var String variableName = new String
	public var String recordExp = new String
	
	
	def getId() { return id }
	def getType() { return type }
	def getInputFile() { return inputFile }
	def getParameters() { return parameters }
	def getVariableName() { return variableName }
	def getRecordExp() { return recordExp }
}


class KeyValue {
	public var key = new String
	public var value = new String
	public var refKey = new HashSet<String>
	public var refVal = new HashSet<String>
	
	def getKey() { return key }
	def getValue() { return value }
	def getRefKey() { return refKey }
	def getRefVal() { return refVal }
	
	def display() {
		System.out.println("	Key: " + key + "	Value: " + value )
		for(rk : refKey) System.out.println("	RefKey: " + rk )
		for(rv : refVal) System.out.println("	RefVal: " + rv )
	}
}

class JSONData {
	public var kvList = new ArrayList<KeyValue>
	def getKvList() { return kvList }
	def display() {
		for(elm : kvList)
			System.out.println(" JSON Key: " + elm.key + " -> value: " + elm.value )
	}
}