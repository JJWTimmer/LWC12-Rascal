module lang::lwc::Constants
//	NAME MAY BE CHANGED!

import lang::lwc::Definition;

map[str,str] getProperties(str elementName) {
	map[str,str] result = ();
	ElementDefinition elemDef = Elements[elementName];
	
	visit(elemDef) {
		case requiredAttrib(str name, list[list[Unit]] unitList) : result += (name : getValueType(unitList));
	 	case optionalAttrib(str name, list[list[Unit]] unitList, ValueDefinition defaultValue) : result += (name : getValueType(unitList, defaultValue));
	 	case optionalModifierAttrib(str name, _, list[list[Unit]] unitList, ValueDefinition defaultValue) : result += (name : getValueType(unitList, defaultValue));
	 	case sensorPoint(str name, list[list[Unit]] unitList) : result += (name : getValueType(unitList));
	 	case selfPoint(_) : result += ("[self]" : "");
	}
	
	return result;
}

str getValueType(list[list[Unit]] unitList, ValueDefinition defaultValue) {
	str valueType = getValueType(unitList);
	if(valueType == "") {
		valueType = getValueType(defaultValue);
	}
	return valueType;
}

str getValueType(list[list[Unit]] unitList) {
	if(unitList == []) {
		return "";
	}
	return "num";
	//see if elements from unitList are in Units
}

str getValueType(numValue(_, _)) {
	return "num";
}

str getValueType(boolValue(_)) {
	return "bool";
}

str getValueType(listValue(_)) {
	return "list";
}

public set[str] ElementNames = {key | key <- Elements};
public map[str, list[AttributeDefinition]] OptionalAttribs = ( key : [ O | O:optionalAttrib(_,_,_) <- Elements[key].attributes ] | key <- Elements );
public map[str, list[ConnectionPointDefinition]] DefinedConnectionPoints = ( key : Elements[key].connectionpoints | key <- Elements);
public map[str, list[SensorPointDefinition]] DefinedSensorPoints = ( key : Elements[key].sensorpoints | key <- Elements);
public map[str, map[str,str]] ElementProperties = ( key : getProperties(key) | key <- Elements );