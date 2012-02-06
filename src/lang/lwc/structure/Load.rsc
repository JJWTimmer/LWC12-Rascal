module lang::lwc::structure::Load

import lang::lwc::structure::AST;
import lang::lwc::structure::Parser;
import ParseTree;

public Structure implode(Tree tree) =
	implode(#Structure, tree); 

public Structure load(loc l) = implode(parse(l));
public Structure load(str s) = implode(parse(s));
