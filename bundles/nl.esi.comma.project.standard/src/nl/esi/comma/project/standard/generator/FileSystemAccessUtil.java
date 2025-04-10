package nl.esi.comma.project.standard.generator;

import java.io.File;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Objects;

import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.common.CommonPlugin;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.xtext.generator.IFileSystemAccess2;
import org.eclipse.xtext.util.RuntimeIOException;

public class FileSystemAccessUtil {
	public static final String ROOT_PATH = ".";

	private FileSystemAccessUtil() {
		// Empty
	}

	public static String toPath(URI uri) {
		return uri == null ? null : CommonPlugin.resolve(uri).toFileString();
	}

	public static URI getRootURI(IFileSystemAccess2 fsa) {
		return fsa.getURI(ROOT_PATH);
	}

	public static URI getRootURI(IFileSystemAccess2 fsa, String outputConfiguration) {
		return fsa.getURI(ROOT_PATH, outputConfiguration);
	}

	public static Iterable<String> list(IFileSystemAccess2 fsa, String path) {
		return list(fsa, fsa.getURI(path));
	}

	public static Iterable<String> list(IFileSystemAccess2 fsa, String path, String outputConfiguration) {
		return list(fsa, fsa.getURI(path, outputConfiguration));
	}

	private static Iterable<String> list(IFileSystemAccess2 fsa, URI uri) {
		// TODO: There should be a better way than going via java.io.File
		return Arrays.asList(new File(toPath(uri)).list());
	}

	public static Resource loadResource(IFileSystemAccess2 fsa, String fileName, ResourceSet resourceSet) {
		return resourceSet.getResource(fsa.getURI(fileName), true);
	}

	public static Resource loadResource(IFileSystemAccess2 fsa, String fileName, String outputConfiguration,
			ResourceSet resourceSet) {
		return resourceSet.getResource(fsa.getURI(fileName, outputConfiguration), true);
	}

	public static void refresh(IFileSystemAccess2 fsa) throws CoreException {
		if (ResourcesPlugin.getPlugin() == null) {
			return;
		}
		URI fsaURI = fsa.getURI(".");
		if (fsaURI.isPlatformResource()) {
			IResource fsaResource = ResourcesPlugin.getWorkspace().getRoot().findMember(fsaURI.toPlatformString(true),
					true);
			if (fsaResource != null) {
				fsaResource.refreshLocal(IResource.DEPTH_INFINITE, null);
			}
		}
	}

	public static IFileSystemAccess2 createFolderAccess(IFileSystemAccess2 fsa, String path) {
		return new FolderAccess(fsa, path);
	}

	private static class FolderAccess implements IFileSystemAccess2 {
		private final IFileSystemAccess2 delegate;
		private final String prefix;

		public FolderAccess(IFileSystemAccess2 delegate, String path) {
			this.delegate = delegate;
			this.prefix = path.endsWith("/") ? path : path + '/';
		}

		public void deleteFile(String fileName, String outputConfigurationName) {
			delegate.deleteFile(prefix + fileName, outputConfigurationName);
		}

		public void generateFile(String fileName, CharSequence contents) {
			delegate.generateFile(prefix + fileName, contents);
		}

		public URI getURI(String path, String outputConfiguration) {
			return delegate.getURI(prefix + path, outputConfiguration);
		}

		public void generateFile(String fileName, String outputCfgName, InputStream content) throws RuntimeIOException {
			delegate.generateFile(prefix + fileName, outputCfgName, content);
		}

		public void generateFile(String fileName, String outputConfigurationName, CharSequence contents) {
			delegate.generateFile(prefix + fileName, outputConfigurationName, contents);
		}

		public URI getURI(String path) {
			return delegate.getURI(prefix + path);
		}

		public void generateFile(String fileName, InputStream content) throws RuntimeIOException {
			delegate.generateFile(prefix + fileName, content);
		}

		public void deleteFile(String fileName) {
			delegate.deleteFile(prefix + fileName);
		}

		public boolean isFile(String path, String outputConfigurationName) throws RuntimeIOException {
			return delegate.isFile(prefix + path, outputConfigurationName);
		}

		public InputStream readBinaryFile(String fileName, String outputCfgName) throws RuntimeIOException {
			return delegate.readBinaryFile(prefix + fileName, outputCfgName);
		}

		public InputStream readBinaryFile(String fileName) throws RuntimeIOException {
			return delegate.readBinaryFile(prefix + fileName);
		}

		public CharSequence readTextFile(String fileName, String outputCfgName) throws RuntimeIOException {
			return delegate.readTextFile(prefix + fileName, outputCfgName);
		}

		public boolean isFile(String path) throws RuntimeIOException {
			return delegate.isFile(prefix + path);
		}

		public CharSequence readTextFile(String fileName) throws RuntimeIOException {
			return delegate.readTextFile(prefix + fileName);
		}

		@Override
		public int hashCode() {
			return Objects.hash(delegate, prefix);
		}

		@Override
		public boolean equals(Object obj) {
			if (this == obj)
				return true;
			if (obj == null)
				return false;
			if (getClass() != obj.getClass())
				return false;
			FolderAccess other = (FolderAccess) obj;
			return Objects.equals(delegate, other.delegate) && Objects.equals(prefix, other.prefix);
		}
	}
}
