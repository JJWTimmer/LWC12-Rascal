module lang::lwc::structure::Propagate

import lang::lwc::structure::AST;
import lang::lwc::Definition;
import lang::lwc::Constants;

data AliasInfo = ai(list[Modifier] modifiers, str elemname, list[Attribute] attributes);

//do all propagating
public Structure propagate(Structure ast) {
	ast = propagateAliasses(ast);
	ast = propagateDefaults(ast);
	ast = propagateConnectionPoints(ast);
	ast = propagateSensorPoints(ast);
	
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
	}
	
	return ast;
}

//add connectionpoints to the elements in the ast
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
	}
	
	return ast;
}

//add sensorpoints from definition to the ast
public Structure propagateSensorPoints(Structure ast) {
	ast = top-down-break visit(ast) {
		case E:element(_, elementname(str ElemName), _, list[Attribute] Attributes) : {
			if (Elements[ElemName]? && Elements[ElemName].sensorpoints != []) {
				E.attributes = getSensorPoints(Attributes, Elements[ElemName].sensorpoints);
				
				insert E;
			}
		}
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
private ValueList getValue(numValue(int val, list[Unit] un)) = valuelist([metric(integer(val),unit(un))]);
private ValueList getValue(numValue(real val, list[Unit] un)) = valuelist([metric(realnum(val),unit(un))]);
private ValueList getValue(boolValue(true)) = valuelist([booltrue()]);
private ValueList getValue(boolValue(false)) = valuelist([boolfalse()]);
private ValueList getValue(listValue(list[str] lst)) = valuelist([variable(var) | var <- lst]);


//retrieve the connectionpoints that are defined to replace them in the tree
private Attribute getConnectionPoints(str elemName, list[Modifier] mods, list[Attribute] attribs) {
	list[ConnectionPointDefinition] defs = DefinedConnectionPoints[elemName];
	set[str] elementConnectionPointNames = {};
		
	if(defs != []) {
		set[str] definedConnectionPointNames = {cpName | variable(cpName) <- ([] | it + values | attribute(attributename("connections"), valuelist(list[Value] values)) <- attribs)};
		bool attribConnections = false;
		
		elementConnectionPointNames = { d.name | d <- defs, d has name, !(d has modifier) || (d has modifier && modifier(d.modifier) in mods) };
		if (/attribConnections() := defs) {
			elementConnectionPointNames += definedConnectionPointNames;
		}
	}
	
	return attribute(attributename("connections"), valuelist([variable(var) | var <- elementConnectionPointNames]));
}

//remove userdefined sensorpoints and add those from the defintion
private list[Attribute] getSensorPoints(list[Attribute] attributes, list[SensorPointDefinition] points) {
	attributes = visit (attributes) {
		case [A*, attribute(_, _), B*] => A+B
	}
	
	if (points != []) {
		list[Value] definedPoints = [variable(name) | sensorPoint(str name, _) <- points];
		if (/selfPoint(_) := points) {
			definedPoints += [variable("[self]")];		
		}
		attributes += [attribute(attributename("sensorpoints"), valuelist(definedPoints))];
	}
	
	return attributes;
}