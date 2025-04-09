package nl.asml.matala.product.mcrl2

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.HashSet
import nl.esi.comma.types.types.SimpleTypeDecl

class mCRL2 {
	public var places = new ArrayList<Place>
	public var transitions = new ArrayList<Transition>
	public var input_arcs = new HashMap<String,List<String>>  // transition -> list of places
	public var output_arcs = new HashMap<String,List<String>> // transition -> list of places
	public var map_transition_assertions = new HashMap<String,List<String>> // transition -> list of places to assert on
	public var arc_expressions = new ArrayList<ArcExpression>
	public var guard_expressions = new HashMap<String,String> // transition -> expression
	public var internal_places = new ArrayList<Place>
	public var init_place_expression_map = new HashMap<String, List<String>>
	
	def add_to_map_transition_assertions(String tname, String assertion_place) {
		if(map_transition_assertions.keySet.contains(tname)) {
			if(!map_transition_assertions.get(tname).contains(assertion_place)) {
				map_transition_assertions.get(tname).add(assertion_place)
			}
		}
		else {
			map_transition_assertions.put(tname, new ArrayList<String>)
			map_transition_assertions.get(tname).add(assertion_place)
		}
	}
	
	def generatePlaceInitializationText() {
		return 
		'''
		«FOR k : init_place_expression_map.keySet SEPARATOR ''','''»
			"«k.trim»": [
			«FOR elm : init_place_expression_map.get(k) SEPARATOR ''','''»
					«"    "»«elm.trim»
			«ENDFOR»
			]
		«ENDFOR»
		'''
	}
	
	def add_to_init_place_expression_map(String p, String e) {
		if(init_place_expression_map.keySet.contains(p)) 
			init_place_expression_map.get(p).add(e)
		else{
			var lst = new ArrayList<String>
			lst.add(e)
			init_place_expression_map.put(p,lst)
		}
	}
		
	def is_internal_place(String p) {
		for(ip : internal_places) {
			if(ip.name.equals(p)) return true
		}
		return false
	}
	
	// TODO validate all entry in input and output arcs 
	// have corresponding expression in arc_expressions. Risk of null pointer!
	def get_expression(String t, String p, PType type) {
		for(ae : arc_expressions) {
			if(ae.areEqual(t,p,type)) return ae
		}
		return null
	}
	
	def add_expression(String t, String p, String expTxt, PType type, ArrayList<Constraint> constraints) {
		arc_expressions.add(new ArcExpression(t,p,expTxt,type, constraints))
	}
	
	def add_guard_expression(String t, String txt) {
		guard_expressions.put(t,txt)
	}
		
	def display() {
		System.out.println("*************** mCRL2 ***************")
		System.out.println(" > Places ")
		for(p : places){
			System.out.println("	> name: " + p.name + " block-name: " + p.bname + " type: " + p.type.toString)
		}
		System.out.println(" > Transition ")
		for(t : transitions){
			if(guard_expressions.containsKey(t.name))
				System.out.println("	> name: " + t.name + " block-name: " + t.bname + " guard: " + guard_expressions.get(t.name))
			else System.out.println("	> name: " + t.name + " block-name: " + t.bname)
		}
		System.out.println(" > Input Arcs ")
		for(k : input_arcs.keySet) {
			System.out.println("	> places: " + input_arcs.get(k) + "  transition: " + k)
		}
		System.out.println(" > Output Arcs ")
		for(k : output_arcs.keySet) {
			System.out.println("	> transition: " + k + "  places: " + output_arcs.get(k))
		}
		
		System.out.println(" > Constraints ")
		for(e : arc_expressions) {
			for(c : e.constraints) {
				System.out.println("	> transition: " + e.t + "  place: " + e.p + "  direction: " + e.type)
				System.out.println("	> name: " + c.name + "  constraint: " + c.txt)
			}
		}
		System.out.println(" > init_func: ")
		for(k: init_place_expression_map.keySet) {
			System.out.println("	> " + k)
			for(elm: init_place_expression_map.get(k)) {
				System.out.println("		> " + elm)
			}
		}
		System.out.println("***********************************")
	}
	
