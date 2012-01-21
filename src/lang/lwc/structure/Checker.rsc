module lang::lwc::structure::Checker
/*
	AST Checker for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

import lang::lwc::structure::AST;
import lang::lwc::structure::Syntax;

import Message;
import ParseTree;
import IO;

anno set[Message] lang::lwc::structure::Syntax::Structure@messages;

public lang::lwc::structure::Syntax::Structure check(lang::lwc::structure::Syntax::Structure tree) {
	//create AST
	lang::lwc::structure::AST::Structure ast = implode(#lang::lwc::structure::AST::Structure, tree);
	
	//make empty sets
	set[Message] msgs = {};
	set[str] elementnames = {};
	set[str] aliasnames = {};
	set[str] pipenames = {};
	set[str] sensornames = {};
	set[str] constraintnames = {};
	
	top-down visit (ast) {
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
				Message msg = error("Invalid element\nShould be one of:\nPipe, Joint, Valve, Radiator, CentralHeatingUnit, Boiler, Source, Exhaust, Pump, Sensor\nOr an alias which should be declared before use.", E@location);
				msgs += msg;
			}
		}
	}

	tree@messages += msgs;
	iprintln(msgs);
	
	return tree;
}