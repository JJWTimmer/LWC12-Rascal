module lang::lwc::structure::Checker

/*

	Todo:
		- Check number of pipes on a connection
		- Hint about possible connections if an invalid connection name is used
		
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;
import lang::lwc::structure::Implode;
import lang::lwc::structure::Propagate;
import lang::lwc::Util;
import lang::lwc::Definition;

import Message;
import ParseTree;
import IO;
import Set;

/*
	Context for static checker
*/

data Context = context(
	set[str] elementnames,
	set[str] aliasnames,
	set[str] pipenames,
	set[str] constraintnames,
	map[str, set[str]] elementconnections,

	set[Message] messages	
); 

Context initContext() = context({}, {}, {}, {}, (), {});

anno set[Message] start[Structure]@messages;
anno loc node@location;

public start[Structure] check(start[Structure] tree) {
	
	Structure ast = propagateAliasses(implode(tree));
	
	Context context = initContext();
	context = checkFirstPass(context, ast);
	context = checkSecondPass(context, ast);
	
	return tree[@messages = context.messages];
}

Context checkSecondPass(Context context, Structure tree) {

	visit(tree) {
		case pipe(_, _, Value from, Value to, _) : {
			
			if (property(str Var, propname(str pname)) := from) {
				if (context.elementconnections[Var]? && pname notin context.elementconnections[Var]) {
					context.messages += { error("Connectionpoint does not exist", from@location) };
				}
			}
			
			if (property(str Var, propname(str pname)) := to) {
				if (context.elementconnections[Var]? && pname notin context.elementconnections[Var]) {
					context.messages += { error("Connectionpoint does not exist", to@location) };
				}
			}
		}
	}
	
	return context;
}

Context checkFirstPass(Context context, Structure tree) {
		
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

	// First visit, collects and checks alias names
	//
	// This pass is needed so we know which element names are allowed in the
	// second visit
	top-down-break visit (tree.body) {
		case A:aliaselem(str name, _, _, _): context.aliasnames += checkDuplicate(name, A);
	}
	
	// Second visit, checks and collects Elements, Pipes and Constraints
	visit (tree) {
		// Check for duplicate names for elements, pipes, aliases and aliases
		case E:element(_, _, str name, list[Attribute] Attributes): 
		{
			context.elementnames += checkDuplicate(name, E);
			
			// Collect connection points
			if ([A*, attribute(attributename("connections"), valuelist(list[Value] Values)), B*] := Attributes) {
				context.elementconnections[name] = { connpoint | variable(str connpoint) <- Values};
			}
		}
		
		case P:pipe(_, str name, _, _, _)		: context.pipenames += checkDuplicate(name, P);
		case C:constraint(str name, _)			: context.constraintnames += checkDuplicate(name, C);
		
		// Validate element names
		case E:elementname(str name): {
			if (name notin (ElementNames + context.aliasnames)) {
				str msg = "Invalid element\n" +
						  "Should be one of:\n" + 
						  "\t" + implode(ElementNames, ", ");

				if (size(context.aliasnames) > 0)
					msg += "\nOr one of the following aliases:\n"
						+ "\t" + implode(context.aliasnames, ", ");
				
				context.messages += { error(msg, E@location) };
			}
		}
	}
	
	return context;
}

