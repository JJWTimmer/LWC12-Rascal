module lang::lwc::structure::Extern

import lang::lwc::structure::Load;
import lang::lwc::structure::AST;
import lang::lwc::structure::Propagate;

public Structure loadStructure(loc input) = propagate(load(input));

public map[str,str] structureElements(loc input) {
	map[str,str] elementMap = ();
	Structure ast = loadStructure(input);
	
	for(/element(_, ElementName etype, str name, _) := ast) {
		elementMap[name] = etype.id;
	}
	
	return elementMap;
}

public map[str,list[str]] valvePositions(loc input) {
	map[str,list[str]] result = ();
	Structure ast = propagateConnectionPoints(load(input));
	
	for(/element(_, elementname("Valve"), str name, list[Attribute] attributes) := ast) {
		result += (name : ( [] | it + var | attribute(attributename("connections"), valuelist(values)) <- attributes, variable(str var) <- values ) );
	}
	
	return result;	
}
