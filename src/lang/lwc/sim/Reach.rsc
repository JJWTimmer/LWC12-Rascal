module lang::lwc::sim::Reach

import lang::lwc::structure::AST;
import lang::lwc::sim::Context;

import Graph;
import util::Maybe;
import Set;

data ElementNode = elementNode(str name, Maybe[str] property);

public Graph[ElementNode] buildGraph(Structure ast) {
	Graph[ElementNode] graph = {};

	visit (ast) {
		case pipe(_, pipeName, from, to, _) : {
		
			Maybe[ElementNode] fromNode = nothing(); 
			if (property(name, propname(property) ) := from) {
				fromNode = just( elementNode(name, just(property) ) );
			} else if (variable(name) := from) {
				fromNode = just( elementNode(name, nothing() ) );
			}
			
			Maybe[ElementNode] toNode = nothing(); 
			if (property(name, propname(property) ) := to) {
				toNode = just( elementNode(name, just(property ) ) );
			} else if (variable(name) := to) {
				toNode = just( elementNode(name, nothing() ) );
			}
			
			if (nothing() := fromNode || nothing() := toNode) {
				throw "Structure file incorrect, check elements for pipe \'<pipeName>\'";
			}
			
			graph += <fromNode.val, toNode.val>;
		}
	}
	
	return graph;
}

public bool isReachable(Graph[ElementNode] graph, SimContext context, str fromName, Maybe[str] fromProperty, str toName, Maybe[str] toProperty) {
	fromNode = elementNode(fromName, fromProperty);
	toNode = elementNode(toName, toProperty);
	
	path = shortestPathPair(graph, fromNode, toNode);
	
	set[ElementNode] reachable = reach(graph, {fromNode});
	
	bool res = false;
	if (toNode in reachable) {
		res = true;
	}

	return res;
}