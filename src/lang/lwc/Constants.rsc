module lang::lwc::Constants
//	NAME MAY BE CHANGED!

import lang::lwc::Definition;

import Set;

map[str,str] getProperties(str elementName) {
	map[str,str] result = ();
	ElementDefinition elemDef = Elements[elementName];
	
	visit(elemDef) {
		case requiredAttrib(str name, list[list[Unit]] unitList, _) : result += (name : getValueType(unitList));
	 	case optionalAttrib(str name, list[list[Unit]] unitList, ValueDefinition defaultValue, _) : result += (name : getValueType(unitList, defaultValue));
	 	case optionalModifierAttrib(str name, _, list[list[Unit]] unitList, ValueDefinition defaultValue, _) : result += (name : getValueType(unitList, defaultValue));
	 	case sensorPoint(str name, list[list[Unit]] unitList) : result += (name : getValueType(unitList));
	 	case selfPoint(list[list[Unit]] unitList) : result += ("self" : getValueType(unitList));
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

set[str] getEditableProps(str elementName) {
	ElementDefinition elemDef = Elements[elementName];
	set[str] result = {};
	
	visit(elemDef) {
		case requiredAttrib(str name, _, true) : result += name;
		case optionalAttrib(str name, _, _, true) : result += name;
		case optionalModifierAttrib(str name, _, _, _, true) : result += name;
		case sensorPoint(str name, _) : result += name;
		case selfPoint(_) : result += "self";
		case hiddenProperty(str name, _, _) : result += name;
	}
	
	return result;
}

public set[str] ElementNames = {key | key <- Elements};

public map[str, list[AttributeDefinition]] OptionalAttribs = {
	map[str, list[AttributeDefinition]] pmap = ();
	for (key <- Elements) {
		list[AttributeDefinition] plist = [];
		for (H:optionalAttrib(_,_,_,_)   <- Elements[key].attributes) {
			plist += H;
		}
		pmap[key] = plist;
	}
	
	pmap;
};

public map[str, list[AttributeDefinition]] RequiredAttribs = {
	map[str, list[AttributeDefinition]] pmap = ();
	for (key <- Elements) {
		list[AttributeDefinition] plist = [];
		for (H:requiredAttrib(_,_,_)  <- Elements[key].attributes) {
			plist += H;
		}
		pmap[key] = plist;
	}
	
	pmap;
};

public map[str, list[AttributeDefinition]] HiddenProps = {
	map[str, list[AttributeDefinition]] pmap = ();
	
	for (key <- Elements) {
		pmap[key] = for (H:hiddenProperty(_,_,_) <- Elements[key].attributes)
			append(H);
	}
	
	pmap;
};

public map[str, list[ConnectionPointDefinition]] DefinedConnectionPoints = ( key : {
		list[ConnectionPointDefinition] el = []; //workaround for list[void]
		(el | it + toList(s) | s <- Elements[key].connectionpoints);
	} | key <- Elements);
public map[str, list[SensorPointDefinition]] DefinedSensorPoints = ( key : Elements[key].sensorpoints | key <- Elements);
public map[str, map[str,str]] ElementProperties = ( key : getProperties(key) | key <- Elements );
public map[str, list[set[str]]] ElementModifiers = ( key : Elements[key].modifiers | key <- Elements );
public map[str, set[str]] EditableProps = ( key : getEditableProps(key) | key <- Elements );
