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
package nl.asml.matala.server.api;


import java.nio.file.Path;
/**
 * FileServerApi interface for backend file operations.
 * 
 * <p>All paths are relative to the root folder and cannot escape it.
 * This interface is JSON-free; serialization is handled by the REST layer.
 */
public interface GeneratorApi {
	
	public static enum GenerationTarget {
		TESTS,
		SIMULATION;
		
		public String genName() {
			switch(this) {
				case TESTS: return "Tests";
				default: return "Simulation";
			}
		}
}
	
	/**
	 * Converts a bpmn using the relative path 
	 * @param path
	 * @return
	 * @throws ServerApiException
	 */
	public FileWriteResult generate(Path rootPath, String path, byte[] content, String taskName, GenerationTarget target) throws ServerApiException;

}