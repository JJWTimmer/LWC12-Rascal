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
import lang::lwc::Elements;

import Message;
import ParseTree;
import IO;
import Set;

/*
	Context for static checker
*/

data Context = context(
	set[str] elementNames,
	set[str] aliasNames,
	set[str] pipeNames,
	set[str] constraintNames,
	map[str, set[str]] elementConnectionPoints,

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

Context checkFirstPass(Context context, Structure tree) {		
	bool isDuplicate(str name) = name in (
		context.elementNames + 
		context.aliasNames + 
		context.pipeNames + 
		context.constraintNames);
	
	set[str] checkDuplicate(str name, node N) {
		if (isDuplicate(name)) {
			context.messages += { error("Duplicate name\nThe name <name> is already in use", N@location) }; 
		 	return {};
		} else {
			return {name};
		}
	}

	
	visit (tree) {
		// Check for duplicate Names for elements, pipes, aliases and aliases
		case E:element(_, _, str name, list[Attribute] Attributes): 
		{
			context.elementNames += checkDuplicate(name, E);
			
			// Collect connectionpoints
			if ([A*, attribute(attributename("connections"), valuelist(list[Value] Values)), B*] := Attributes) {
				context.elementConnectionPoints[name] = { connpoint | variable(str connpoint) <- Values};
			}
		}
		
		case P:pipe(_, str name, _, _, _)		: context.pipeNames += checkDuplicate(name, P);
		case C:constraint(str name, _)			: context.constraintNames += checkDuplicate(name, C);
		case A:aliaselem(str name, _, _, _)		: context.aliasNames += checkDuplicate(name, A);
		
		// Validate element Names
		case E:elementname(str name): {
			if (name notin (context.aliasNames + ElementNames)) {
				str msg = "Invalid element\n" +
						  "Should be one of:\n" + 
						  implode(ElementNames, ", ");

				if (size(context.aliasNames) > 0)
					msg += "\nOr one of the following aliases:\n"
						+ implode(context.aliasNames, ", ");
				
				msgs += error(msg, E@location);
			}
		}
	}
	
	return context;
}


Context checkSecondPass(Context context, Structure tree) {

	visit(tree) {
		case pipe(_, _, Value from, Value to, _) : {
			
			if (property(str Var, propname(str pname)) := from) {
				if (context.elementConnectionPoints[Var]? && pname notin context.elementConnectionPoints[Var]) {
					context.messages += { error("Connectionpoint does not exist", from@location) };
				}
			}
			
			if (property(str Var, propname(str pname)) := to) {
				if (context.elementConnectionPoints[Var]? && pname notin context.elementConnectionPoints[Var]) {
					context.messages += { error("Connectionpoint does not exist", to@location) };
				}
			}
		}
	}
	
	return context;
}
