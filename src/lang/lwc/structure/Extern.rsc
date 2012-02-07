module lang::lwc::structure::Extern

import lang::lwc::structure::Load;
import lang::lwc::structure::AST;
import lang::lwc::structure::Propagate;

public map[str,str] structureElements(loc input) {
	map[str,str] elementMap = ();
	Structure ast = propagateAliasses(load(input));
	
	for(/element(_, ElementName etype, str name, _) := ast) {
		elementMap[name] = etype.id;
	}
	
	return elementMap;
}

public map[str,list[str]] connections(loc input) {
	map[str,list[str]] result = ();
	Structure ast = propagateConnectionPoints(load(input));
	
	for(element(_, _, str name, list[Attribute] attributes) <- ast) {
		result += (name : ( [] | it + values | attribute(attributename("connections"), valuelist(values)) <- attributes ) );
	}
	
	return result;	
}
