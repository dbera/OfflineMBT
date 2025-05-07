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
package nl.asml.matala.bpmn4s;

public class Logging {

	/** Get the current line number.
	 * @return int - Current line number.
	 */
	private static int getLineNumber() {
	    return Thread.currentThread().getStackTrace()[3].getLineNumber();
	}

	/** Get the current file name.
	 * @return String - Current file name.
	 */
	private static String getFileName() {
	    return Thread.currentThread().getStackTrace()[3].getFileName();
	}

	public static void logInfo(String str) { System.out.println(String.format("[%s] %s", getLineNumber(), str)); }
	public static void logWarning(String str) { System.out.println(String.format("\u001B[33m[%s:%s] WARNING: %s \u001B[0m", getFileName(), getLineNumber(), str)); }
	public static void logError(String str) { System.out.println(String.format("\u001B[31m[%s:%s] ERROR: %s \u001B[0m", getFileName(), getLineNumber(), str)); }
	public static void logDebug(String str) { System.out.println(String.format("\u001B[35m[%s:%s] DEBUG: %s \u001B[0m", getFileName(), getLineNumber(), str)); }
	
}
