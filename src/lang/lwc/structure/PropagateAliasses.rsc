module lang::lwc::structure::PropagateAliasses

import lang::lwc::structure::AST;

data AliasInfo = ai(list[Modifier] modifiers, str elemname, list[Attribute] attributes);

public Structure propagateAliasses(Structure ast) {
	map[str, AliasInfo] aliasinfo = ();
	
	// Collect alias information
	visit(ast) {
		case aliaselem(str Id, list[Modifier] Modifiers, elementname(str ElemName), list[Attribute] Attributes) : {
			ai = ai(Modifiers, ElemName, Attributes);
			aliasinfo[Id] = ai;
		}
	}
	
	// Propagete alias properties and modifiers to elements and pipes
	return visit(ast) {
		case E:element(list[Modifier] Modifiers, elementname(str ElemName), _, list[Attribute] Attributes) : {
			if (aliasinfo[ElemName]?) {
				E.modifiers += aliasinfo[ElemName].modifiers;
				E.etype = elementname(aliasinfo[ElemName].elemname);
				E.attributes += aliasinfo[ElemName].attributes;
				insert E;
			}
		}
		
		case P:pipe(elementname(str ElemName), _,  _, _, list[Attribute] attributes) : {
			if (aliasinfo[ElemName]?) {
				P.etype = elementname(aliasinfo[ElemName].elemname);
				P.attributes += aliasinfo[ElemName].attributes;
				insert P;
			}
		}
	}
}