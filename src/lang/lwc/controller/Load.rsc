module lang::lwc::controller::Load

import lang::lwc::controller::AST;
import lang::lwc::controller::Parser;
import ParseTree;

public Controller implode(Tree tree) =
	implode(#Controller, tree); 

public Controller load(loc l) = implode(parse(l));
public Controller load(str s) = implode(parse(s));
