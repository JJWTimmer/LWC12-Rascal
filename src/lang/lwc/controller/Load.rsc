module lang::lwc::controller::Load

import lang::lwc::controller::AST;
import lang::lwc::controller::Parser;
import ParseTree;

public lang::lwc::controller::AST::Controller implode(Tree tree) =
	implode(#lang::lwc::controller::AST::Controller, tree); 

public lang::lwc::controller::AST::Controller load(loc l) = implode(parse(l));
public lang::lwc::controller::AST::Controller load(str s) = implode(parse(s));