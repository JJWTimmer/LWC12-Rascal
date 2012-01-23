module lang::lwc::structure::Checker
/*
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;
import lang::lwc::structure::Syntax;
import lang::lwc::structure::PropagateAliasses;

import Message;
import ParseTree;

anno set[Message] start[Structure]@messages;

public start[Structure] check(start[Structure] tree) {
	//create AST
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	lang::lwc::structure::AST::Structure ast = propagateAliasses(ast);
	
	
	//make empty sets
	set[Message] msgs = {};
	set[str] elementnames = {};
	set[str] aliasnames = {};
	set[str] pipenames = {};
	set[str] sensornames = {};
	set[str] constraintnames = {};
	
	visit (ast) {
		case E:element(_, _, str Name, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", E@location);
				msgs += msg;
			} else {
				elementnames += Name;
			}
		}
		
		case P:pipe(_, str Name, _, _, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", P@location);
				msgs += msg;
			} else {
				pipenames += Name;
			}
		}
		
		case A:aliaselem(str Name, _, _, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", A@location);
				msgs += msg;
			} else {
				aliasnames += Name;
			}
		}
		
		case S:sensor(_, _, str Name, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", S@location);
				msgs += msg;
			} else {
				sensornames += Name;
			}
		}
		
		case C:constraint(str Name, _) : {
			if (Name in elementnames || Name in aliasnames || Name in pipenames || Name in sensornames || Name in constraintnames) {
				Message msg = error("Duplicate name", C@location);
				msgs += msg;
			} else {
				constraintnames += Name;
			}
		}		
		case E:elementname(str Name) : {
			if (Name notin {"Pipe", "Joint", "Valve", "Radiator", "CentralHeatingUnit", "Boiler", "Source", "Exhaust", "Pump", "Sensor"} && Name notin aliasnames) {
				Message msg = error("Invalid element\nShould be one of:\nPipe, Joint, Valve, Radiator, CentralHeatingUnit, Boiler, Source, Exhaust, Pump, Sensor\nOr an alias name.", E@location);
				msgs += msg;
			}
		}
	}

	tree@messages = msgs;
	return tree;
}