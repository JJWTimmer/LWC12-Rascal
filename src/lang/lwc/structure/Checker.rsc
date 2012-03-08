module lang::lwc::structure::Checker

/*

	Todo:
		- Check number of pipes on a connection
		- Hint about possible connections if an invalid connection name is used
		- built checkSensorPoints (check units)
		- check modifiers
		
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;

import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::Definition;
import lang::lwc::Constants;

import Message;
import ParseTree;
import List;
import Set;
import IO;
/*
	Context for static checker
*/

data Context = context(
	set[str] elementnames,
	set[str] aliasnames,
	set[str] pipenames,
	set[str] constraintnames,
	map[str, set[str]] elementconnections,
	map[str, str] namemap,
	set[Message] messages	
); 

Context initContext() = context({}, {}, {}, {}, (), (), {});

anno loc node@location;

public Tree check(Tree tree) {
	
	Structure ast = implode(tree);
	
	Context context = initContext();
	context = collect(context, ast);
	context = checkDuplicates(context, ast);
	context = checkConnectionPoints(context, ast);
	context = checkSensorPoints(context, ast);
	context = checkModifiers(context, ast);
	context = checkRequiredAttribs(context, ast);
	
	return tree[@messages = context.messages];
}

Context collect(Context context, Structure ast) {
			
	bool isDuplicate(str name) = name in (
		context.elementnames + 
		context.aliasnames + 
		context.pipenames + 
		context.constraintnames);
	
	set[str] checkDuplicate(str name, node N) {
		if (isDuplicate(name)) {
			context.messages += { error("Duplicate name\nThe name <name> is already in use", N@location) }; 
		 	return {};
		} else {
			return {name};
		}
	}

	ast = propagate(ast);

	visit (ast.body) {
		case A:aliaselem(str name, _, _, _): context.aliasnames += checkDuplicate(name, A);
		case element(_, elementname(str elem), str name, [A*, attribute(attributename("connections"), valuelist(list[Value] Values)), B*]) :
		{
			context.elementconnections[name] = { connpoint | variable(str connpoint) <- Values};
			context.namemap[name] = elem;
		}
		
		case E:element(_, elementname(str elem), str name, list[Attribute] Attributes): 
		{
			context.elementnames += checkDuplicate(name, E);
			context.elementconnections[name] = {};
			context.namemap[name] = elem;
		}
		
		case P:pipe(_, str name, _, _, _)		: context.pipenames += checkDuplicate(name, P);
		case C:constraint(str name, _)			: context.constraintnames += checkDuplicate(name, C);
	}

	return context;
}

/*
	checks in first pass:
	duplicate alias names
	duplicate element names
	duplicate pipe names
	duplicate constraint names
	valid element names from Definition.rsc
	
	extra:
	collect connectionpoints
*/
Context checkDuplicates(Context context, Structure ast) {
	
	// Second visit, checks and collects Elements, Pipes and Constraints
	for (/E:elementname(str name) <- ast.body) {
		if (name notin (ElementNames + context.aliasnames)) {
			str msg = "Invalid element
					  'Should be one of:
					  '    <intercalate(", ", toList(ElementNames))>";

			if (context.aliasnames != {})
				msg += "\nOr one of the following aliases:
					   '    <intercalate(", ", toList(context.aliasnames))>";
			
			context.messages += { error(msg, E@location) };
		}
	}
	
	return context;
}

