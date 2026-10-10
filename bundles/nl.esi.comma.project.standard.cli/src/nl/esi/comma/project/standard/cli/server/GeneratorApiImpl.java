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
package nl.esi.comma.project.standard.cli.server;

import static nl.asml.matala.server.rest.ServerUtil.validateAndNormalize;
import static nl.esi.comma.project.standard.cli.Main.generateFiles;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

import nl.asml.matala.server.api.FileServerApi;
import nl.asml.matala.server.api.FileWriteResult;
import nl.asml.matala.server.api.GeneratorApi;
import nl.asml.matala.server.api.ServerApiException;

/**
 * File-system-backed implementation of {@link FileServerApi}. All paths are
 * validated to stay within the configured root directory.
 */
public class GeneratorApiImpl implements GeneratorApi {

	@Override
	public FileWriteResult generate(Path rootPath, String path, byte[] content, String taskName, GenerationTarget target)
			throws ServerApiException {
		try {
			var contentFile = validateAndNormalize(rootPath, path);
			var prjFile = Path.of(contentFile.toString().replaceFirst("(.*\\.)\\w+", "$1.prj"));
			var contentFileName = contentFile.getFileName().toString();
			Files.createDirectories(contentFile.getParent());
			Files.write(contentFile, content, StandardOpenOption.CREATE, StandardOpenOption.WRITE,
					StandardOpenOption.TRUNCATE_EXISTING);
			Files.write(prjFile, generateProjectFile(target, contentFileName, taskName), StandardOpenOption.CREATE,
					StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING);

			generateFiles(new String[] { "I", prjFile.toString(), "o", rootPath.toString() });
			return new FileWriteResult(path, "Generated Successfully", true);
		} catch (IOException e) {
			return new FileWriteResult(path, e.getMessage(), false);
		}
	}

	private byte[] generateProjectFile(GenerationTarget target, String targetFileName, String taskName) {
		var type = targetFileName.replaceFirst(".*\\.(\\w+)", "$1").equalsIgnoreCase("bpmn") ? "bpmn" : "product";
		return String.format("""
			Project project {
			    Generate %s {
			        %s {
			          %s-file "%s"
			        }
			    }
			}
				""", target.genName(), taskName, type, targetFileName).getBytes(StandardCharsets.UTF_8);
	}
}