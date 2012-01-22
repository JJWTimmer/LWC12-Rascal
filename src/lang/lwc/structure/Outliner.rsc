module lang::lwc::structure::Outliner
/*
	Code Outliner for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/
import lang::lwc::structure::Syntax;
import lang::lwc::structure::AST;

import ParseTree;
import util::IDE;
import Node;

data Outline = root(StructureOutline structure);
data StructureOutline = structureoutline(Aliases aliases, Elements elements, Pipes pipes, Sensors sensors, Constraints constraints);

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

data AliasInfo = ai(list[Modifier] modifiers, str elemname, list[Asset] assets);

public node outliner(start[Structure] tree) {
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	
	list[ElementNode] el = [];
	list[AliasNode] al = [];
	list[PipeNode] pi = [];
	list[SensorNode] se = [];
	list[ConstraintNode] co = [];	
	
	map[str, AliasInfo] aliasmap = ();

	//first visit all aliasses to build property table
	visit (ast) {		
		case A:aliaselem(str Id, list[Modifier] Mods, elementname(ElemName), list[Asset] Assets) : {
			if (aliasmap[ElemName]?) {
				Mods += aliasmap[ElemName].modifiers;
				Assets += aliasmap[ElemName].assets;
			}
			an = aliasnode(setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			an@label = Id;
			an@\loc = A@location;
			al += an;
			
			aliasmap[Id] = ai(Mods, ElemName, Assets);
		}
	}
	
	visit (ast) {
		case E:element(list[Modifier] Mods, elementname(ElemName), str Name, list[Asset] Assets) : {
			if (aliasmap[ElemName]?) {
				Mods += aliasmap[ElemName].modifiers;
				Assets += aliasmap[ElemName].assets;
			}
			en = elementnode(setAnnotations(modifiers(getModNode(Mods)), ("label" : "Modifiers")), setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			en@label = Name;
			en@\loc = E@location;
			el += en;
		}
		
		case P:pipe(elementname(ElemName), str Name, _, _, list[Asset] Assets) : {
			if (aliasmap[ElemName]?) {
				Assets += aliasmap[ElemName].assets;
			}
			pn = pipenode(setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			pn@label = Name;
			pn@\loc = P@location;
			pi += pn;
		}
		
		case S:sensor(str Name, _, list[Asset] Assets) : {
			sn = sensornode(setAnnotations(assets(getAssetNode(Assets)), ("label" : "Assets")));
			sn@label = Name;
			sn@\loc = S@location;
			se += sn;
		}
		
		case C:constraint(str Name, _) : {
			cn = constraintnode();
			cn@label = Name;
			cn@\loc = C@location;
			co += cn;
		}
	}
	
	Elements elements = elements(el);
	Aliases aliases = aliases(al);
	Pipes pipes = pipes(pi);
	Sensors sensors = sensors(se);
	Constraints constraints = constraints(co);
	
	
	StructureOutline so = structureoutline(aliases, elements, pipes, sensors, constraints);
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