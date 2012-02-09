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
	
	for (/X:element(list[Modifier] modifiers, E:elementname("Sensor"), str ename, list[Attribute] attributes) := ast) {
		if (/attribute(attributename("on"), VL:valuelist(list[Value] val)) := attributes) {
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

private set[Message] getErrorNonExistent(loc where) = { error("Sensorpoint does not exist or to many points defined", where) };
private set[Message] getErrorUnits(loc where) = { error("Sensorpoint not compatible with sensor or no modifier", where) };
private set[Message] getErrorNoOn(loc where) = { error("Sensor not connected", where) };

private Context checkSensorVar(Context ctx, V:variable(str name), list[Modifier] modifiers) {
	if (ctx.namemap[name]? && /selfPoint(_) !:= DefinedSensorPoints[ctx.namemap[name]] ) {
		ctx.messages += getErrorNonExistent(V@location);
		
	} if (name in ctx.pipenames && /selfPoint(_) !:= DefinedSensorPoints["Pipe"] ) {
		ctx.messages += getErrorNonExistent(V@location);
		
	} else if (ctx.namemap[name]? && /selfPoint(list[list[Unit]] unitlist) := DefinedSensorPoints[ctx.namemap[name]] ) {
		str firstMod = "";
		if ([modifier(str \mod), M*] := modifiers) {
			firstMod = \mod;
		}
		if (!SensorModifiers[firstMod]? || (SensorModifiers[firstMod]? && SensorModifiers[firstMod] != unitlist) ) {
			ctx.messages += getErrorUnits(V@location);
		}

	} else if (name in ctx.pipenames && /selfPoint(list[list[Unit]] unitlist) := DefinedSensorPoints["Pipe"] ) {
		str firstMod = "";
		if ([modifier(str \mod), M*] := modifiers) {
			firstMod = \mod;
		}
		
		if (!SensorModifiers[firstMod]? || (SensorModifiers[firstMod]? && SensorModifiers[firstMod] != unitlist) ) {
			ctx.messages += getErrorUnits(V@location);
		}
	} else {
		ctx.messages += getErrorNonExistent(V@location);
	}
	return ctx;
}

private Context checkSensorProp(Context ctx, P:property(str vname, propname(str pname)), list[Modifier] modifiers) {
	if (ctx.namemap[vname]? && /sensorPoint(pname, _) !:= DefinedSensorPoints[ctx.namemap[vname]] ) {
		ctx.messages += getErrorNonExistent(P@location);
	} else if (vname in ctx.pipenames && /sensorPoint(pname, _) !:= DefinedSensorPoints["Pipe"] ) {
		ctx.messages += getErrorNonExistent(P@location);
	} else if (ctx.namemap[vname]? && /sensorPoint(pname, list[list[Unit]] unitlist) := DefinedSensorPoints[ctx.namemap[vname]] ) {
		str firstMod = "";
		if ([modifier(str \mod), M*] := modifiers) {
			firstMod = \mod;
		}
		if (!SensorModifiers[firstMod]? || (SensorModifiers[firstMod]? && SensorModifiers[firstMod] != unitlist) ) {
			ctx.messages += getErrorUnits(P@location);
		}
		
	} else if (vname in ctx.pipenames && /sensorPoint(pname, list[list[Unit]] unitlist) := DefinedSensorPoints["Pipe"] ) {
		str firstMod = "";
		if ([modifier(str \mod), M*] := modifiers) {
			firstMod = \mod;
		}
		if (!SensorModifiers[firstMod]? || (SensorModifiers[firstMod]? && SensorModifiers[firstMod] != unitlist) ) {
			ctx.messages += getErrorUnits(P@location);
		}
		
	} else {
		ctx.messages += getErrorNonExistent(P@location);
	}
	return ctx;
}