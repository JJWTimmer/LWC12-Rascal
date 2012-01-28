module lang::lwc::structure::Propagate

import lang::lwc::structure::AST;
import lang::lwc::Definition;

data AliasInfo = ai(list[Modifier] modifiers, str elemname, list[Attribute] attributes);


public Structure propagate(Structure ast) {
	ast = propagateAliasses(ast);
	ast = propagateDefaults(ast);
	ast = propagateConnectionPoints(ast);
	
	return ast;
}

//fill in all alias info in the ast
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

//add defaults to the elements in the ast
public Structure propagateDefaults(Structure ast) {
	ast = top-down-break visit(ast) {
		case E:element(_, elementname(str ElemName), _, list[Attribute] Attributes) : {
			if (Elements[ElemName]?) {
				E.attributes += getDefaults(OptionalAttribs[ElemName], Attributes);
				insert E;
			}
		}
		
		case P:pipe(elementname(str ElemName), _, _,  _, list[Attribute] Attributes) : {
			if (Elements[ElemName]?) {
				P.attributes += getDefaults(OptionalAttribs[ElemName], Attributes);	
				insert P;
			}
		}
		//do not add a default case in a top-down-break!
	}
	
	return ast;
}

public Structure propagateConnectionPoints(Structure ast) {
	ast = top-down-break visit(ast) {
		case E:element(list[Modifier] Modifiers , elementname(str ElemName), _, list[Attribute] Attributes) : {
			if (Elements[ElemName]?) {
				bool gotConnectionPointDefs = false;
				
				E.attributes = visit (E.attributes) {
					case [A*, attribute(attributename("connections"), _), B*] : {
						gotConnectionPointDefs = true;
						insertvalue = A + B + [getConnectionPoints(ElemName, Modifiers, Attributes)];
						insert insertvalue;
					}
				}
				
				if(!gotConnectionPointDefs) {
					Attribute attrib = getConnectionPoints(ElemName, Modifiers, Attributes);
					if ( attribute(_, valuelist([]) ) !:= attrib) {
						E.attributes += [attrib];
					}
				}
				
				insert E;
			}
		}
		//do not add a default case in a top-down-break!
	}
	
	return ast;
}

//retrieve the defaults for the attributes that are not set
private list[Attribute] getDefaults(list[AttributeDefinition] optionalAttribs, list[Attribute] existingAttribs) =
	[
		attribute(attributename(attribname), getValue(defaultvalue)) 
		| optionalAttrib(str attribname, _, ValueDefinition defaultvalue) <- optionalAttribs,
		attribname notin [ existingattrib | attribute(attributename(str existingattrib), _) <- existingAttribs]
	];

//transforms definition ADT's to AST ADT's
private ValueList getValue(ValueDefinition defaultvalue) {
	switch(defaultvalue) {
		case numValue(int val, list[Unit] un) 	: return valuelist([metric(integer(val),unit(un))]);
		case numValue(real val, list[Unit] un) 	: return valuelist([metric(realnum(val),unit(un))]);
		case boolValue(true) 					: return valuelist([booltrue()]);
		case boolValue(false) 					: return valuelist([boolfalse()]);
		case listValue(list[str] lst) 			: return valuelist([variable(var) | var <- lst]);
	}
}

//retrieve the connectionpoints that are defined to replace them in the tree
private Attribute getConnectionPoints(str elemName, list[Modifier] mods, list[Attribute] attribs) {
	list[ConnectionPointDefinition] defs = DefinedConnectionPoints[elemName];
	set[str] elementConnectionPointNames = {};
		
	if(defs != []) {
		set[str] definedConnectionPointNames = {cpName | variable(cpName) <- ([] | it + values | attribute(attributename("connections"), valuelist(list[Value] values)) <- attribs)};
		bool attribConnections = false;
		
		for (ConnectionPointDefinition cpDef <- defs) {
			switch(cpDef) {
				case gasConnection(str Name) :  {
					elementConnectionPointNames += Name;
				}
				
				case liquidConnection(str Name) : {
					elementConnectionPointNames += Name;
				}
				
				case unknownConnection(str Name) : {
					elementConnectionPointNames += Name;
				}
				
				//special case: allow the connections attribute and add its values (below)
				case attribConnections() : {
					attribConnections = true;
				}
				
				case liquidConnectionModifier(str Name, ModifierDefinition Mod) : {
					if (modifier(Mod) in mods) {
						elementConnectionPointNames += Name;
					}
				}
				
				case unknownConnectionModifier(str Name, ModifierDefinition Mod) : {
					if (modifier(Mod) in mods) {
						elementConnectionPointNames += Name;
					}
				
				}
			}
		}
		
		if (attribConnections) {
			elementConnectionPointNames += definedConnectionPointNames;
		}
	}
	
	return attribute(attributename("connections"), valuelist([variable(var) | var <- elementConnectionPointNames]));
}