module lang::lwc::structure::Checker

/*
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;
import lang::lwc::structure::Syntax;
import lang::lwc::structure::PropagateAliasses;
import lang::lwc::Util;


import Message;
import ParseTree;
import IO;
import Set;

anno set[Message] start[Structure]@messages;
anno loc node@location;

public start[Structure] check(start[Structure] tree) {

	// Allowed elements names
	set[str] allowedElementNames = {
		"Boiler", 
		"CentralHeatingUnit", 
		"Exhaust", 
		"Joint", 
		"Pipe", 
		"Pump", 
		"Radiator", 
		"Sensor",
		"Source", 
		"Valve"
	};
		
	// create AST
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	ast = propagateAliasses(ast);
	
	// make empty sets
	set[Message] msgs = {};
	set[str] elementnames = {};
	set[str] aliasnames = {};
	set[str] pipenames = {};
	set[str] constraintnames = {};
	
	bool isDuplicate(str name) = name in (elementnames + aliasnames + pipenames + constraintnames);
	
	set[str] checkDuplicate(str name, node N) {
		if (isDuplicate(name)) {
			msgs += error("Duplicate name\nThe name <name> is already in use", N@location); 
		 	return {};
		} else {
			return {name};
		}
	}
	
	visit (ast) {
	
		// Check for duplicate names for elements, pipes, aliases and aliases
		case E:element(_, _, str name, _)		: elementnames += checkDuplicate(name, E);
		case P:pipe(_, str name, _, _, _)		: pipenames += checkDuplicate(name, P);
		case C:constraint(str name, _)			: constraintnames += checkDuplicate(name, C);
		case A:aliaselem(str name, _, _, _)		: aliasnames += checkDuplicate(name, A);
		
		// Validate element names
		case E:elementname(str name): {
			if (name notin (allowedElementNames + aliasnames)) {
				str msg = "Invalid element\n" +
						  "Should be one of:\n" + 
						  implode(allowedElementNames, ", ");
				
				if (size(aliasnames) > 0)
					msg += "\nOr one of the following aliases:\n"
						+ implode(aliasnames, ", ");
				
				msgs += error(msg, E@location);
			}
		}
	}

	return tree[@messages = msgs];
}
