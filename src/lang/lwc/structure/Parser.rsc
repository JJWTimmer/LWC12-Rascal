module lang::lwc::structure::Parser

import lang::lwc::structure::Syntax;
import ParseTree;


public Main parse(str input) = parse(#Main, input);
public Main parse(str input, loc l) = parse(#Main, input, l);
