module lang::lwc::structure::Checker

/*

	Todo:
		- Check number of pipes on a connection
		- Hint about possible connections if an invalid connection name is used
		- built checkSensorPoints
		- checkConnectionPoints doesnt work for variable(name)
		
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;
import lang::lwc::structure::Implode;
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

anno set[Message] start[Structure]@messages;
anno loc node@location;

public start[Structure] check(start[Structure] tree) {
	
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

	visit (ast.body) {
		case A:aliaselem(str name, _, _, _): context.aliasnames += checkDuplicate(name, A);
		case element(_, elementname(str elem), str name, [A*, attribute(attributename("connections"), valuelist(list[Value] Values)), B*]) :
		{
			context.elementconnections[name] = { connpoint | variable(str connpoint) <- Values};
			context.namemap[name] = elem;
		}
		
		case E:element(_, _, str name, list[Attribute] Attributes): 
		{
			context.elementnames += checkDuplicate(name, E);
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
					  '    <intercalate(", ", ElementNames)>";

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
			if (ctx.elementconnections[var]? && pname notin ctx.elementconnections[var]) {
				ctx.messages += { error("Connectionpoint does not exist", point@location) };
			}
		} else if (variable(str var) := point) {
			if (ctx.elementconnections[var]? && /attribConnections() !:= DefinedConnectionPoints[ctx.namemap[name]]) {
				ctx.messages += { error("Connectionpoint does not exist", point@location) };
			}
		}
		
		return ctx;
	}

	//check if the user defined connectionpoints are allowed according to the definitionfile
	for (name <- context.elementconnections) {
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
	
	return context;
}