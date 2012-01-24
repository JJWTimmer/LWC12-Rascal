module lang::lwc::structure::Propagate

import lang::lwc::structure::AST;
import lang::lwc::Definition;

data AliasInfo = ai(list[Modifier] modifiers, str elemname, list[Attribute] attributes);

public Structure propagate(Structure ast) {
	ast = propagateAliasses(ast);
	ast = propagateDefaults(ast);
	
	return ast;
}

public Structure propagateAliasses(Structure ast) {
	map[str, AliasInfo] aliasinfo = ();
	
	// Collect alias information
	visit(ast) {
		case aliaselem(str Id, list[Modifier] Modifiers, elementname(str ElemName), list[Attribute] Attributes) : {
			ai = ai(Modifiers, ElemName, Attributes);
			aliasinfo[Id] = ai;
		}
	}
	
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

public Structure propagateDefaults(Structure ast) {
	ast = top-down-break visit(ast) {
		case E:element(_, elementname(str ElemName), _, list[Attribute] Attributes) : {
			if (Elements[ElemName]?) {
				list[AttributeDefinition] optionalAttribs = [O | O:optionalAttrib(_, _, _) <- Elements[ElemName].attributes];
				if (optionalAttribs != [] ) {

					E.attributes +=
						[
							attribute(attributename(attribname), getValue(defaultvalue)) 
							| optionalAttrib(str attribname, _, ValueDefinition defaultvalue) <- optionalAttribs,
							attribname notin [ existingattrib | attribute(attributename(str existingattrib), _) <- E.attributes]
						];
						
					insert E;
				}
			}
		}
		
		default: ;
	}
	
	return ast;
}

private ValueList getValue(ValueDefinition defaultvalue) {
	switch(defaultvalue) {
		case numValue(int val, list[Unit] un) 	: return valuelist([metric(integer(val),unit(un))]);
		case numValue(real val, list[Unit] un) 	: return valuelist([metric(realnum(val),unit(un))]);
		case boolValue(true) 					: return valuelist([booltrue()]);
		case boolValue(false) 					: return valuelist([boolfalse()]);
		case listValue(list[str] lst) 			: return valuelist([variable(var) | var <- lst]);
	}
}