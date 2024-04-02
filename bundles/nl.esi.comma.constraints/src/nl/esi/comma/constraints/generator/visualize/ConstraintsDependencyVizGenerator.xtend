package nl.esi.comma.constraints.generator.visualize

import java.io.BufferedReader
import java.io.IOException
import java.util.ArrayList
import java.util.HashSet
import java.util.List
import nl.esi.comma.constraints.constraints.AlternatePrecedence
import nl.esi.comma.constraints.constraints.AlternateResponse
import nl.esi.comma.constraints.constraints.AlternateSuccession
import nl.esi.comma.constraints.constraints.ChainPrecedence
import nl.esi.comma.constraints.constraints.ChainResponse
import nl.esi.comma.constraints.constraints.ChainSuccession
import nl.esi.comma.constraints.constraints.Choice
import nl.esi.comma.constraints.constraints.CoExistance
import nl.esi.comma.constraints.constraints.Constraints
import nl.esi.comma.constraints.constraints.Dependencies
import nl.esi.comma.constraints.constraints.End
import nl.esi.comma.constraints.constraints.ExclusiveChoice
import nl.esi.comma.constraints.constraints.Existential
import nl.esi.comma.constraints.constraints.Future
import nl.esi.comma.constraints.constraints.Init
import nl.esi.comma.constraints.constraints.NotChainSuccession
import nl.esi.comma.constraints.constraints.NotCoExistance
import nl.esi.comma.constraints.constraints.NotSuccession
import nl.esi.comma.constraints.constraints.Past
import nl.esi.comma.constraints.constraints.Precedence
import nl.esi.comma.constraints.constraints.Ref
import nl.esi.comma.constraints.constraints.RefActSequence
import nl.esi.comma.constraints.constraints.RefAction
import nl.esi.comma.constraints.constraints.RefStep
import nl.esi.comma.constraints.constraints.RefStepSequence
import nl.esi.comma.constraints.constraints.RespondedExistence
import nl.esi.comma.constraints.constraints.Response
import nl.esi.comma.constraints.constraints.SimpleChoice
import nl.esi.comma.constraints.constraints.Succession
import nl.esi.comma.constraints.constraints.Templates
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.io.InputStreamReader
import java.io.ByteArrayInputStream

class ConstraintsDependencyVizGenerator {
	
	var AssistantGraph graph
	def generateViz(Resource res, IFileSystemAccess2 fsa, List<Constraints> constraints, String name){
		val String path = "\\Constraints\\"
		
		var uri = fsa.getURI("./")
		var file = ResourcesPlugin.getWorkspace().getRoot().getFile(new Path(uri.toPlatformString(true)));
		var srcGenPath = file.getLocation().toOSString;
		for(constraintsSource : constraints){
			if(constraintsSource.composition.isNullOrEmpty){
				computeGraph(constraintsSource.templates)
				graph.computeMissingConstraints
				var dot = generateDot(fsa)
				var fname = name + "_viz.dot"
				fsa.generateFile(path+fname, dot)
				displayVisualization(fname, srcGenPath+path)
				var json = graph.toJSON(true)
				//fsa.generateFile(path + name + ".json", json)
				var html = graph.toHTML()
				fsa.generateFile(path + name +"_viz.html", new ByteArrayInputStream(html))
			} else {
				for(elm : constraintsSource.composition){
					var templateList = new HashSet<Templates>
					for(t : elm.templates) {templateList.add(t)}
					computeGraph(templateList.toList)
					graph.computeMissingConstraints
					var dot = generateDot(fsa)
					var fname = elm.name + "_viz.dot"
					fsa.generateFile(path+fname, dot)
					//displayVisualization(fname, srcGenPath+path)
					var json = graph.toJSON(true)
					//fsa.generateFile(path + elm.name + ".json", json)
					var html = graph.toHTML()
					fsa.generateFile(path + elm.name +"_viz.html", new ByteArrayInputStream(html))
				}
			}
		}
		//fsa.generateFile(path+name+".plantuml", generatePlantUML)
	}
	
	def generatePlantUML(){
		'''
		@startuml
		hide empty description
		«FOR node:graph.nodes»
		state «node.label»
		«ENDFOR»
		«FOR edge:graph.edges»
			«IF edge.type.equals(ArrowType.right)»
			«edge.source» -[#black]-> «edge.target»
			«ENDIF»
			«IF edge.type.equals(ArrowType.dashedRight)»
			«edge.source» -[#black,dashed]-> «edge.target»
			«ENDIF»
			«IF edge.type.equals(ArrowType.both)»
			«edge.source» -[#black]-> «edge.target»
			«edge.target» -[#black]-> «edge.source»
			«ENDIF»
			«IF edge.type.equals(ArrowType.dashedBoth)»
			«edge.source» -[#black,dashed]-> «edge.target»
			«edge.target» -[#black,dashed]-> «edge.source»
			«ENDIF»
			«IF edge.type.equals(ArrowType.left)»
			«edge.source» -left[#red]-> «edge.target»
			«ENDIF»
			«IF edge.type.equals(ArrowType.dashedLeft)»
			«edge.source» -left[#red,dashed]-> «edge.target»
			«ENDIF»
		«ENDFOR»
		@enduml
		'''
	}
	
