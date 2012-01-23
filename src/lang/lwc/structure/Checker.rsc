module lang::lwc::structure::Checker

/*
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;
import lang::lwc::structure::Syntax;
import lang::lwc::Util;

import Message;
import ParseTree;
import IO;
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
	
	// make empty sets
	set[Message] msgs = {};
	set[str] elementnames = {};
	set[str] aliasNames = {};
	set[str] pipenames = {};
	set[str] sensornames = {};
	set[str] constraintnames = {};
	
	top-down visit (ast) {
	
		// Check duplicate element names
		case E:element(_, _, str Name, _) : {
			if (Name in elementnames || Name in aliasNames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", E@location);
				msgs += msg;
			} else {
				elementnames += Name;
			}
		}
		
		// Check for duplicate pipe names
		case P:pipe(_, str Name, _, _, _) : {
			if (Name in elementnames || Name in aliasNames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", P@location);
				msgs += msg;
			} else {
				pipenames += Name;
			}
		}
		
		// Check of duplicate alias names
		case A:aliaselem(str Name, _, _, _) : {
			if (Name in elementnames || Name in aliasNames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", A@location);
				msgs += msg;
			} else {
				aliasNames += Name;
			}
		}
		
		// Check for duplicate sensor names
		case S:sensor(_, _, str Name, _) : {
			if (Name in elementnames || Name in aliasNames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", S@location);
				msgs += msg;
			} else {
				sensornames += Name;
			}
		}
		
		// Check of duplicate constraint names
		case C:constraint(str Name, _) : {
			if (Name in elementnames || Name in aliasNames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", C@location);
				msgs += msg;
			} else {
				constraintnames += Name;
			}
		}
		
		// Validate element names
		case E:elementname(str name): {
			if (name notin (elementNames + aliasNames)) {
				str possibleAliases = implode(aliasNames, ", ");
				str msg = "Invalid element\n" +
						  "Should be one of:\n" + 
						  implode(elementNames, ", ");
					
				if (size(aliasNames) > 0)
					msg += "\nOr one of the following aliases:\n"
						+ implode(aliasNames, ", ");
				
				msgs += error(msg, E@location);
			}
		}
	}

	tree@messages = msgs;
	iprintln(msgs);
	
	return tree;
}