module lang::lwc::controller::Parser

import lang::lwc::controller::Syntax;
import ParseTree;

public Controller parse(str input, loc origin) = parse(#Controller, input, origin);
public Controller parse(str input) = parse(#Controller, input);
