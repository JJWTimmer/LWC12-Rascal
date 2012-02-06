module lang::lwc::structure::Implode

extend lang::lwc::structure::AST; 
extend lang::lwc::structure::Syntax;

import ParseTree;

public lang::lwc::structure::AST::Structure implode(start[Structure] tree) 
	= implode(#lang::lwc::structure::AST::Structure, tree);
