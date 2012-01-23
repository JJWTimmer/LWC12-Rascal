module lang::lwc::controller::Parser

import lang::lwc::controller::Syntax;
import ParseTree;

public start[Controller] parse(str input) = parse(input);
public start[Controller] parse(str input, loc origin) = parse(#start[Controller], input, origin);
