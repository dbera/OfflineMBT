package nl.esi.comma.scenarios.generator.causalgraph

import java.util.ArrayList
import org.eclipse.emf.common.util.EList
import nl.esi.comma.scenarios.scenarios.PayLoad
import nl.esi.comma.scenarios.scenarios.Config
import nl.esi.comma.scenarios.scenarios.Product
import nl.esi.comma.scenarios.scenarios.InterfaceEvents
import java.io.InputStreamReader
import java.util.stream.Collectors
import java.io.BufferedReader
import nl.esi.comma.scenarios.dashboard.DashboardHelper
import java.util.HashMap
import java.util.List
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.io.IOException
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import java.util.Set

class CausalGraph {
	var public nodes = new ArrayList<Node>
	var public edges = new ArrayList<Edge>
	var public features = new HashMap<String, Feature>
	
	// used for dgs generation // remove when not used TODO //
	var nidx = 0
    var eidx = 0
	
	new(){
	}
	
	new(ArrayList<Node> nodes, ArrayList<Edge> edges) {
		this.nodes = nodes
		this.edges = edges
	}
	
	def isPresentNode(String nodeName){
		for (node : nodes){
			if (node.actionName.equals(nodeName)){
				return true
			}
		}
		return false
	}
	
	def isPresentEdge(String srcNode, String dstNode){
		for (edge : edges){
			if (edge.src.equals(srcNode) &&
				edge.dst.equals(dstNode)
			){
				return true
			}
		}
		return false
	}
	
	def addNode(Node node){
		if (!isPresentNode(node.actionName)){
			this.nodes.add(node)
		}
	}
	
	def getNode(String name) {
	    for(node : this.nodes) {
	        if(node.actionName.equals(name)) {
	            return node
	        }
	    }
	    return null
	}
	
	def getEdge(String src, String dst){
		for (e : edges){
			if (e.src.equals(src) 
				&& e.dst.equals(dst)){
					return e
				}
		}
		return null
	}
	
	def addEdge(Edge edge){
		this.edges.add(edge)
	}
	
	def getEdgesOfNode(Node node) {
		var edgesOfNode = new ArrayList<Edge>
		for (e : edges){
			if (e.src.equals(node.actionName)){
				edgesOfNode.add(e)
			}
		}
		return edgesOfNode
	}
	
	def getTargetNodes(Node node) {
	    var nodeList = new ArrayList<String>
	    for(e : node.edges) nodeList.add(e.dst)
	    return nodeList
	}
	
	def generateStringText(String srcNode, List<String> dstNodeList, Set<String> changes, int numSCN) {
	    val updated_color = "[fillcolor = gold style=filled]" // gold4
        val new_color = "[fillcolor = cyan style=filled]" //fontcolor=cyan4
        val removed_color = "[fillcolor = gray74 style=filled]" //gray22
	    
	    val edge_update_color = "[color = gold]"
	    val edge_removed_color = "[color = gray74]"
	    val edge_new_color = "[color = cyan]"
	    
	    var str = new String
	    for(elm : dstNodeList) 
	    {
	       //var ncolor = new String
	       var ecolor = new String
	       //var isnodeChanged = false
	       var isedgeChanged = false
	       
	       /*if(changes.contains("node_updated")) { ncolor = updated_color isnodeChanged = true }
	       if(changes.contains("node_added")) { ncolor = new_color isnodeChanged = true  }
	       if(changes.contains("node_deleted")) { ncolor = removed_color isnodeChanged = true }*/
	       var edg = getEdge(srcNode, elm)
	       if(edg.changeType.equals("edge_added")) { ecolor = edge_new_color isedgeChanged = true }  
	       if(edg.changeType.equals("edge_updated")) { ecolor = edge_update_color isedgeChanged = true }
	       if(edg.changeType.equals("edge_deleted")) { ecolor = edge_removed_color isedgeChanged = true }
	       
	       //if(isedgeChanged) str += srcNode + " -> " + elm + " " + "[penwidth ="+ (edg.scnIDs.size/numSCN as double)*4.0 +"] " + ecolor +";\r\n"
	       var wid = (edg.scnIDs.size/numSCN as double)*4.0
	       if(wid<0.2) wid = 0.2
	       if(isedgeChanged) str += srcNode + " -> " + elm + " " + "[penwidth =4.0] " + ecolor +";\r\n"
           else str += srcNode + " -> " + elm + " [penwidth = "+ wid +"]" +";\r\n"
           
	       /*if(isedgeChanged) str += srcNode + " -> " + elm + " " + ecolor +";\r\n"
	       else str += srcNode + " -> " + elm + ";\r\n"*/ // Original
	       
	       // if(isnodeChanged) str += srcNode + " " + ncolor + ";\r\n"
	    }
	    
	    var ncolor = new String
	    var isnodeChanged = false
	    
	    if(changes.contains("node_updated")) { ncolor = updated_color isnodeChanged = true }
        if(changes.contains("node_added")) { ncolor = new_color isnodeChanged = true  }
        if(changes.contains("node_deleted")) { ncolor = removed_color isnodeChanged = true }

	    if(isnodeChanged) str += srcNode + " " + ncolor + ";\r\n"
	    return str
	}
	
