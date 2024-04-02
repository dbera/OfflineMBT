package nl.esi.comma.scenarios.tests.causalgraph

import com.google.inject.Inject
import java.util.ArrayList
import nl.esi.comma.scenarios.generator.causalgraph.GenerateCausalGraph
import nl.esi.comma.scenarios.scenarios.Scenarios
import nl.esi.comma.scenarios.tests.ScenariosInjectorProvider
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(typeof(XtextRunner))
@InjectWith(ScenariosInjectorProvider)
class CausalGraphGenSimpleTest {
	@Inject ParseHelper<Scenarios> parseHelper
	@Inject IScopeProvider scopeProvider
	
	//ResourceSet set
	InMemoryFileSystemAccess fsa
	
	@Before
	def void setup() {
		fsa = new InMemoryFileSystemAccess()
		var scnModel = parseHelper.parse('''
		feature-name "Feature: BasicTestWithoutData"
		feature-tag "@tag1" "@tag2"
		file-location ""
		Scenario s0 Hash "-1273492148"
			scenario-name "Scenario: Perform basic interaction A"
			scenario-tag "@tagA" "@tagB"
						
						Given Action a1
						When Action a2
						And Action a3
						Then Action a1
						When Action a2
						Then Action a3
		feature-name "Feature: BasicTestWithoutData"
		feature-tag "@tag1" "@tag2"
		file-location ""
		Scenario s1 Hash "-1273492147"
			scenario-name "Scenario: Perform basic interaction B"
			scenario-tag "@tagC" "@tagD"
			
						Given Action a4
						When Action a3
						Then Action a2
						When Action a5
						Then Action a6
						
		feature-name "Feature: BasicTestWithoutData"
		feature-tag "@tag1" "@tag2"
		file-location ""
		Scenario s2 Hash "-1273492146"
			scenario-name "Scenario: Perform basic interaction C"
			scenario-tag "@tagB" "@tagD"
						Given Action a5
						When Action a6
						Then Action a1
		''')
		var scnSources = new ArrayList<Scenarios>
		scnSources.add(scnModel)
		(new GenerateCausalGraph).generateCausalGraph(fsa, scopeProvider, scnSources, "SimpleWithoutData")
	}
	
	@Test
	def generateGraph(){
		val file = IFileSystemAccess::DEFAULT_OUTPUT +"..\\test-gen\\SpecFlowToScenarios\\SimpleWithoutData\\graph.scn"
		
		assertTrue(fsa.textFiles.containsKey(file))
		assertEquals(ExpectedGraph.ISimpleWithoutDataTest.toString, fsa.textFiles.get(file).toString)
	}
}