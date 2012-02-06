module lang::lwc::structure::Extern

import lang::lwc::structure::Load;
import lang::lwc::structure::AST;

public map[str,str] structureElements(loc input) {
	
	Structure ast = load(input);
	
	map[str,str] elementNames = ();
	
	visit(ast)
	{
		case element(_, ElementName etype, str name, _):
			elementNames[name] = etype.id;
	}
	
	return elementNames;
} 

