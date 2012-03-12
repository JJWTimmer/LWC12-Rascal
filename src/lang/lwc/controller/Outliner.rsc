module lang::lwc::controller::Outliner

import lang::lwc::controller::Syntax;
import lang::lwc::controller::AST;

import lang::lwc::controller::Load;
import lang::lwc::util::Outline;

import util::IDE;
import ParseTree;

anno loc node@location;

data ControllerOutline = colOutline(OutlineNode variables, OutlineNode conditions, OutlineNode states);

public node controllerOutliner(Tree tree) {
	
	list[OutlineNode] initLeaf(str name, node N) = [olLeaf()[@label=name][@\loc=N@location]];
	
	ControllerOutline outline = colOutline(
		olListNode([])[@label="Variables"],
		olListNode([])[@label="Conditions"],
		olListNode([])[@label="States"]
	)[@label="Structure"];

	visit (implode(tree)) {
		case N:declaration(str name, _) 		: outline.variables.children += initLeaf(name, N);
		case N:condition(str name, _)			: outline.conditions.children += initLeaf(name, N);
		case N:state(statename(str name), _)	: outline.states.children += initLeaf(name, N);
	}
	
	return olSimpleNode(outline);	
}