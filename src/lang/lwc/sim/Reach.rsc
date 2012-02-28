module lang::lwc::sim::Reach

import lang::lwc::structure::AST;
import lang::lwc::sim::Context;
import lang::lwc::Definition;

import Graph;
import util::Maybe;
import Set;
import List;
import Relation;
import IO;

data ElementNode = elementNode(str name, Maybe[value] property);

public Graph[ElementNode] buildGraph(Structure ast) {

	//make links between all points in an object
	Graph[ElementNode] makeInternalLinks(str nodename, set[set[str]] connectionpoints) {
		Graph[ElementNode] graph = {};
		set[ElementNode] nodes = {};
		
		for (connectionset <- connectionpoints) {
			nodes = {elementNode(nodename, just(p)) | p <- connectionset };
			graph += (nodes * nodes) - ident(nodes);
		}
		
		
		return graph;
	}
	
	Graph[ElementNode] graph = {};
	
	//get all pipes (connections) between objects
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
	
	cg = carrier(graph);
	
	//for every object check if there are internal connections
	for (\node <- cg) {
		nodename = \node.name;
		
		set[str] connectionpoints = {};
		str etype = "";
		
		visit(ast) {
			case element(_, elementname(ename), nodename, [_*, attribute(attributename("connections"), valuelist(VL)), _*]) : {
				connectionpoints = {s | variable(s) <- VL};
				etype = ename;
			}
		}
		
		if (etype == "Valve") continue; //valves are calculated dynamically in isReachable
		
		set[set[str]] connectUs = {};
		
		for (setOfPoints <- Elements[etype].connectionpoints) {
			setOfNames = {c.name | c <- setOfPoints, c has name};
				
			if (attribConnections() in setOfPoints) {
				if (setOfNames != {}) {
					connectionpoints -= setOfNames;
					connectUs += {setOfNames};
				}
				else {
					connectUs += {connectionpoints};
				}
			} else {
				setConnections = setOfNames & connectionpoints;
				connectionpoints -= setOfNames;
				connectUs += {setConnections};
			}
		}
		
		if (connectUs == {{}}) continue;
		
		graph += makeInternalLinks(nodename, connectUs);

	}
	
	return graph;
}

//is toNode reachable from fromNode, taking in account the position of the valves?
public bool isReachable(Graph[ElementNode] staticgraph, SimContext context, str fromName, Maybe[str] fromProperty, str toName, Maybe[str] toProperty) {
	fromNode = elementNode(fromName, fromProperty);
	toNode = elementNode(toName, toProperty);
	
	dynamicgraph = staticgraph;
	
	for (elem <- context.\data.elements) {
		if (elem.\type == "Valve") {
			if ([H*,simProp("position", val),T*] := elem.props) {
				vl = getSimContextBucketList(val);
				
				if (size(vl) > 1) {
					nl = {elementNode(elem.name, just(x)) | x <- vl };
					dynamicgraph += (nl*nl) - ident(nl);
				}
			}
		}
	}
	
	reachable = reach(dynamicgraph, {fromNode});
	iprintln(dynamicgraph);
	iprintln(fromNode);
	iprintln(toNode);
	iprintln(reachable);
	
	bool res = false;
	if (toNode in reachable) {
		res = true;
	}

	return res;
}