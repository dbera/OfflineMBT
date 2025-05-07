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

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonArray
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonDeserializer
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonParseException
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import java.lang.reflect.Type

class GsonHelper {
	
	static class DependencyGraphSerializer implements JsonSerializer<AssistantGraph>, JsonDeserializer<AssistantGraph> {

		override serialize(AssistantGraph ag, Type arg1, JsonSerializationContext context) {
			val nodes = new JsonObject
			ag.nodes.stream().forEach[n|
				var nodeJson = new JsonObject
				nodeJson.addProperty("name", n.label)
				if (n.missingConstr.size > 0){
					var missing = new JsonArray
					for (constr: n.missingConstr){
						missing.add(constr)
					}
					nodeJson.add("missing", missing)
				}
				nodes.add(n.label, nodeJson)
			]
			
			val edges = new JsonArray 
			ag.edges.stream().forEach[e |
				var edgeJson = new JsonObject
				edgeJson.addProperty("name", e.label)
				edgeJson.addProperty("source", e.source)
				edgeJson.addProperty("target", e.target)
				edgeJson.addProperty("type", e.type.name)
				edges.add(edgeJson)
			]
			var graph = new JsonObject
			graph.add("nodes", nodes)
			graph.add("edges", edges)
			
			var root = new JsonObject
			root.add("graph", graph)
			return root
		}
		
		override deserialize(JsonElement arg0, Type arg1, JsonDeserializationContext arg2) throws JsonParseException {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
	}
	def static String toJSON(AssistantGraph graph, boolean pretty){
		var gson = getGson(pretty)
		var root = gson.toJsonTree(graph).getAsJsonObject
		return gson.toJson(root)
	}
	
	def static Gson getGson(boolean pretty) {
		var builder = new GsonBuilder().serializeNulls
		builder.registerTypeAdapter(AssistantGraph, new DependencyGraphSerializer)
		if (pretty) { 
			builder = builder.setPrettyPrinting
		}
		return builder.create
	}
}