/*
	validate connectionpoints
*/
Context checkConnectionPoints(Context context, Structure ast) {
	
	Context checkPoint(Value point, Context ctx) {
		if (property(str var, propname(str pname)) := point) {
			if ( !ctx.elementconnections[var]? || (ctx.elementconnections[var]? && pname notin ctx.elementconnections[var])) {
				ctx.messages += { error("Connectionpoint does not exist", point@location) };
			}
		} else if (variable(str var) := point) {
			if ( !ctx.elementconnections[var]? || (ctx.elementconnections[var]? && "[self]" notin ctx.elementconnections[var] ) ) {
				ctx.messages += { error("Connectionpoint does not exist", point@location) };
			}
		}
		
		return ctx;
	}

	//check if the user defined connectionpoints are allowed according to the definitionfile
	for (name <- context.namemap) {
		//if there are no defined connectionpoints for <name>
		if (!DefinedConnectionPoints[context.namemap[name]]?) {
			//then remove this entry from the map
			context.elementconnections -= (name : context.elementconnections[name]);
		//if there are no attribconnections in the defined connectionpoints for <name> ???
		} else {
		
			if (/attribConnections() !:= DefinedConnectionPoints[context.namemap[name]]) {
				//then remove this entry from the map
				context.elementconnections -= (name : context.elementconnections[name]);
			}
			
			//if connectionpoints are defined, and there exists an attribConnections()
			set[str] s = {};
			set[str] cpds = {cpd.name | ConnectionPointDefinition cpd <- DefinedConnectionPoints[context.namemap[name]], cpd has name};
			context.elementconnections[name] ? s += cpds;
		}
	}

	for (/pipe(_, _, Value from, Value to, _) := ast) {	
		context = checkPoint(from, context);
		context = checkPoint(to, context);
	}
	
	return context;
}


/*
	checks if sensorpoint names are correct
*/
Context checkSensorPoints(Context context, Structure ast) {	
	ast = propagate(ast);
	
	for (X:element(modifiers, E:elementname("Sensor"), ename, attributes) <- ast.body) {
		if (attribute(attributename("on"), VL:valuelist(val)) <- attributes) {
			if ([V:variable(_)] := val) {
				context = checkSensorVar(context, ename, V, modifiers, ast);
			} else if ([P:property(_, propname(_))] := val) {
				context = checkSensorProp(context, ename, P, modifiers, ast);
			} else {
				context.messages += getErrorNonExistent(VL@location);
			}
		} else {
			context.messages += getErrorNoOn(X@location);
		}
	}

	return context;
}

private set[Message] getErrorNonExistent(loc where) = { error("Sensorpoint does not exist or too many points defined", where) };
private set[Message] getErrorUnits(loc where) = { error("Sensorpoint not compatible with sensor or no modifier", where) };
private set[Message] getErrorNoOn(loc where) = { error("Sensor not connected", where) };

private Context checkSensorVar(Context ctx, str ename, V:variable(str name), list[Modifier] modifiers, Structure ast) {
		//check if the element type of the name var has selfpoint defined, if not error!
	ctx.messages += ( {} | it + getErrorNonExistent(getLoc(V, ename)) | ctx.namemap[name]?, !any(selfPoint(_) <- DefinedSensorPoints[ctx.namemap[name]]) )
		//check if the name var is a pipe and has selfpoint defined, if not error!	
		+ ( {} | it + getErrorNonExistent(getLoc(V, ename, ast)) | name in ctx.pipenames,  !any(selfPoint(_) <- DefinedSensorPoints["Pipe"]) )
		//check if the element type of the name var has selfpoint defined, if so check units with sensor modifiers
 		+ ( {} | it + checkElementModifierUnits(ename, V, modifiers, getPropUnits(name, propname, ctx), ast) | ctx.namemap[name]?, selfPoint(propname) <- DefinedSensorPoints[ctx.namemap[name]])
 		//check if the the name var is a pipe and has selfpoint defined, if so check units with sensor modifiers
		+ ( {} | it + checkElementModifierUnits(ename, V, modifiers, getPropUnits(name, propname, ctx), ast) | name in ctx.pipenames, selfPoint(propname) <- DefinedSensorPoints["Pipe"])
		//check if name does exist anyway, if not, error
		+ ( {} | it + getErrorNonExistent(getLoc(V, ename, ast)) | name notin ctx.pipenames, !ctx.namemap[name]? );
	return ctx;
}

