/**
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
package nl.esi.comma.constraints.generator.visualize

import java.util.HashSet
import java.util.Set
import nl.esi.comma.constraints.dashboard.DashboardHelper

class AssistantGraph {
	Set<AssistantNode> nodes
	Set<AssistantEdge> edges
	
	new(){
		nodes = new HashSet<AssistantNode>
		edges = new HashSet<AssistantEdge>
	}
	
	def computeMissingConstraints(){
		//check precedence
		for (n : nodes){
			var missingPast = false
			if (checkPrecedence(n)){
				missingPast = missingPast(n)
			}
			if (missingPast){
				n.addMissingConstr("Past")
			}
		}
	}
	
	def missingPast(AssistantNode n){
		var missingPast = true
		var targetEdges = getEdgesForTarget(n.label)
		for (e : targetEdges){
			if(e.type.equals(ArrowType.left)||e.type.equals(ArrowType.dashedLeft)){
				missingPast = false
			}
			if(e.type.equals(ArrowType.both)||e.type.equals(ArrowType.dashedBoth)){
				if(e.label.startsWith("Succ")||e.label.startsWith("AltSucc")||e.label.startsWith("ChSucc")){//only these three constraints requires a step in the past
					missingPast = false
				}
			}
		}
		return missingPast
	}
	
	def checkPrecedence(AssistantNode n){
		var checkPrecedence = false
		if (!n.init){//initial step does not require precedence
			var targetEdges = getEdgesForTarget(n.label)
			for (e: targetEdges){
				if (e.type === ArrowType.right || e.type === ArrowType.dashedRight){
					checkPrecedence = true
				}
			}
			var sourceEdges = getEdgesForSource(n.label)
			for (e: sourceEdges){
				if (e.type === ArrowType.right || e.type === ArrowType.dashedRight){
					checkPrecedence = true
				}
				if (e.type === ArrowType.left || e.type === ArrowType.dashedLeft){
					checkPrecedence = true
				}
			}
		}
		return checkPrecedence
	}
	
	def getEdgesForSource(String source){
		var selectedEdges = new HashSet<AssistantEdge>
		for (e : edges){
			if(e.source.equals(source)){
				selectedEdges.add(e)
			}
		}
		return selectedEdges
	}
	
	def getEdgesForTarget(String target){
		var selectedEdges = new HashSet<AssistantEdge>
		for (e : edges){
			if(e.target.equals(target)){
				selectedEdges.add(e)
			}
		}
		return selectedEdges
	}
	
	def addEdge(String source, String target, String label, ArrowType type){
		if(!containsEdge(source, target, label)){
			var newEdge = new AssistantEdge(source, target, type, label)
			edges.add(newEdge)
		}
	}
	
	def containsEdge(String src, String tgt, String label) {
		for(edge:edges){
			if(edge.source.equals(src) 
				&& edge.target.equals(tgt)
				&& edge.label.equals(label)){
					return true
			}
		}
		return false
	}
	
	def addNode(String label){
		var n = getNode(label)
		if (n === null){
			var newNode = new AssistantNode(label)
			nodes.add(newNode)
		}
	}
	
	def addNode(String label, boolean init, boolean end){
		var n = getNode(label)
		if (n === null){
			var newNode = new AssistantNode(label)
			newNode.init = init
			newNode.end = end
			nodes.add(newNode)
		} else {
			n.init = init
			n.end = end
		}
	}
	
	def getNode(String label){
		for(node:nodes){
			if(node.label.equals(label)){
				return node
			}
		}
		return null
	}
	
	def getNodes(){
		return this.nodes.toList
	}
	
	def getEdges(){
		return this.edges.toList
	}
	
	def String toJSON(boolean pretty){
		return GsonHelper.toJSON(this, pretty)
	}
	
	def byte[] toHTML(){
		var byte[] result = null
		result = DashboardHelper.getHTML(this.toJSON(false));
		return result
	}
}