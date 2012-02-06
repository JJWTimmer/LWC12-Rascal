module lang::lwc::structure::Extern

import lang::lwc::structure::Load;
import lang::lwc::structure::AST;

public map[str,str] structureElements(loc input) {

	map[str,str] elementMap = ();
	
	visit(load(input)) {
		case element(_, ElementName etype, str name, _):
			elementMap[name] = etype.id;
	}
	
	return elementMap;
}