	def generateDGSText(String srcNode, List<String> dstNodeList, Set<String> changes) {
	    var str = new String
	    // val n = "n"
	    val e = "e"

	    // str += "an " + srcNode + " label: " + "\"" + srcNode + "\"\r\n"
	    // nidx++
	    for(elm : dstNodeList) {
	        str += "ae " + e + eidx + " " + srcNode + " > " + elm + " label: \"" + e + eidx + "\"\r\n"
	        eidx++ 
	    }
	    return str
	}
	
	def generateDGS(IFileSystemAccess2 fsa, String taskName) {
	    nidx = 0
	    eidx = 0
	    var str = new String
	    var dgsStr = "DGS004\r\n"
	    dgsStr += "\"reachabilitygraph.dgs\" 0 0\r\n"
	    for(n : nodes) {
	        str += "an " + n.actionName + " label: " + "\"" + n.actionName + "\"\r\n"
	    }
	    dgsStr += str
	    for(n : nodes) {
	        dgsStr += generateDGSText(n.actionName, getTargetNodes(n), n.changeType)
	    }
	    fsa.generateFile("\\visualization\\" + taskName + "\\reachabilitygraph.dgs", dgsStr)
	}
	
	def generateDOT(IFileSystemAccess2 fsa, String taskName, int numSCN) {
	    var dotStr = "digraph diffCG {\r\n"
	    // dotStr += "concentrate=true;\r\n"
	    for(n : nodes) {
	        dotStr += generateStringText(n.actionName, getTargetNodes(n), n.changeType, numSCN)
	    }
        dotStr += "node [shape=plaintext]\r\n" +
                "some_node [\r\n" +
                "label=<\r\n" +
                "   <table border=\"0\" cellborder=\"1\" cellspacing=\"0\">\r\n" +
                "   <tr><td bgcolor=\"white\"><font color=\"black\">LEGEND</font></td></tr>\r\n" +
                "   <tr><td bgcolor=\"gold\"><font color=\"gold4\">Updated</font></td></tr>\r\n" +
                "   <tr><td bgcolor=\"cyan\"><font color=\"cyan4\">Added</font></td></tr>\r\n" +
                "   <tr><td bgcolor=\"gray74\"><font color=\"gray22\">Removed</font></td></tr>\r\n" +
                "   </table>>\r\n" +
                " ];\r\n"
	    dotStr += "}"
	    
	    val String path = "\\visualization\\" + taskName + "\\"
        var uri = fsa.getURI("./")
        var file = ResourcesPlugin.getWorkspace().getRoot().getFile(new Path(uri.toPlatformString(true)));
        var srcGenPath = file.getLocation().toOSString;
	    displayDOT(dotStr, srcGenPath + path, fsa, taskName)
	    // generateDGS(fsa, taskName)
	}
	
