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
package nl.esi.comma.scenarios.generator.impactanalysis

import com.google.gson.GsonBuilder
import com.google.gson.TypeAdapter
import com.google.gson.stream.JsonReader
import com.google.gson.stream.JsonWriter
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class Reports {
	
	new(){
		
	}
	private static def createDateTimeJsonAdapter() {
		return new TypeAdapter<LocalDateTime>() {

			override read(JsonReader jsonReader) throws IOException {
				return LocalDateTime.parse(jsonReader.nextString())
			}

			override write(JsonWriter jsonWriter, LocalDateTime value) throws IOException {
				jsonWriter.value(DateTimeFormatter.ISO_LOCAL_DATE_TIME.format(value))
			}
		};

	}
	
	static def String toJson(ImpactAnalysisReport report) {
		return new GsonBuilder()
			.excludeFieldsWithoutExposeAnnotation()
			.setPrettyPrinting()
			.registerTypeAdapter(LocalDateTime, createDateTimeJsonAdapter())
			.create()
			.toJson(report);
	}
	
	def byte[] getHtmlTemplate() {
		var in = this.class.classLoader.getResourceAsStream("impactAnalysis.html")
		if (in !== null) {
			try {
				val ByteArrayOutputStream buf = new ByteArrayOutputStream()
				var int rByte
				while ((rByte = in.read()) != -1) {
					buf.write(rByte)
				}
				return buf.toByteArray()
			} catch (IOException e) {
				// fixme:
				e.printStackTrace
			}
		} else {
			System.err.println('Could not load the impactAnalysis.html template from the ' + Reports.toString + ' plugin')
		}

		return null;
	}
}