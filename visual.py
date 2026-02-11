#!/usr/bin/env python3

import os
import re
import json
from collections import defaultdict
import argparse

def find_manifest_files(repo_path):
    """Find all MANIFEST.MF files in the repository."""
    manifest_files = []
    for root, dirs, files in os.walk(repo_path):
        # Check if META-INF directory exists in current directory
        meta_inf_path = os.path.join(root, 'META-INF')
        if os.path.isdir(meta_inf_path):
            manifest_path = os.path.join(meta_inf_path, 'MANIFEST.MF')
            if os.path.exists(manifest_path):
                manifest_files.append(manifest_path)
    return manifest_files

def parse_manifest(manifest_path):
    """Parse a MANIFEST.MF file to extract plugin ID and dependencies."""
    with open(manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract Bundle-SymbolicName
    bundle_name_match = re.search(r'Bundle-SymbolicName:\s*([^;\n]+)', content)
    if not bundle_name_match:
        return None, []
    
    plugin_id = bundle_name_match.group(1).strip()
    
    # Extract Require-Bundle
    dependencies = []
    require_bundle_match = re.search(r'Require-Bundle:\s*([^;].*?)(?:\n\w|$)', content, re.DOTALL)
    if require_bundle_match:
        deps_text = require_bundle_match.group(1)
        # Handle line continuations and split by commas
        deps_text = re.sub(r'\n\s+', '', deps_text)
        deps = [d.strip() for d in deps_text.split(',')]
        
        # Extract just the plugin ID from each dependency (ignoring version constraints)
        for dep in deps:
            dep_id_match = re.search(r'^([^;]+)', dep)
            if dep_id_match:
                dependencies.append(dep_id_match.group(1).strip())
    
    return plugin_id, dependencies

def should_include_plugin(plugin_id):
    """Check if the plugin should be included in the visualization."""
    return not (plugin_id.endswith('.ui') or plugin_id.endswith('.ide'))

def generate_dependency_graph(manifest_files):
    """Generate a dependency graph from manifest files."""
    dependencies = {}
    internal_plugins = set()
    
    # First, identify all internal plugins (excluding .ui and .ide plugins)
    for manifest_path in manifest_files:
        plugin_id, _ = parse_manifest(manifest_path)
        if plugin_id and should_include_plugin(plugin_id):
            internal_plugins.add(plugin_id)
    
    # Then, build the dependency graph with only internal dependencies
    for manifest_path in manifest_files:
        plugin_id, deps = parse_manifest(manifest_path)
        if plugin_id and should_include_plugin(plugin_id):
            # Filter out external dependencies and .ui/.ide plugins
            internal_deps = [dep for dep in deps if dep in internal_plugins]
            dependencies[plugin_id] = internal_deps
    
    return dependencies, internal_plugins

def generate_html(dependencies, all_plugins):
    """Generate HTML with SVG visualization of plugin dependencies."""
    # Convert plugin IDs to indices for the visualization
    plugin_indices = {plugin: idx for idx, plugin in enumerate(sorted(all_plugins))}
    
    # Prepare nodes and links for D3.js
    nodes = [{"id": plugin, "group": 1} for plugin in sorted(all_plugins)]
    links = []
    
    for source, targets in dependencies.items():
        for target in targets:
            links.append({
                "source": plugin_indices[source],
                "target": plugin_indices[target],
                "value": 1
            })
    
    # Create a more direct representation of the dependency graph for JavaScript
    dep_graph = {}
    for source, targets in dependencies.items():
        dep_graph[source] = targets
    
    graph_data = json.dumps({"nodes": nodes, "links": links})
    dep_graph_json = json.dumps(dep_graph)
    
    html = f'''<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Eclipse Plugin Dependencies</title>
    <style>
        body {{ margin: 0; font-family: Arial, sans-serif; }}
        #graph {{ width: 100%; height: 100vh; }}
        .node {{ cursor: pointer; }}
        .node:hover {{ stroke: #000; stroke-width: 1.5px; }}
        .node-label {{ font-size: 10px; pointer-events: none; }}
        .link {{ stroke: #999; stroke-opacity: 0.6; }}
        .link.direct {{ stroke: #ff0000; stroke-opacity: 1; stroke-width: 2px; }}
        .link.indirect {{ stroke: #ff9900; stroke-opacity: 0.8; stroke-width: 1.5px; }}
        
        #details {{
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: white;
            border: 1px solid #ccc;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            max-width: 300px;
            max-height: 200px;
            overflow: auto;
        }}
        
        #stats {{
            position: fixed;
            top: 20px;
            right: 20px;
            background: white;
            border: 1px solid #ccc;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }}
        
        #legend {{
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: white;
            border: 1px solid #ccc;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }}
        
        .legend-item {{
            display: flex;
            align-items: center;
            margin-bottom: 5px;
        }}
        
        .legend-color {{
            width: 20px;
            height: 3px;
            margin-right: 8px;
        }}
    </style>
    <script src="https://d3js.org/d3.v7.min.js"></script>
</head>
<body>
    <div id="graph"></div>
    <div id="details">
        <h3>Plugin Details</h3>
        <p>Click on a node to see details</p>
    </div>
    <div id="stats">
        <h3>Repository Stats</h3>
        <p>Total plugins: <strong>{len(all_plugins)}</strong></p>
        <p>Total dependencies: <strong>{sum(len(deps) for deps in dependencies.values())}</strong></p>
        <p><em>Note: UI and IDE plugins excluded</em></p>
    </div>
    <div id="legend">
        <h3>Legend</h3>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #ff0000;"></div>
            <div>Direct Dependencies</div>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #ff9900;"></div>
            <div>Indirect Dependencies</div>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background-color: #999;"></div>
            <div>Other Dependencies</div>
        </div>
    </div>
    
    <script>
    // Graph data
    const graph = {graph_data};
    
    // Full dependency graph (plugin ID -> [dependencies])
    const dependencyGraph = {dep_graph_json};
    
    // Create the force simulation
    const width = window.innerWidth;
    const height = window.innerHeight;
    
    const simulation = d3.forceSimulation(graph.nodes)
        .force("link", d3.forceLink(graph.links).id(d => d.index))
        .force("charge", d3.forceManyBody().strength(-100))
        .force("center", d3.forceCenter(width / 2, height / 2));
    
    // Create the SVG container
    const svg = d3.select("#graph")
        .append("svg")
        .attr("viewBox", [0, 0, width, height])
        .attr("width", width)
        .attr("height", height);
    
    // Add zoom functionality
    svg.call(d3.zoom()
        .extent([[0, 0], [width, height]])
        .scaleExtent([0.1, 8])
        .on("zoom", (event) => {{
            g.attr("transform", event.transform);
        }}));
    
    const g = svg.append("g");
    
    // Add links
    const link = g.append("g")
        .selectAll("line")
        .data(graph.links)
        .join("line")
        .attr("class", "link")
        .attr("stroke-width", d => Math.sqrt(d.value));
    
    // Add nodes
    const node = g.append("g")
        .selectAll("circle")
        .data(graph.nodes)
        .join("circle")
        .attr("class", "node")
        .attr("r", 5)
        .attr("fill", "#69b3a2")
        .call(drag(simulation))
        .on("click", showDetails);
    
    // Add labels
    const label = g.append("g")
        .selectAll("text")
        .data(graph.nodes)
        .join("text")
        .attr("class", "node-label")
        .attr("dx", 8)
        .attr("dy", ".35em")
        .text(d => {{
            // Get last 3 segments of the plugin ID
            const segments = d.id.split('.');
            if (segments.length <= 3) {{
                return d.id;
            }} else {{
                return segments.slice(-3).join('.');
            }}
        }});
    
    // Set up the simulation
    simulation.on("tick", () => {{
        link
            .attr("x1", d => d.source.x)
            .attr("y1", d => d.source.y)
            .attr("x2", d => d.target.x)
            .attr("y2", d => d.target.y);
        
        node
            .attr("cx", d => d.x)
            .attr("cy", d => d.y);
        
        label
            .attr("x", d => d.x)
            .attr("y", d => d.y);
    }});
    
    // Drag functionality
    function drag(simulation) {{
        function dragstarted(event) {{
            if (!event.active) simulation.alphaTarget(0.3).restart();
            event.subject.fx = event.subject.x;
            event.subject.fy = event.subject.y;
        }}
        
        function dragged(event) {{
            event.subject.fx = event.x;
            event.subject.fy = event.y;
        }}
        
        function dragended(event) {{
            if (!event.active) simulation.alphaTarget(0);
            event.subject.fx = null;
            event.subject.fy = null;
        }}
        
        return d3.drag()
            .on("start", dragstarted)
            .on("drag", dragged)
            .on("end", dragended);
    }}
    
    // Find all transitive dependencies recursively
    function findAllDependencies(pluginId) {{
        const directDeps = dependencyGraph[pluginId] || [];
        const allDeps = new Set(directDeps);
        const indirectDeps = new Set();
        
        function collectDeps(id) {{
            const deps = dependencyGraph[id] || [];
            for (const dep of deps) {{
                if (!allDeps.has(dep)) {{
                    indirectDeps.add(dep);
                    allDeps.add(dep);
                    collectDeps(dep);
                }}
            }}
        }}
        
        // Start recursive collection from direct dependencies
        for (const dep of directDeps) {{
            collectDeps(dep);
        }}
        
        return {{
            direct: directDeps,
            indirect: [...indirectDeps]
        }};
    }}
    
    // Show plugin details and highlight dependencies
    function showDetails(event, d) {{
        const detailsDiv = document.getElementById("details");
        
        // Reset all links to default style
        link.classed("direct", false).classed("indirect", false);
        
        // Find all dependencies
        const allDeps = findAllDependencies(d.id);
        const directDepIds = allDeps.direct;
        const indirectDepIds = allDeps.indirect;
        
        // Create lookup sets for faster checking
        const directDepSet = new Set(directDepIds);
        const indirectDepSet = new Set(indirectDepIds);
        
        // Highlight direct dependencies
        link.each(function(l) {{
            const isDirect = l.source.id === d.id && directDepSet.has(l.target.id);
            d3.select(this).classed("direct", isDirect);
        }});
        
        // Highlight indirect dependencies
        link.each(function(l) {{
            // An indirect dependency link is one where:
            // 1. The source is in our direct or indirect dependencies
            // 2. The target is in our indirect dependencies
            // 3. It's not already marked as a direct dependency
            const isIndirect = !d3.select(this).classed("direct") && 
                             ((directDepSet.has(l.source.id) || indirectDepSet.has(l.source.id)) && 
                              indirectDepSet.has(l.target.id));
            
            d3.select(this).classed("indirect", isIndirect);
        }});
        
        // Find dependents (plugins that depend on this one)
        const dependents = [];
        for (const [plugin, deps] of Object.entries(dependencyGraph)) {{
            if (deps.includes(d.id)) {{
                dependents.push(plugin);
            }}
        }}
        
        let html = `<h3>${{d.id}}</h3>`;
        
        if (directDepIds.length > 0) {{
            html += `<p><strong>Direct Dependencies:</strong></p><ul>`;
            directDepIds.forEach(dep => {{
                html += `<li>${{dep}}</li>`;
            }});
            html += `</ul>`;
        }} else {{
            html += `<p><strong>Direct Dependencies:</strong> None</p>`;
        }}
        
        if (indirectDepIds.length > 0) {{
            html += `<p><strong>Indirect Dependencies:</strong></p><ul>`;
            indirectDepIds.forEach(dep => {{
                html += `<li>${{dep}}</li>`;
            }});
            html += `</ul>`;
        }}
        
        if (dependents.length > 0) {{
            html += `<p><strong>Used by:</strong></p><ul>`;
            dependents.forEach(dep => {{
                html += `<li>${{dep}}</li>`;
            }});
            html += `</ul>`;
        }} else {{
            html += `<p><strong>Used by:</strong> None</p>`;
        }}
        
        detailsDiv.innerHTML = html;
    }}
    </script>
</body>
</html>
'''
    
    return html

def main():
    parser = argparse.ArgumentParser(description='Generate Eclipse plugin dependency visualization')
    parser.add_argument('repo_path', help='Path to the repository containing Eclipse plugins')
    parser.add_argument('--output', '-o', default='plugin_dependencies.html', 
                        help='Output HTML file path (default: plugin_dependencies.html)')
    
    args = parser.parse_args()
    
    print(f"Searching for plugin manifest files in {args.repo_path}...")
    manifest_files = find_manifest_files(args.repo_path)
    print(f"Found {len(manifest_files)} manifest files.")
    
    print("Parsing manifest files and building dependency graph...")
    dependencies, internal_plugins = generate_dependency_graph(manifest_files)
    print(f"Found {len(internal_plugins)} internal plugins with {sum(len(deps) for deps in dependencies.values())} internal dependencies.")
    
    print("Generating HTML visualization...")
    html = generate_html(dependencies, internal_plugins)
    
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"Visualization saved to {args.output}")

if __name__ == "__main__":
    main()