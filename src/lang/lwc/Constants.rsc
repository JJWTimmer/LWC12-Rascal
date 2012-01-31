module lang::lwc::Constants
//	NAME MAY BE CHANGED!

import lang::lwc::Definition;

set[str] getPropertyNames(str elementName) {
	set[str] result = {};
	ElementDefinition elemDef = Elements[elementName];
	
	visit(elemDef) {
		case requiredAttrib(str name, _) : result += name;
	 	case optionalAttrib(str name, _, _) : result += name;
	 	case sensorPoint(str name, _) : result += name;
	 	case selfPoint(_) : result += "[self]";
	}
	
	return result;
}

public set[str] ElementNames = {key | key <- Elements};
public map[str, list[AttributeDefinition]] OptionalAttribs = ( key : [ O | O:optionalAttrib(_,_,_) <- Elements[key].attributes ] | key <- Elements );
public map[str, list[ConnectionPointDefinition]] DefinedConnectionPoints = ( key : Elements[key].connectionpoints | key <- Elements);
public map[str, set[str]] ElementProperties = ( key : getPropertyNames(key) | key <- Elements );

//locatie van getPropertyNames maakt uit voor herkenning in ElementProperties. ElementProperties veranderen
//in een functie verhelpt dit probleem, maar het is een bug. In het klein reconstrueren en bug report maken
