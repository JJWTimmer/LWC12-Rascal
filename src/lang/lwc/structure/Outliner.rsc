module lang::lwc::structure::Outliner
/*
	Code Outliner for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
	
	todo: fix imports
*/
import lang::lwc::structure::AST;
import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::util::Outline;

import ParseTree;
import util::IDE;
import Node;

// Data structures
data StructureOutline = solOutline(
	OutlineNode aliases, 
	OutlineNode elements, 
	OutlineNode pipes, 
	OutlineNode constraints
);

data ElementNode = solElement(node modifiers, node attributes);
data AliasNode = solAlias(OutlineNode modifiers, OutlineNode attributes);

public node structureOutliner(Tree tree) {

	// Setup the basic outline
	StructureOutline outline = solOutline(
		olListNode([])[@label="Aliases"],
		olListNode([])[@label="Elements"],
		olListNode([])[@label="Pipes"],
		olListNode([])[@label="Constraints"]
	)[@label="Structure"];
	
	map[str,list[node]] elements = ();
	
	// Visit the the AST (where aliases are propagated)
	visit (propagateAliasses(implode(tree))) {
	
		// Create alias nodes
		case A:aliaselem(str name, list[Modifier] modifiers, _, list[Attribute] attributes):
			outline.aliases.children += [solAlias(
				initModifiers(modifiers),
				initAttributes(attributes)
			)[@label=name][@\loc=A@location]];
	
		// Collect elements, they are further processed below
		case E:element(list[Modifier] modifiers, elementname(str \type), str name, list[Attribute] attributes):
		{
			if (! elements[\type]?) elements[\type] = [];

			elements[\type] += [
				solElement(initModifiers(modifiers), initAttributes(attributes))
				[@label=name][@\loc=E@location] 
			];
		}
		
		// Create pipe nodes
		case P:pipe(_, str name, _, _, list[Attribute] attributes):
			outline.pipes.children += [olSimpleNode(initAttributes(attributes))[@label=name][@\loc=P@location]];
		
		// Create constraint nodes
		case C:constraint(str name, _): 
			outline.constraints.children += [olLeaf()[@label=name][@\loc=C@location]];
	}

	// Group elements by type
	outline.elements.children = for (str K <- elements) append(
		olListNode(
			[e | e: solElement(node modifiers, node attributes) <- elements[K]]
		)[@label = K]
	);
	
	// Return the outline in an empty node
	return olSimpleNode(outline);
}

// Helper method to construct a list of modifier nodes
private OutlineNode initModifiers(list[Modifier] lst) 
	= olListNode(
		[ olLeaf()[@label=E.id][@\loc=E@location] | E <- lst ]
	)[@label="Modifiers"];

// Helper method to construct a list of attribute nodes
private OutlineNode initAttributes(list[Attribute] lst) 
	= olListNode(
		[ olLeaf()[@label=E.name.name][@\loc=E@location] | E <- lst ]
	)[@label="Attributes"];
