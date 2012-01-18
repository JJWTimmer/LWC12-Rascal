import lang::lwc::structure::Syntax;
import lang::lwc::structure::AST;
import ParseTree;
tree = parse(#lang::lwc::structure::Syntax::Structure, |project://lwc-uva/lwc/example1.lwcs|);
ast = implode(#lang::lwc::structure::AST::Structure, tree);