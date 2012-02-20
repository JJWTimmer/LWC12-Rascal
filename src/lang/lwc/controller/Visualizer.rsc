module lang::lwc::controller::Visualizer

import lang::lwc::controller::Load;
import lang::lwc::controller::AST;

import vis::Figure;
import vis::Render;
import List;

public void visualizeController(ParseTree::Tree tree) = render(buildControllerGraph(implode(tree)));

public Figure buildControllerGraph(Controller ast)
{
	// Build the graph
	list[Figure] nodes = [];
	list[Edge] edges = [];
	
	list[str] states = [];
	rel[str, str] transitions = {};
	
	// Collect elements
	for (S:state(statename(str name), L) <- ast.topstatements)
	{
		states += name;
		transitions += toSet([<name,G> | /goto(statename(G)) <- L]);
	}
	
	for (str state <- states)
		nodes += ellipse(text(state), id(state));
		
	for (<str from, str to> <- transitions)
		edges += edge(from, to, toArrow(arrow()));
	
	return graph(nodes, edges, gap(40));
}

private Figure point(num x, num y) = ellipse(shrink(0), align(x, y));

private Figure arrow() = overlay([point(0,1), point(1,1), point(0.5, 0)], 
		shapeConnected(true), shapeClosed(true),
		fillColor(color("black")), size(10));

