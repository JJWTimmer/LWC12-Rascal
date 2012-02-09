module lang::lwc::structure::Parser

import lang::lwc::structure::Syntax;

import ParseTree;

public start[Structure] parse(str input) = parse(#start[Structure], input);
public start[Structure] parse(loc input) = parse(#start[Structure], input);
public start[Structure] parse(str input, loc origin) = parse(#start[Structure], input, origin);