	def add_input_arc(String t, String p) {
		if(input_arcs.keySet.contains(t)) { 
			if(!input_arcs.get(t).contains(p)) {
				input_arcs.get(t).add(p)
			}
		}
		else { 
			input_arcs.put(t, new ArrayList<String>) 
			input_arcs.get(t).add(p)
		}
	}
	
	def add_output_arc(String t, String p) {
		if(output_arcs.keySet.contains(t)) { 
			if(!output_arcs.get(t).contains(p)) {
				output_arcs.get(t).add(p)
			}
		}
		else { 
			output_arcs.put(t, new ArrayList<String>) 
			output_arcs.get(t).add(p)
		}
	}
	
	def getPlace(String bname, String name) { 
		for(pl : places)
			if(pl.name.equals(name) && pl.bname.equals(bname))
				return pl
		throw new RuntimeException
	}
	
	def getTransition(String bname, String name) { 
		for(tr : transitions)
			if(tr.name.equals(name) && tr.bname.equals(bname))
				return tr
		throw new RuntimeException
	}
	
	def isPresent(Place p, List<Place> lp) {
		for(elm : lp) { if(elm.name.equals(p.name)) return true }
		return false
	}
	
	def getPlacesMcrl2() {
		var lp = new ArrayList<Place>
		for(p : places) { if(!isPresent(p,lp)) lp.add(p) }
		return
		'''
		«FOR p : lp SEPARATOR ''','''»
		    «generateMcrl2Place(p)»
		«ENDFOR»
		'''
	}
	
	def getTransitionsMcrl2() {
		return
		'''
		«FOR t : transitions SEPARATOR ''','''»
			"«t.name»": {
				"pre": [
					«IF input_arcs.keySet.contains(t.name)»
						«FOR p : input_arcs.get(t.name) SEPARATOR ''','''»
							"«p»"
						«ENDFOR»
					«ENDIF»
				],
				"guard": "«guard_expressions.get(t.name)»",
				"post": {
					«IF output_arcs.keySet.contains(t.name)»
						«FOR p : output_arcs.get(t.name) SEPARATOR ''','''»
							"«p»": « get_expression(t.name, p, PType.OUT) !== null ? get_expression(t.name, p, PType.OUT).expTxt : "{}"»
						«ENDFOR»
					«ENDIF»
				}
			}
		«ENDFOR»
		'''
	}
	
	def generateMcrl2Place(Place p) {
		return 
		'''
		"«p.name»": "«p.custom_type.getName()»"
		'''
	}
	
	def toMcrl2() {
		'''
		{"init": {
			«generatePlaceInitializationText»
		},
		
		"places": {
			«getPlacesMcrl2()»
		},
		
		"transitions": {
			«getTransitionsMcrl2()»
		}}
		'''
	}
	
	def getBlocks() {
		var block_set = new HashSet<String>
		for(t : transitions) {
			block_set.add(t.bname)
		}
		return block_set
	}
	
	def getTransitions(String block_name) {
		var transition_list = new ArrayList<String>
		for(t : transitions) {
			if(t.bname.equals(block_name))
				transition_list.add(t.name)
		}
		return transition_list
	}
	
	def getOutputs(String transition_name) {
		var output_list = new HashSet<String>
		for(t : output_arcs.keySet) {
			if(t.equals(transition_name)) {
				for(p : output_arcs.get(t)) {
					output_list.add(p)
				}
			}
		}
		return output_list
	}
	
	def getIntputs(String transition_name) {
		var input_list = new HashSet<String>
		for(t : input_arcs.keySet) {
			if(t.equals(transition_name)) {
				for(p : input_arcs.get(t)) {
					input_list.add(p)
				}
			}
		}
		return input_list
	}
	
	def getInputArcsOfBlock(String block_name) {
		var arcList = new HashSet<String>
		for(b: getBlocks) {
			for(t : getTransitions(b)) {
				for(ip : getIntputs(t)) {
					arcList.add(ip)
				}		
			}
		}
		return arcList
	}
	
	def getOutputArcsOfBlock(String block_name) {
		var arcList = new HashSet<String>
		for(b: getBlocks) {
			for(t : getTransitions(b)) {
				for(ip : getOutputs(t)) {
					arcList.add(ip)
				}		
			}
		}
		return arcList
	}
}