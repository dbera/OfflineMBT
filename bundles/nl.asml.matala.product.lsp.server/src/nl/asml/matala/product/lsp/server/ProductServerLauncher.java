package nl.asml.matala.product.lsp.server;

import org.eclipse.lsp4j.SetTraceParams;
import org.eclipse.lsp4j.WorkDoneProgressCancelParams;
import org.eclipse.xtext.ide.server.LanguageServerImpl;

import com.google.inject.AbstractModule;
import com.google.inject.Module;
import com.google.inject.util.Modules;

import nl.esi.xtext.lsp.server.ServerLauncher;

public class ProductServerLauncher extends ServerLauncher {
	public static void main(String[] args) {
		new ProductServerLauncher().launch(args);
	}

	@Override
	protected Module getServerModule() {
		return Modules.combine(new MonacoServerModule(), super.getServerModule());
	}

	private static class MonacoServerModule extends AbstractModule {
		@Override
		protected void configure() {
			bind(LanguageServerImpl.class).to(MonacoLanguageServerImpl.class);
		}
	}

	private static class MonacoLanguageServerImpl extends LanguageServerImpl {
		@Override
		public void cancelProgress(WorkDoneProgressCancelParams params) {
			// Ignore, but trace
			System.err.println(String.format("cancelProgress(%s)", params));
		}

		@Override
		public void setTrace(SetTraceParams params) {
			// Ignore, but trace
			System.err.println(String.format("setTrace(%s)", params));
		}
	}
}
