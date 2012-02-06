extend lang::lwc::controller::Syntax;
extend lang::lwc::controller::AST;
import ParseTree;
tree = parse(#start[Controller], |project://lwc-uva/lwc/example1.lwcc|);
ast = implode(#lang::lwc::controller::AST::Controller, tree);