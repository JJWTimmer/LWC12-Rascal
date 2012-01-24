module lang::lwc::structure::Outliner
/*
	Code Outliner for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/
import lang::lwc::structure::Syntax;
import lang::lwc::structure::AST;
import lang::lwc::structure::PropagateAliasses;

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


data ElementNode = elementNode(str Etype, Modifiers modifiers, Attributes attributes);
data AliasNode = aliasNode(Modifiers modifiers, Attributes attributes);
data PipeNode = pipeNode(Attributes attributes);
data ConstraintNode = constraintNode();
data ModifierNode = modifierNode();
data AttributeNode = attributeNode();

public node outliner(start[Structure] tree) {
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	ast = propagateAliasses(ast);
	
	list[ElementNode] el = [];
	list[AliasNode] al = [];
	list[PipeNode] pi = [];
	list[ConstraintNode] co = [];
	
	visit (ast) {
		case A:aliaselem(str Name, list[Modifier] Mods, _, list[Attribute] Attribs) : {
			an = aliasNode(setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(attributes(getAttributeNode(Attribs)), ("label" : "Attributes")));
			an@label = Name;
			an@\loc = A@location;
			al += an;
			
		}
	
		case E:element(list[Modifier] Mods, elementname(str Etype), str Name, list[Attribute] Attribs) : {
			en = elementNode(Etype, setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(attributes(getAttributeNode(Attribs)), ("label" : "Attributes")));
			en@label = Name;
			en@\loc = E@location;
			el += en;
		}
		
		case P:pipe(_, str Name, _, _, list[Attribute] Attribs) : {
			pn = pipeNode(setAnnotations(attributes(getAttributeNode(Attribs)), ("label" : "Attributes")));
			pn@label = Name;
			pn@\loc = P@location;
			pi += pn;
		}
		
		case C:constraint(str Name, _) : {
			cn = constraintNode();
			cn@label = Name;
			cn@\loc = C@location;
			co += cn;
		}
	}
	
	set[str] etypes = {etype | elementNode(str etype, _, _) <- el};
	
	list[node] elemNodes = [];
	
	for (etype <- etypes) {
		node etypeNode = "<etype>list"([setAnnotations("<e@label>"(modifiers, attributes), ("loc":e@\loc)) | e: elementNode(etype, Modifiers modifiers, Attributes attributes) <- el]);
		etypeNode@label = etype;
		elemNodes += etypeNode;
	}
	
	Elements elements = elements(elemNodes);
	Aliases aliases = aliases(al);
	Pipes pipes = pipes(pi);
	Constraints constraints = constraints(co);
	
	
	StructureOutline so = structureoutline(aliases, elements, pipes, constraints);
	so@label = "Structure";
	Outline root = root(so);

	return root;
}

private list[ModifierNode] getModNode(list[Modifier] mods) {
	return [setAnnotations(modifierNode(), ("label" : m.id, "loc" : m@location)) | m <- mods];
}


private list[AttributeNode] getAttributeNode(list[Attribute] attributes) {
	return [setAnnotations(attributeNode(), ("label" : attribute.name.name, "loc" : attribute@location)) | attribute <- attributes];
}