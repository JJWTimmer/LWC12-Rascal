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
data Assets = assets(list[AssetNode]);


data ElementNode = elementnode(str Etype, Modifiers modifiers, Assets assets);
data AliasNode = aliasnode(Modifiers modifiers, Assets assets);
data PipeNode = pipenode(Assets assets);
data ConstraintNode = constraintnode();
data ModifierNode = modifiernode();
data AssetNode = assetnode();

public node outliner(start[Structure] tree) {
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	ast = propagateAliasses(ast);
	
	list[ElementNode] el = [];
	list[AliasNode] al = [];
	list[PipeNode] pi = [];
	list[ConstraintNode] co = [];
	
	visit (ast) {
		case A:aliaselem(str Name, list[Modifier] Mods, _, list[Asset] Assets) : {
			an = aliasnode(setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			an@label = Name;
			an@\loc = A@location;
			al += an;
			
		}
	
		case E:element(list[Modifier] Mods, elementname(str Etype), str Name, list[Asset] Assets) : {
			en = elementnode(Etype, setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			en@label = Name;
			en@\loc = E@location;
			el += en;
		}
		
		case P:pipe(_, str Name, _, _, list[Asset] Assets) : {
			pn = pipenode(setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			pn@label = Name;
			pn@\loc = P@location;
			pi += pn;
		}
		
		case C:constraint(str Name, _) : {
			cn = constraintnode();
			cn@label = Name;
			cn@\loc = C@location;
			co += cn;
		}
	}
	
	set[str] etypes = {etype | elementnode(str etype, _, _) <- el};
	
	list[node] elemnodes = [];
	
	for (etype <- etypes) {
		node etypenode = "<etype>list"([setAnnotations("<e@label>"(modifiers, assets), ("loc":e@\loc)) | e: elementnode(etype, Modifiers modifiers, Assets assets) <- el]);
		etypenode@label = etype;
		elemnodes += etypenode;
	}
	
	Elements elements = elements(elemnodes);
	Aliases aliases = aliases(al);
	Pipes pipes = pipes(pi);
	Constraints constraints = constraints(co);
	
	
	StructureOutline so = structureoutline(aliases, elements, pipes, constraints);
	so@label = "Structure";
	Outline root = root(so);

	return root;
}

private list[ModifierNode] getModNode(list[Modifier] mods) {
	return [setAnnotations(modifiernode(), ("label" : m.id, "loc" : m@location)) | m <- mods];
}


private list[AssetNode] getAssetNode(list[Asset] assets) {
	return [setAnnotations(assetnode(), ("label" : asset.name.name, "loc" : asset@location)) | asset <- assets];
}