	def displayVisualization(String fname, String path) {
		var ProcessBuilder builder = new ProcessBuilder("cmd.exe", "/c", "dot -Tpng -O "+ fname);
		builder.redirectErrorStream(true);
		var Process p = null;
		try { p = builder.start(); } catch (IOException e) { e.printStackTrace(); }
		var BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()));
		var String line = null;
		do {
			try {
			line = r.readLine();
			} catch (IOException e) {
				e.printStackTrace();
			}
		} while (line!==null)
		var String expr1 = "dot -Tpng " + path + fname + " -O " + fname;
		var String expr2 = "rundll32.exe \"C:\\Program Files\\Windows Photo Viewer\\PhotoViewer.dll\", ImageView_Fullscreen " + path + fname + ".png";
		try { Runtime.getRuntime().exec(expr1); } catch (IOException e) { e.printStackTrace(); }
		try { Runtime.getRuntime().exec(expr2); } catch (IOException e) { e.printStackTrace(); }
	}
	
	def String generateDot(IFileSystemAccess2 access2) {
		var StringBuilder b = new StringBuilder("digraph dependency {\n")
		b.append(legend)
		b.append("  rankdir = LR; nodesep=.25; sep=1;\n")
		for(node: graph.nodes){
			b.append("  ").append(node.label)
			b.append(" [shape=ellipse,label=\""+ node.label+ "\"];\n")
		}
		for(edge: graph.edges){
			b.append("  ").append(edge.source)
			b.append(" -> ").append(edge.target)
			if(edge.label.contains("<b>")){
				b.append(" [label=<")
				b.append(edge.label).append(">")
			} else{
				b.append(" [label=\"")
				b.append(edge.label).append("\"")
			}
			if(edge.type.equals(ArrowType.both)){
				b.append(" dir=both color=blue")
			}
			if(edge.type.equals(ArrowType.dashedBoth)){
				b.append(" dir=both style=dashed color=blue")
			}
			if(edge.type.equals(ArrowType.dashedRight)){
				b.append(" style=dashed")
			}
			if(edge.type.equals(ArrowType.left)){
				b.append(" color=red dir=back")
			}
			if(edge.type.equals(ArrowType.dashedLeft)){
				b.append(" color=red dir=back style=dashed")
			}
			if(edge.type.equals(ArrowType.none)){
				b.append(" dir=none")
			}
			b.append("]\n")	
		}
		return b.append("}\n").toString
	}
	
	def String legend(){
		var legend = "subgraph cluster0 {"
		legend += "   rank=min; color=white \n"
		legend += "   legendTable [ shape=plaintext color=black fontname=Courier" + "\n"
		legend += "   label=< \n"
		legend += "   <table border='0' cellborder='1' cellspacing='0'> \n"
		legend += "   <tr><td bgcolor=\"lightblue\"><b> Legend </b></td></tr> \n"
		legend += "   <tr><td> Black </td><td>Response</td></tr>\n"
		legend += "   <tr><td> Red </td><td>Precedence</td></tr>\n"
		legend += "   <tr><td> Blue </td><td>Dependency</td></tr>\n"
		legend += "    </table>>] \n"
		legend += "}"
		return legend
	}
	
	def computeGraph(List<Templates> templateList){
		graph = new AssistantGraph
		for(templates : templateList) {
			for(elm : templates.type){
				if(elm instanceof Choice){
					for(elmInst : elm.type) {
//						if(elmInst instanceof SimpleChoice) {
//							var refA = elmInst.refA
//							for(elmA:getRefName(refA)){
//								graph.addNode(elmA)
//							}
//						}
						if(elmInst instanceof ExclusiveChoice) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									graph.addEdge(elmA, elmB, "Not together", ArrowType.none)
								}
							}
						}
					}
				}
				if(elm instanceof Existential) {
					for(elmInst : elm.type) {
						if(elmInst instanceof Init) {
							var ref = elmInst.ref
							for(elmA:getRefName(ref)){
								if (graph.getNode(elmA) !== null){
									graph.getNode(elmA).init = true
								} else {
									graph.addNode(elmA, true, false)
								}
							}
						}
						if(elmInst instanceof End) {
							var ref = elmInst.ref
							for(elmA:getRefName(ref)){
								if (graph.getNode(elmA) !== null){
									graph.getNode(elmA).end = true
								}
//								} else {
//									graph.addNode(elmA, false, true)
//								}
							}
						}
					}
				}
				
				if(elm instanceof Future) {
					for(elmInst : elm.type) {
						if(elmInst instanceof Response) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.not){
										graph.addEdge(elmA, elmB, "Not", ArrowType.dashedRight)
									} else {
										graph.addEdge(elmA, elmB, "", ArrowType.dashedRight)
									}
								}
							}
						}
						if(elmInst instanceof AlternateResponse) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							var refC = elmInst.refC
							var betweenActions = ""
							for(elmC:getRefName(refC)){
								betweenActions += elmC + " "
							}
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.not){
										graph.addEdge(elmA, elmB, "with out <b>"+ betweenActions + "</b>in between", ArrowType.dashedRight)
									} else {
										graph.addEdge(elmA, elmB, "with <b>"+ betweenActions + "</b>in between", ArrowType.dashedRight)
									}
									
								}
							}
							for(elmC:getRefName(refC)){
								graph.addNode(elmC)
							}
						}
						if(elmInst instanceof ChainResponse) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.not){
										graph.addEdge(elmA, elmB, "Not", ArrowType.right)
									} else {
										graph.addEdge(elmA, elmB, "", ArrowType.right)
									}
								}
							}
						}
					}
				}
				if(elm instanceof Past) {
					for(elmInst : elm.type) {
						if(elmInst instanceof Precedence) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.not){
										graph.addEdge(elmA, elmB, "Not", ArrowType.dashedLeft)
									} else {
										graph.addEdge(elmA, elmB, "", ArrowType.dashedLeft)
									}
								}
							}
						}
						if(elmInst instanceof AlternatePrecedence) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							var refC = elmInst.refC
							var betweenActions = ""
							for(elmC:getRefName(refC)){
								betweenActions += elmC + " "
							}
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.not){
										graph.addEdge(elmA, elmB, "with out <b>"+ betweenActions + "</b>in between", ArrowType.dashedLeft)
									}else{
										graph.addEdge(elmA, elmB, "with <b>"+ betweenActions + "</b>in between", ArrowType.dashedLeft)
									}
								}
							}
						}
						if(elmInst instanceof ChainPrecedence) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.not){
										graph.addEdge(elmA, elmB, "Not", ArrowType.left)
									} else {
										graph.addEdge(elmA, elmB, "", ArrowType.left)
									}
								}
							}
						}

					}
				}
				
				if(elm instanceof Dependencies) {
					for(elmInst : elm.type) {
						if(elmInst instanceof RespondedExistence) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									graph.addEdge(elmA, elmB, "RespExt", ArrowType.dashedBoth)
								}
							}
						}
						if(elmInst instanceof CoExistance) {
							var refA = elmInst.refA
							var refs = getRefName(refA)
							var src = refs.get(0)
							graph.addNode(src)
							for(var i = 1; i<refs.size; i ++){
								graph.addNode(refs.get(i))
								graph.addEdge(src, refs.get(i), "CoExt", ArrowType.dashedBoth)
							}
						}
						if(elmInst instanceof Succession) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									graph.addEdge(elmA, elmB, "Succ", ArrowType.dashedBoth)
								}
							}
						}
						if(elmInst instanceof AlternateSuccession) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							var refC = elmInst.refC
							var betweenActions = ""
							for(elmC:getRefName(refC)){
								betweenActions += elmC + " "
							}
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									if(elmInst.negation){
										graph.addEdge(elmA, elmB, "AltSucc with out <b>"+ betweenActions + "</b>in between", ArrowType.dashedBoth)
									}else{
										graph.addEdge(elmA, elmB, "AltSucc with <b>"+ betweenActions + "</b>in between", ArrowType.dashedBoth)
									}
								}
							}
						}
						if(elmInst instanceof ChainSuccession) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									graph.addEdge(elmA, elmB, "ChSucc", ArrowType.both)
								}
							}
						}
						if(elmInst instanceof NotSuccession) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									graph.addEdge(elmA, elmB, "NotSucc", ArrowType.dashedBoth)
								}
							}
						}
						if(elmInst instanceof NotCoExistance) {
							var refA = elmInst.refA
							var refs = getRefName(refA)
							var src = refs.get(0)
							graph.addNode(src)
							for(var i = 1; i<refs.size; i ++){
								graph.addNode(refs.get(i))
								graph.addEdge(src, refs.get(i), "NotCoExt", ArrowType.dashedBoth)
							}
						}
						if(elmInst instanceof NotChainSuccession) {
							var refA = elmInst.refA
							var refB = elmInst.refB
							for(elmA:getRefName(refA)){
								graph.addNode(elmA)
								for(elmB:getRefName(refB)){
									graph.addNode(elmB)
									graph.addEdge(elmA, elmB, "NotChSucc", ArrowType.both)
								}
							}
						}
					}
				}
			}
		}
	}
	
	def getRefName(List<Ref> refList){
		var refName = new ArrayList<String>
		for(ref:refList){
			refName.add(getRefName(ref))
		}
		return refName
	}
	
	def getRefName(Ref ref){
		var refName = new String
		if(ref instanceof RefStep){
			refName = ref.step.name
		}
		if(ref instanceof RefAction) {
			refName = ref.act.act.name
		}
		if(ref instanceof RefStepSequence){
			refName = ref.seq.name
		}
		if(ref instanceof RefActSequence) {
			refName = ref.seq.name
		}
		return refName
	}
}