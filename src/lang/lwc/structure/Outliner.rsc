module lang::lwc::structure::Outliner
/*
	Code Outliner for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/
import lang::lwc::structure::Syntax;
import lang::lwc::structure::AST;
import lang::lwc::structure::Implode;
import lang::lwc::structure::PropagateAliasses;
import lang::lwc::Outline;

import ParseTree;
import util::IDE;
import Node;
import IO;

// Data structures
data StructureOutline = solOutline(
	OutlineNode aliases, 
	OutlineNode elements, 
	OutlineNode pipes, 
	OutlineNode constraints
);

data ElementNode = solElement(str \type, node modifiers, node attributes);
data AliasNode = solAlias(OutlineNode modifiers, OutlineNode attributes);

public node outliner(start[Structure] tree) {

	// Setup the basic outline
	StructureOutline outline = solOutline(
		olListNode([])[@label="Aliases"],
		olListNode([])[@label="Elements"],
		olListNode([])[@label="Pipes"],
		olListNode([])[@label="Constraints"]
	)[@label="Structure"];
	
	list[node] elements = [];
	
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
			elements += [
				solElement(
					\type, 
					initModifiers(modifiers), 
					initAttributes(attributes)
				)[@label=name][@\loc=E@location]
			];
		
		// Create pipe nodes
		case P:pipe(_, str name, _, _, list[Attribute] attributes):
			outline.aliases.children += [pipenode(initAttributes(attributes))[@label=name][@\loc=P@location]];
		
		// Create constraint nodes
		case C:constraint(str name, _): 
			outline.constraints.children += [constraintnode()[@label=name][@\loc=C@location]];
	}

	// Group elements by type
	outline.elements.children = for (solElement(str etype, _, _) <- elements) append(
		olListNode(
			["<e@label>"(modifiers, attributes)[@\loc=e@\loc] | e: solElement(etype, node modifiers, node attributes) <- elements]
		)[@label = etype]
	);
	
	// Return the outline in an empty node
	return olSimpleNode(outline);
}

// Helper method to construct a list of modifier nodes
private OutlineNode initModifier(list[Modifier] lst) 
	= olListNode(
		[ olLeaf()[@label=E.id][@\loc=E@location] | E <- lst ]
	)[@label="Modifiers"];

// Helper method to construct a list of attribute nodes
private OutlineNode initAttributes(list[Attribute] lst) 
	= olListNode(
		[ olLeaf()[@label=E.name.name][@\loc=E@location] | E <- lst ]
	)[@label="Attributes"];
