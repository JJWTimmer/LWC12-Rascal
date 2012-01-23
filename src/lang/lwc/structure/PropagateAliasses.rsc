module lang::lwc::structure::PropagateAliasses

import lang::lwc::structure::AST;

data AliasInfo = ai(list[Modifier] modifiers, ElementName elemname, list[Asset] assets);

public Structure propagateAliasses(Structure ast) {
	map[str, AliasInfo] aliasinfo = ();
	
	visit(ast) {
		case aliaselem(str Id, list[Modifier] Modifiers, elementname(str ElemName), list[Asset] Assets) : {
			ai = aliasinfo(Modifiers, ElemName, Assets);
			aliasinfo[Id] = ai;
		}
	}
	
	ast = visit(ast) {
		case E:element(list[Modifier] Modifiers, elementname(str ElemName), _, list[Asset] Assets) : {
			if (aliasinfo[ElemName]?) {
				E.modifiers += aliasinfo[ElemName].modifiers;
				E.etype = elementname(aliasinfo[ElemName].elemname);
				E.assets += aliasinfo[ElemName].assets;
				insert E;
			}
		}
		
		case P:pipe(elementname(str ElemName), _,  _, _, list[Asset] assets) : {
			if (aliasinfo[ElemName]?) {
				P.etype = elementname(aliasinfo[ElemName].elemname);
				P.assets += aliasinfo[ElemName].assets;
				insert P;
			}
		}
	}
	
	return ast;
}