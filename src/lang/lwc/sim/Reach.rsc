module lang::lwc::sim::Reach

import lang::lwc::sim::Context;
import lang::lwc::Definition;
import lang::lwc::sim::Graph;

import Graph;
import util::Maybe;
import Set;
import List;
import Relation;
import IO;

//is toNode reachable from fromNode, taking in account the position of the valves?
public bool isReachable(Graph[ElementNode] staticgraph, SimContext context, str fromName, Maybe[str] fromProperty, str toName, Maybe[str] toProperty) {
	ElementNode fromNode = elementNode(fromName, fromProperty);
	ElementNode toNode = elementNode(toName, toProperty);

	Graph[ElementNode] dynamicgraph = staticgraph;
	
	for (ElementState elem <- context.\data.elements) {

		if (elem.\type == "Valve") {

			if ([_*,simProp("position", val),_*] := elem.props) {
				list[value] vl = getSimContextBucketList(val);
				
				if (size(vl) > 1) {

					set[ElementNode] nodeset = {};
					for (x <- vl) {

						str prop = "";
						if (str M := x) {
							prop = M;
						}
						
						if (prop != "") {
							nodeset += elementNode(elem.name, just(prop));
						}
					}
					dynamicgraph += (nodeset*nodeset) - ident(nodeset);
				}
			}
		}
	}
	
	reachable = reach(dynamicgraph, {fromNode});
	
	bool res = false;
	if (toNode in reachable) {
		res = true;
	}

	return res;
}