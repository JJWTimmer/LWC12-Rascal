module lang::lwc::controller::Visualizer

import lang::lwc::controller::Load;
import lang::lwc::controller::AST;

import vis::Figure;
import vis::Render;
import IO;
import List;

public void visualizeController(ParseTree::Tree tree) = render(buildControllerGraph(implode(tree)));

public data State = 
	ActiveState(str name) 
	| ActiveEdge(tuple[str, str])
	| Done()
;

public Figure buildStatefulControllerGraph(Controller ast, State() runState)
{
	// Keep track of the current state
	State current = Done();
	
	return computeFigure(
		bool () {
			State state = runState();
			bool recompute = state != current;
			current = state;
			
			return recompute;
		},
		Figure () {
			return buildControllerGraph(ast, current);
		}
	);
}

public Figure buildControllerGraph(Controller ast) = buildControllerGraph(ast, Done());

public Figure buildControllerGraph(Controller ast, State runState)
{
	// Build the graph
	list[Figure] nodes = [];
	list[Edge] edges = [];
	
	list[str] states = [];
	rel[str, str] transitions = {};
	
	// Collect elements
	for (S:state(statename(str name), L) <- ast.topstatements) {
		states += name;
		transitions += toSet([<name,G> | /goto(statename(G)) <- L]);
	}
	
	for (str state <- states)
		nodes += stateFigure(
			state,
			(ActiveState(str N) := runState && N == state)
		);
		
	for (<str from, str to> <- transitions)
		edges += directedEdge(
			from, to, (ActiveEdge(tuple[str,str] N) := runState && N == <from, to>)
		);
	
	return graph(nodes, edges, gap(40));
}

private Figure stateFigure(str state, bool active) = ellipse(
	text(state), 
	id(state),
	fillColor(color(active ? "red" : "white"))
);

private Edge directedEdge(str from, str to, bool active)
{
	Color c = color(active ? "red" : "black");
	return edge(from, to, toArrow(coloredArrow(c)), lineColor(c));	
}

private Figure point(num x, num y) = 
	ellipse(shrink(0), align(x, y));

private Figure coloredArrow(Color color) =
	overlay([point(0,1), point(1,1), point(0.5, 0)], 
		shapeConnected(true), shapeClosed(true),
		fillColor(color), lineColor(color), size(10));