	def displayDOT(String dotGraph, String path, IFileSystemAccess2 fsa, String taskName) 
    {
        var fname = "diff.dot"
        var ofname = "diff.png"
        fsa.generateFile("\\visualization\\" + taskName + "\\" +fname, dotGraph)
        // System.out.println(" PATH " + path + fname)
        
        var String expr1 = "dot -Tpng " + path + fname + " -O " + fname;
        // var String expr1 = "dot -Tpng " + path + fname + " > " + ofname;
        
        var output = new StringBuffer();
        try {
            var p = Runtime.getRuntime().exec(expr1);
            p.waitFor();
            var reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
            var line = "";           
            while ((line = reader.readLine())!== null) {
                output.append(line + "\n");
            }
        } catch (IOException e) { e.printStackTrace(); }
        System.out.println(output.toString());
        
        // var String expr2 = "rundll32.exe \"C:\\Program Files\\Windows Photo Viewer\\PhotoViewer.dll\", ImageView_Fullscreen " + path + fname + ".png";
        // try { Runtime.getRuntime().exec(expr1); } catch (IOException e) { e.printStackTrace(); }
        // try { Runtime.getRuntime().exec(expr2); } catch (IOException e) { e.printStackTrace(); }
    }
	
	//update Action Node data, init and test set
	def setNodeProperties(String nodeName, String scnID, EList<PayLoad> data, boolean init, boolean terminal,
							EList<Config> configs, EList<Product> productSet, EList<InterfaceEvents> events, 
							int index) {
		for (var i =0; i < this.nodes.size; i++) {
			if (this.nodes.get(i).actionName.equals(nodeName)) {
				this.nodes.get(i).init = (this.nodes.get(i).init || init)
				this.nodes.get(i).terminal = (this.nodes.get(i).terminal || terminal)
				this.nodes.get(i).scnIDs.add(scnID)
				
				if (!data.empty){
					var nodeData = new NodeData(scnID, index)
					for (d : data) {
						var dataList = d.dataList
						for (testData : dataList) {
							nodeData.addData(testData.key, testData.value)
						}
					}
					this.nodes.get(i).addData(nodeData)
				}
				
				for (conf : configs) {
					this.nodes.get(i).addConfig(conf.value)
				}
				for (prod : productSet) {
					this.nodes.get(i).addProductSet(prod.value)
					this.nodes.get(i).addIDtoProductSet(scnID, prod.value)
				}
				for (e : events) {
					this.nodes.get(i).addEvents(e.value)
				}
			}
		}
	}
	
	def setEdgeProperties(String srcNode, String dstNode, ArrayList<String> scnIDs, EList<Config> configs, 
							EList<Product> productSet) {
		for (var i = 0; i < this.edges.size; i++){
			if (this.edges.get(i).src.equals(srcNode) 
				&& this.edges.get(i).dst.equals(dstNode)){
				for (id : scnIDs) {
					this.edges.get(i).addScnID(id)
				}
				for (conf : configs) {
					this.edges.get(i).addConfig(conf.value)
				}
				for (prod : productSet) {
					this.edges.get(i).addProductSet(prod.value)
				}
			}
		}
	}
	
	def addFeature(Feature feature) {
	    this.features.put(feature.ID, feature);
	}
	
	def String toJSON(boolean pretty, CausalFootprint footprintA, CausalFootprint footprintB) {
		return GsonHelper.toJSON(this, pretty, footprintA, footprintB)
	}
	
	def byte[] toHTML(boolean diff, CausalFootprint footprintA, CausalFootprint footprintB) {
		var byte[] result = null
		if (diff) {
		    result = DashboardHelper.getHTML(this.toJSON(false, footprintA, footprintB));
		} else {
			var in = this.class.classLoader.getResourceAsStream("causal_graph.html")
			var html = new BufferedReader(new InputStreamReader(in))
				.lines().parallel().collect(Collectors.joining("\n"));
			result = html.replace("\"%CAUSAL_GRAPH%\"", this.toJSON(false, null, null)).bytes
		}
		return result
	}
	
}