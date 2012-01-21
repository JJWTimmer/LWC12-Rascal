module lang::lwc::structure::Outliner

import lang::lwc::structure::Syntax;
import lang::lwc::structure::AST;

import ParseTree;
import util::IDE;
import Node;

data Outline = root(StructureOutline structure);
data StructureOutline = structureoutline(Elements elements, Aliases aliases, Pipes pipes, Sensors sensors, Constraints constraints);

data Elements = elements(list[ElementNode]);
data Aliases = aliases(list[AliasNode]);
data Pipes = pipes(list[PipeNode]);
data Sensors = sensors(list[SensorNode]);
data Constraints = constraints(list[ConstraintNode]);

data Modifiers = modifiers(list[ModifierNode]);
data Assets = assets(list[AssetNode]);


data ElementNode = elementnode(Modifiers modifiers, Assets assets);
data AliasNode = aliasnode(Modifiers modifiers, Assets assets);
data PipeNode = pipenode(Assets assets);
data SensorNode = sensornode(Assets assets);
data ConstraintNode = constraintnode();
data ModifierNode = modifiernode();
data AssetNode = assetnode();


public node outliner(lang::lwc::structure::Syntax::Structure tree) {
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	
	list[ElementNode] el = [];
	list[AliasNode] al = [];
	list[PipeNode] pi = [];
	list[SensorNode] se = [];
	list[ConstraintNode] co = [];	
	
	visit (ast) {
		case E:element(list[Modifier] Mods, ElementName ElemName, str Name, list[Asset] Assets) : {
			en = elementnode(setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			en@label = Name;
			en@\loc = E@location;
			el += en;
		}
		
		case A:aliaselem(str Id, list[Modifier] Mods, ElementName ElemName, list[Asset] Assets) : {
			an = aliasnode(setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			an@label = Id;
			an@\loc = A@location;
			al += an;
		}
	}
	
	Elements elements = elements(el);
	Aliases aliases = aliases(al);
	Pipes pipes = pipes(pi);
	Sensors sensors = sensors(se);
	Constraints constraints = constraints(co);
	
	
	StructureOutline so = structureoutline(elements, aliases, pipes, sensors, constraints);
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