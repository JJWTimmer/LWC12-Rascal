module lang::lwc::structure::Implode

import lang::lwc::structure::AST; 
import lang::lwc::structure::Syntax;
import ParseTree;

public lang::lwc::structure::AST::Structure implode(start[Structure] tree) 
	= implode(#lang::lwc::structure::AST::Structure, tree);
