package nl.esi.comma.systemconfig.tests

import org.eclipse.xtext.testing.InjectWith
import org.junit.runner.RunWith
import org.eclipse.xtext.testing.XtextRunner
import nl.esi.comma.systemconfig.configuration.FeatureDefinition
import com.google.inject.Inject
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Test

@RunWith(XtextRunner)
@InjectWith(ConfigurationInjectorProvider)
class ConfigurationParsingTest {
	@Inject
	ParseHelper<FeatureDefinition> parseHelper
	
	@Test
	def void loadModel(){
		val result = parseHelper.parse('''
		Feature-list {
			bool FeatureA
			bool FeatureB
			bool FeatureC
		}
		
		Configuration configA {
			FeatureA,
			FeatureC
		}
		
		Configuration configB {
			FeatureB
		}
		
		Configuration configC {
			FeatureC
		}
		''')
		Assert.assertNotNull(result)
		Assert.assertTrue(result.eResource.errors.isEmpty)
	}
}
