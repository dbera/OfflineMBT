package nl.esi.xtext.lsp.server;

import org.eclipse.xtext.ide.server.ILanguageServerShutdownAndExitHandler;
import org.eclipse.xtext.ide.server.LaunchArgs;
import org.eclipse.xtext.ide.server.ServerModule;
import org.eclipse.xtext.ide.server.SocketServerLauncher;
import org.eclipse.xtext.util.IFileSystemScanner;
import org.eclipse.xtext.xbase.lib.ArrayExtensions;

import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;
import com.google.inject.util.Modules;

import nl.esi.xtext.lsp.impl.SaveJavaIoFileSystemScanner;

public class ServerLauncher {
	public static final String STDIO = "-stdio";
	public static final String WEB_SOCKET = "-ws";

	public static void main(String[] args) {
		new ServerLauncher().launch(args);
	}

	public void launch(String[] args) {
		if (ArrayExtensions.contains(args, STDIO)) {
			String prefix = ServerLauncher.class.getName();
			LaunchArgs launchArgs = org.eclipse.xtext.ide.server.ServerLauncher.createLaunchArgs(prefix, args);
			createServerLauncher(args).start(launchArgs);
		} else if (ArrayExtensions.contains(args, WEB_SOCKET)) {
			createWebSocketServerLauncher(args).launch(args);
		} else {
			createSocketServerLauncher(args).launch(args);
		}
	}

	protected org.eclipse.xtext.ide.server.ServerLauncher createServerLauncher(String[] args) {
		Injector injector = Guice.createInjector(Modules.combine(new SafeServerModule(), getServerModule()));
		return injector.getInstance(org.eclipse.xtext.ide.server.ServerLauncher.class);
	}

	protected WebSocketServerLauncher createWebSocketServerLauncher(String[] args) {
		return new WebSocketServerLauncher() {
			@Override
			protected Module getServerModule() {
				return Modules.combine(new RemoteServerModule(), ServerLauncher.this.getServerModule());
			}
		};
	}

	protected SocketServerLauncher createSocketServerLauncher(String[] args) {
		return new SocketServerLauncher() {
			@Override
			protected Module getServerModule() {
				return Modules.combine(new RemoteServerModule(), ServerLauncher.this.getServerModule());
			}
		};
	}

	protected com.google.inject.Module getServerModule() {
		return new ServerModule();
	}

	protected static class SafeServerModule extends AbstractModule {
		@Override
		protected void configure() {
			super.configure();

			bind(IFileSystemScanner.class).to(SaveJavaIoFileSystemScanner.class);
		}
	}
	
	protected static class RemoteServerModule extends SafeServerModule {
		@Override
		protected void configure() {
			super.configure();

			bind(ILanguageServerShutdownAndExitHandler.class).to(ILanguageServerShutdownAndExitHandler.NullImpl.class);
		}
	}
}
