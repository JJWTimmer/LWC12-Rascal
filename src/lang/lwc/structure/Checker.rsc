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
				context = checkSensorVar(context, V, modifiers);
			} else if ([P:property(_, propname(_))] := val) {
				context = checkSensorProp(context, P, modifiers);
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

private Context checkSensorVar(Context ctx, V:variable(str name), list[Modifier] modifiers) {
		//check if the element type of the name var has selfpoint defined, if not error!
	ctx.messages += ( {} | it + getErrorNonExistent(V@location) | ctx.namemap[name]?, !any(selfPoint(_) <- DefinedSensorPoints[ctx.namemap[name]]) )
		//check if the name var is a pipe and has selfpoint defined, if not error!	
		+ ( {} | it + getErrorNonExistent(V@location) | name in ctx.pipenames,  !any(selfPoint(_) <- DefinedSensorPoints["Pipe"]) )
		//check if the element type of the name var has selfpoint defined, if so check units with sensor modifiers
 		+ ( {} | it + checkElementModifierUnits(V, modifiers, unitlist) | ctx.namemap[name]?, selfPoint(unitlist) <- DefinedSensorPoints[ctx.namemap[name]] )
 		//check if the the name var is a pipe and has selfpoint defined, if so check units with sensor modifiers
		+ ( {} | it + checkElementModifierUnits(V, modifiers, unitlist) | name in ctx.pipenames, selfPoint(unitlist) <- DefinedSensorPoints["Pipe"] )
		//check if name does exist anyway, if not, error
		+ ( {} | it + getErrorNonExistent(V@location) | name notin ctx.pipenames, !ctx.namemap[name]? );
	return ctx;
}

private Context checkSensorProp(Context ctx, P:property(str vname, propname(str pname)), list[Modifier] modifiers) {
		//check if the element type of the name var has property pname defined, if not error!
	ctx.messages += ( {} | it + getErrorNonExistent(P@location) | ctx.namemap[vname]?,  !any(sensorPoint(pname, _) <- DefinedSensorPoints[ctx.namemap[vname]]) )
		//check if the name var is a pipe and has property pname defined, if not error!
		+ ( {} | it + getErrorNonExistent(P@location) | vname in ctx.pipenames, !any(sensorPoint(pname, _) <- DefinedSensorPoints["Pipe"]) )
		//check if the element type of the name var has property pname defined, if so check units with sensor modifiers
		+ ( {} | it + checkElementModifierUnits(P, modifiers, unitlist) | ctx.namemap[vname]?, sensorPoint(pname, unitlist) <- DefinedSensorPoints[ctx.namemap[vname]] )
		//check if the the name var is a pipe and has property pname defined, if so check units with sensor modifiers
		+ ( {} | it + checkElementModifierUnits(P, modifiers, unitlist) | vname in ctx.pipenames, sensorPoint(pname, list[list[Unit]] unitlist) <- DefinedSensorPoints["Pipe"] )
		//check if name does exist anyway, if not, error
		+ ( {} | it + getErrorNonExistent(P@location) | vname notin ctx.pipenames, !ctx.namemap[vname]? );
	return ctx;
}

private set[Message] checkElementModifierUnits(Value V, list[Modifier] modifiers, list[list[Unit]] unitList) {
	str firstMod = "";
	set[Message] msgs = {};
	
	if([modifier(\mod), M*] := modifiers) {
		firstMod = \mod;
	}
	if(!SensorModifiers[firstMod]? || (SensorModifiers[firstMod]? && SensorModifiers[firstMod] != unitList) ) {
		msgs += getErrorUnits(V@location);
	}
	return msgs;
}

private Context checkModifiers(Context context, Structure ast) {
	ast = propagateAliasses(ast);

	visit(ast) {
		case E:element(modifiers, elementname(str elementType), _, _) : context.messages += checkModifiers(E, modifiers, elementType);
		case A:aliaselem(_, modifiers, elementname(str elementType), _) : context.messages += checkModifiers(A, modifiers, elementType);
	}

	return context;
}

set[Message] checkModifiers(Statement S, list[Modifier] modifiers, str elementType) {
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