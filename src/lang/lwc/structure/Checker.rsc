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
	
	map[str, set[str]] elementconnections = ();
	
	visit (ast) {
	
		// Check for duplicate element names
		case E:element(_, _, str Name, list[Asset] Assets) : {

			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in constraintnames) {
				Message msg = error("Duplicate name", E@location);
				msgs += msg;
			} else {
				elementnames += Name;
			}
			
			//collect connectionpoints
			if ([A*, asset(assetname("connections"), valuelist(list[Value] Values)), B*] := Assets) {
				set[str] connectionpoints = { connpoint | variable(str connpoint) <- Values};
				elementconnections[Name] = connectionpoints;
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
				aliasnames += Name;
			}
		}
		
		// Check of duplicate constraint names
		case C:constraint(str Name, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in constraintnames) {
				Message msg = error("Duplicate name", C@location);
				msgs += msg;
			} else {
				constraintnames += Name;
			}
		}
		
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
	
	iprintln(elementconnections);
	
	// Check valid connection points	
	visit(ast) {

		case pipe(_, _, Value from, Value to, _) : {
			
			if (property(str Var, propname(str pname)) := from) {
				if (elementconnections[Var]? && pname notin elementconnections[Var]) {
					msgs += error("Connectionpoint does not exist", from@location);
				}
			}
			
			if (property(str Var, propname(str pname)) := to) {
				if (elementconnections[Var]? && pname notin elementconnections[Var]) {
					msgs += error("Connectionpoint does not exist", to@location);
				}
			}
		}
	}

	iprintln(msgs);
	tree@messages = msgs;
	return tree;
}
