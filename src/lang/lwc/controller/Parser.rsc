module lang::lwc::controller::Parser

import lang::lwc::controller::Syntax;

import ParseTree;

public start[Controller] parse(str input) = parse(#start[Controller], input);
public start[Controller] parse(loc input) = parse(#start[Controller], input);
public start[Controller] parse(str input, loc origin) = parse(#start[Controller], input, origin);
