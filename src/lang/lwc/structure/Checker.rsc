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
import Set;

anno set[Message] start[Structure]@messages;

public start[Structure] check(start[Structure] tree) {

	// Allowed elements names
	set[str] elementNames = {
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
	
	visit (ast) {

		case E:element(_, _, str Name, _) : {

			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in constraintnames) {
				Message msg = error("Duplicate name", E@location);
				msgs += msg;
			} else {
				elementnames += Name;
			}
		}
		
		// Check for duplicate pipe names
		case P:pipe(_, str Name, _, _, _) : {

			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in constraintnames) {

				Message msg = error("Duplicate name", P@location);
				msgs += msg;
			} else {
				pipenames += Name;
			}
		}
		
		// Check of duplicate alias names
		case A:aliaselem(str Name, _, _, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in constraintnames) {
				Message msg = error("Duplicate name", A@location);
				msgs += msg;
			} else {
				aliasNames += Name;
			}
		}
		
		case C:constraint(str Name, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in constraintnames) {
				Message msg = error("Duplicate name", C@location);
				msgs += msg;
			} else {
				constraintnames += Name;
			}
		}
		
		// Validate element names
		case E:elementname(str name) : {
			if (name notin (elementnames + aliasnames)) {
				str possibleAliases = implode(aliasnames, ", ");
				str msg = "Invalid element\n" +
						  "Should be one of:\n" + 
						  implode(elementnames, ", ");
					
				if (size(aliasnames))
					msg += "\nOr one of the following aliases:\n"
						+ implode(aliasnames, ", ");
				
				msgs += error(msg, E@location);
			}
		}
	}

	tree@messages = msgs;
	return tree;
}
