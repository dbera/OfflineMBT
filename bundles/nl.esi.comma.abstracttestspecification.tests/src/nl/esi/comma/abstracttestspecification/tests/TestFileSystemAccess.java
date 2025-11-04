package nl.esi.comma.abstracttestspecification.tests;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import org.eclipse.emf.common.util.URI;
import org.eclipse.xtext.generator.IFileSystemAccess2;
import org.eclipse.xtext.util.RuntimeIOException;
import org.eclipse.xtext.util.StringInputStream;


public class TestFileSystemAccess implements IFileSystemAccess2 {
	private final Path basePath;
	
	public TestFileSystemAccess(Path basePath) {
		this.basePath = basePath.toAbsolutePath();
	}
	
	private Path resolve(String path) {
		return basePath.resolve(path);
	}
	
	@Override
	public void generateFile(String fileName, CharSequence contents) {
		generateFile(fileName, new StringInputStream(contents.toString()));
	}

	@Override
	public void generateFile(String fileName, String outputConfigurationName, CharSequence contents) {
		generateFile(fileName, contents);
	}

	@Override
	public void deleteFile(String fileName) {
		try {
			Files.delete(resolve(fileName));
		} catch (IOException e) {
			throw new RuntimeIOException(e);
		}
	}

	@Override
	public void deleteFile(String fileName, String outputConfigurationName) {
		deleteFile(fileName);
	}

	@Override
	public URI getURI(String path, String outputConfiguration) {
		return getURI(path);
	}

	@Override
	public URI getURI(String path) {
		return URI.createFileURI(resolve(path).toString());
	}

	@Override
	public void generateFile(String fileName, String outputCfgName, InputStream content) throws RuntimeIOException {
		generateFile(fileName, content);
	}

	@Override
	public void generateFile(String fileName, InputStream content) throws RuntimeIOException {
		Path path = resolve(fileName);
		try {
			Files.createDirectories(path.getParent());
			Files.copy(content, path, StandardCopyOption.REPLACE_EXISTING);
		} catch (IOException e) {
			throw new RuntimeIOException(e);
		}
	}

	@Override
	public InputStream readBinaryFile(String fileName, String outputCfgName) throws RuntimeIOException {
		return readBinaryFile(fileName);
	}

	@Override
	public InputStream readBinaryFile(String fileName) throws RuntimeIOException {
		try {
			return Files.newInputStream(resolve(fileName));
		} catch (IOException e) {
			throw new RuntimeIOException(e);
		}
	}

	@Override
	public CharSequence readTextFile(String fileName, String outputCfgName) throws RuntimeIOException {
		return readTextFile(fileName);
	}

	@Override
	public CharSequence readTextFile(String fileName) throws RuntimeIOException {
		try {
			return Files.readString(resolve(fileName));
		} catch (IOException e) {
			throw new RuntimeIOException(e);
		}
	}

	@Override
	public boolean isFile(String path, String outputConfigurationName) throws RuntimeIOException {
		return isFile(path);
	}

	@Override
	public boolean isFile(String path) throws RuntimeIOException {
		return Files.isRegularFile(resolve(path));
	}
}
