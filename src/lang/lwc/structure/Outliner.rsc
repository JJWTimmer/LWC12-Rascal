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

data Outline = root(StructureOutline structure);
data StructureOutline = structureoutline(Aliases aliases, Elements elements, Pipes pipes, Constraints constraints);

data Elements = elements(list[node]);
data Aliases = aliases(list[AliasNode]);
data Pipes = pipes(list[PipeNode]);
data Constraints = constraints(list[ConstraintNode]);

data Modifiers = modifiers(list[ModifierNode]);
data Attributes = attributes(list[AttributeNode]);

data ElementNode = elementnode(str Etype, Modifiers modifiers, Attributes attributes);
data AliasNode = aliasnode(Modifiers modifiers, Attributes attributes);
data PipeNode = pipenode(Attributes attributes);
data ConstraintNode = constraintnode();
data ModifierNode = modifiernode();
data AttributeNode = attributenode();

public node outliner(start[Structure] tree) {
	ast = propagateAliasses(implode(tree));
	
	list[ElementNode] el = [];
	list[AliasNode] al = [];
	list[PipeNode] pi = [];
	list[ConstraintNode] co = [];
	
	visit (ast) {
		case A:aliaselem(str name, list[Modifier] modifiers, _, list[Attribute] attributes):
			al += aliasnode(
				initModifiers(modifiers),
				initAttributes(attributes)
			)[@label=name][@\loc=A@location];
	
		case E:element(list[Modifier] modifiers, elementname(str Etype), str name, list[Attribute] attributes):
			el += elementnode(
				Etype, 
				initModifiers(modifiers), 
				initAttributes(attributes)
			)[@label=name][@\loc=E@location];
		
		case P:pipe(_, str name, _, _, list[Attribute] attributes):
			pi += pipenode(initAttributes(attributes))[@label=name][@\loc=P@location];
		
		case C:constraint(str name, _): 
			co += constraintnode()[@label=name][@\loc=C@location];
	}

	elemnodes = for (elementnode(str etype, _, _) <- el) append(
		"<etype>list"(
			[
				"<e@label>"(modifiers, attributes)[@\loc=e@\loc] | e: elementnode(etype, Modifiers modifiers, Attributes attributes) <- el
			]
		)[@label = etype]
	);
	
	StructureOutline so = structureoutline(
		aliases(al), 
		elements(elemnodes), 
		pipes(pi), 
		constraints(co)
	)[@label="Structure"];

	return root(so);
}

private Modifiers initModifiers(list[Modifier] mods) 
	= modifiers(
		[modifiernode()[@label=m.id][@\loc=m@location] | m <- mods]
	)[@label="Modifiers"];

private Attributes initAttributes(list[Attribute] lst) 
	= attributes(
		[setAnnotations(attributenode(), ("label" : E.name.name, "loc" :E@location)) | E <- lst]
	)[@label="Attributes"];
