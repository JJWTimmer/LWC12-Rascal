module lang::lwc::Constants
//	NAME MAY BE CHANGED!

import lang::lwc::Definition;

list[str] getPropertyNames(str elementName) {
	list[str] result = [];
	ElementDefinition elemDef = Elements[elementName];
	
	visit(elemDef) {
		case requiredAttrib(str name, _) : result += name;
	 	case optionalAttrib(str name, _, _) : result += name;
	 	case sensorPoint(str name, _) : result += name;
	 	case selfPoint(_) : result += "[self]";
	}
	
	return result;
}

public list[str] ElementNames = [key | key <- Elements];
public map[str, list[AttributeDefinition]] OptionalAttribs = ( key : [ O | O:optionalAttrib(_,_,_) <- Elements[key].attributes ] | key <- Elements );
public map[str, list[ConnectionPointDefinition]] DefinedConnectionPoints = ( key : Elements[key].connectionpoints | key <- Elements);
public map[str, list[str]] ElementProperties = ( key : getPropertyNames(key) | key <- Elements );