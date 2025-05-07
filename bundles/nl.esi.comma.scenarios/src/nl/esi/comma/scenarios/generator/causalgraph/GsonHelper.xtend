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
package nl.esi.comma.scenarios.generator.causalgraph

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonSerializer
import com.google.gson.JsonDeserializer
import java.lang.reflect.Type
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonParseException
import com.google.gson.JsonObject
import com.google.gson.JsonArray

class GsonHelper {
	
	static class DataSerializer implements JsonSerializer<NodeData> {
		
		override serialize(NodeData nodeData, Type arg1, JsonSerializationContext context) {
			var obj = new JsonObject
			val dataMap = new JsonArray
			nodeData.dataMap.entrySet.forEach[entry |
				var e = new JsonObject
				e.addProperty("key", entry.key)
				e.addProperty("value", entry.value)
				dataMap.add(e)
			]
			obj.add("dataMap", dataMap)
			return obj
		}
	}
	
	static class CausalGraphSerializer implements JsonSerializer<CausalGraph>, JsonDeserializer<CausalGraph> {
		val dataSerializer = new DataSerializer
		var gson = new Gson()
		override serialize(CausalGraph cg, Type arg1, JsonSerializationContext context) {
			val nodes = new JsonObject
			cg.nodes.stream().forEach[n |
				var nodeJson = new JsonObject
				nodeJson.addProperty("actionName", n.actionName)
				nodeJson.addProperty("init", n.init)
				if (n.changeType != null) {
					var changeTypes = new JsonArray
					for(changetype : n.changeType){
						changeTypes.add(changetype)
					}
					nodeJson.add("changeType", changeTypes)
				}
				
				val data = new JsonArray
				n.datas.forEach[d | data.add(dataSerializer.serialize(d, arg1, context))]
				nodeJson.add("data", data)
				var productSet = new JsonArray
				for(prod : n.productSet){
					productSet.add(prod)
				}
				nodeJson.add("productSet", productSet)
				nodes.add(n.actionName, nodeJson)
				nodeJson.add("testSet", gson.toJsonTree(n.scnIDs));
			]
			
			val edges = new JsonArray
			cg.edges.stream().forEach[e |
				var edgeJson = new JsonObject
				edgeJson.addProperty("source", e.src)
				edgeJson.addProperty("target", e.dst)
				if (e.changeType != null){
					edgeJson.addProperty("changeType", e.changeType)
				}
				var productSet = new JsonArray
				for(prod : e.productSet){
					productSet.add(prod)
				}
				edgeJson.add("productSet", productSet)
				edges.add(edgeJson)
			]
			
			var meta = new JsonObject
			meta.add("features", gson.toJsonTree(cg.features))
			
			var graph = new JsonObject
			graph.add("nodes", nodes)
			graph.add("edges", edges)
			graph.add("meta", meta)
			
			var root = new JsonObject
			root.add("graph", graph)
			return root
		}
		
		override deserialize(JsonElement arg0, Type arg1, JsonDeserializationContext arg2) throws JsonParseException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
	}
	
	def static String toJSON(CausalGraph graph, boolean pretty, CausalFootprint footprintA, CausalFootprint footprintB) {
		var gson = getGson(pretty)
		var root = gson.toJsonTree(graph).getAsJsonObject
		if (footprintA !== null && footprintB !== null) {
		    var meta = root.getAsJsonObject("graph").getAsJsonObject("meta");
		    meta.add("footprintA", gson.toJsonTree(footprintA));
            meta.add("footprintB", gson.toJsonTree(footprintB));
		}
		
		return gson.toJson(root)
	}
	
	def static Gson getGson(boolean pretty) {
		var builder = new GsonBuilder().serializeNulls
		builder.registerTypeAdapter(CausalGraph, new CausalGraphSerializer)
		if (pretty) { 
			builder = builder.setPrettyPrinting
		}
		return builder.create
	}
}