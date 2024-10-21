package nl.esi.xtext.lsp.server;

import org.eclipse.xtext.ide.server.ILanguageServerShutdownAndExitHandler;
import org.eclipse.xtext.ide.server.LaunchArgs;
import org.eclipse.xtext.ide.server.ServerModule;
import org.eclipse.xtext.ide.server.SocketServerLauncher;
import org.eclipse.xtext.xbase.lib.ArrayExtensions;

import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;
import com.google.inject.util.Modules;

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
		Injector injector = Guice.createInjector(getServerModule());
		return injector.getInstance(org.eclipse.xtext.ide.server.ServerLauncher.class);
	}

	protected WebSocketServerLauncher createWebSocketServerLauncher(String[] args) {
		return new WebSocketServerLauncher() {
			@Override
			protected Module getServerModule() {
				return Modules.combine(new ServerShutdownModule(), ServerLauncher.this.getServerModule());
			}
		};
	}

	protected SocketServerLauncher createSocketServerLauncher(String[] args) {
		return new SocketServerLauncher() {
			@Override
			protected Module getServerModule() {
				return Modules.combine(new ServerShutdownModule(), ServerLauncher.this.getServerModule());
			}
		};
	}

	protected com.google.inject.Module getServerModule() {
		return new ServerModule();
	}

	protected static class ServerShutdownModule extends AbstractModule {
		@Override
		protected void configure() {
			bind(ILanguageServerShutdownAndExitHandler.class).to(ILanguageServerShutdownAndExitHandler.NullImpl.class);
		}
	}
}