private Context checkSensorProp(Context ctx, str ename, P:property(str vname, propname(str pname)), list[Modifier] modifiers, Structure ast) {
		//check if the element type of the name vname has property pname defined, if not error!
	ctx.messages += ( {} | it + getErrorNonExistent(P@location) | ctx.namemap[vname]?,  !any(sp <- DefinedSensorPoints[ctx.namemap[vname]], sp has property, sp.property == pname) )
		//check if the name vname is a pipe and has property pname defined, if not error!
		+ ( {} | it + getErrorNonExistent(P@location) | vname in ctx.pipenames, !any(sp <- DefinedSensorPoints["Pipe"], sp has property, sp.property == pname) )
		//check if the element type of the name vname has property pname defined, if so check units with sensor modifiers
		+ ( {} | it + checkElementModifierUnits(ename, P, modifiers, getPropUnits(vname, sp.property, ctx), ast) | ctx.namemap[vname]?, sp <- DefinedSensorPoints[ctx.namemap[vname]], sp has property, sp.property == pname )
		//check if the the name vname is a pipe and has property pname defined, if so check units with sensor modifiers
		+ ( {} | it + checkElementModifierUnits(ename, P, modifiers, getPropUnits(vname, sp.property, ctx), ast) | vname in ctx.pipenames, sp <- DefinedSensorPoints["Pipe"], sp has property, sp.property == pname  )
		//check if name does exist anyway, if not, error
		+ ( {} | it + getErrorNonExistent(P@location) | vname notin ctx.pipenames, !ctx.namemap[vname]? );
	return ctx;
}

private loc getLoc(node optimal, str ename, Structure ast) {
	if  (optimal@location?) return optimal@location;
	visit(ast) {
		case E:element(_,_,ename,_) : return E@location;
	}
	throw "really no loc found!";
}

private list[list[Unit]] getPropUnits(str targetName, str propName, Context ctx) {
	etype = (ctx.namemap[targetName]?) ? ctx.namemap[targetName] : "Pipe";
iprintln(ElementPropertiesUnits[etype]);
iprintln(ElementPropertiesUnits[etype][propName]);
iprintln(typeOf(ElementPropertiesUnits[etype][propName]));
	return ElementPropertiesUnits[etype][propName];
}

private set[Message] checkElementModifierUnits(str ename, Value V, list[Modifier] modifiers, list[list[Unit]] unitList, Structure ast) {
	str firstMod = "";
	set[Message] msgs = {};
	
	if([modifier(\mod), M*] := modifiers) {
		firstMod = \mod;
	}
	if(!SensorModifiers[firstMod]? || (SensorModifiers[firstMod]? && SensorModifiers[firstMod] != unitList) ) {
		msgs += getErrorUnits(getLoc(V, ename, ast));
	}
	return msgs;
}

private Context checkModifiers(Context context, Structure ast) {
	ast = propagateAliasses(ast);

	for(\E:element(modifiers, elementname(str elementType), _, _) <- ast) {
		context.messages += checkModifiers(E, modifiers, elementType);
	}
	
	return context;
}

private set[Message] checkModifiers(Statement S, list[Modifier] modifiers, str elementType) {
	if(elementType notin Elements) {
		return {};
	}
	set[Message] result = {};
	bool flag = false;
	list[set[str]] allowedModifiers = ElementModifiers[elementType];
	map[set[str], int] usedModSets = ( modSet : 0 | modSet <- allowedModifiers );
	for(M:modifier(str id) <- modifiers) {
		for(modSet <- allowedModifiers) {
			if(id in modSet) {
				flag = true;
				usedModSets[modSet] += 1;
			}
		}
		if(!flag) {
			str msg = "Invalid modifier. Possible modifiers are 
					  '<intercalate(", ", [ x | s <- allowedModifiers, x <- s ])>";
			result += { error(msg, M@location) };
		}
		flag = false;
	}
	
	for(modSet <- usedModSets) {
		if(usedModSets[modSet] > 1) {
			str msg = "You can use at most one of the following modifiers:
					  '<intercalate(", ", toList(modSet))>";
			result += { error(msg, S@location) };
		}
	}
	
	return result;
}

private Context checkRequiredAttribs(Context context, Structure ast) {
	ast = propagateAliasses(ast);

	visit(ast) {
		case E:element(modifiers, elementname(str elementType), _, attributes) : context.messages += checkElementAttribs(elementType, attributes, E@location);
		case P:pipe(_, _, _, _, attributes) : context.messages += checkElementAttribs("Pipe", attributes, P@location);
	}

	return context;
}

private set[Message] checkElementAttribs (str elementType, list[Attribute] attributes, loc where) {
	set[Message] msgs = {};
	
	for (requiredAttrib(str attribName, _, _) <- RequiredAttribs[elementType]) {
		if ( !any(attribute(attributename(attribName), _) <- attributes) ) {
			msgs += error("Missing required attribute <attribName>", where);
		} 
	}
	
	return msgs;
}