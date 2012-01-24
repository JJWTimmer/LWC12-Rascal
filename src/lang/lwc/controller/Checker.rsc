module lang::lwc::controller::Checker

import lang::lwc::controller::AST;
import lang::lwc::controller::Load;
import lang::lwc::Util;

import Message;

/*
	TODO: get map from element variables as defined in structure file, to element type of these variables
*/

data Context = context(
	set[str] statenames,
	set[str] conditionnames,
	set[str] variablenames,
	//map[str,str] properties,
	
	set[Message] messages);
	
anno set[Message] start[Controller]@messages;
anno loc node@location;
	
Context initContext() = context({}, {}, {}, {});

public start[Controller] check(start[Controller] parseTree) {
	
	Controller ast = implode(parseTree);
	Context context = initContext();
	
	context = checkNames(context, ast);
	
	return parseTree[@messages = context.messages];
}

Context checkNames(Context context, Controller tree) {

	map[str,set[str]] allowedProperties = (
		"Boiler": {"capacity", 
				   "watertemp", 
				   "self"},
		"CentralHeatingUnit": {"burnertemp",
							   "power",
							   "ignite",
							   "ignitiondetect",
							   "interntaltemp"
								},
		"Exhaust": {},
		"Joint": {"connections"},
		"Pipe": {"diameter", 
				 "length", 
				 "self"},
		"Pump": {"capacity",
				 "self"},
		"Radiator": {"heatcapacity",
					 "self"},
		"Sensor": {"on",
				   "unit",
				   "range"},
		"Source": {"flowrate"},
		"Valve": {"position"}
	);
	
	//this should contain all used variable names in the structure file
	//and their ElementType
	map[str,str] allowedElements = ();
	
	bool isDuplicate(str name) = name in (
		context.statenames + 
		context.conditionnames +
		context.variablenames);
		
	set[str] checkDuplicate(str name, node N) {
		if (isDuplicate(name)) {
			context.messages += { error("Duplicate name\nThe name <name> is already in use", N@location) }; 
		 	return {};
		} else {
			return {name};
		}
	}
		
	visit(tree) {
		//Check for duplicate names for states, conditions and variables
		case S:state(statename(str name), _) : context.statenames += checkDuplicate(name, S);
		case C:condition(str name, _) : context.conditionnames += checkDuplicate(name, C);
		case D:declaration(str name, _) : context.variablenames += checkDuplicate(name, D);
		
		//Validate state names
		case G:goto(statename(str name)) : {
			if(name notin context.statenames) {
				str msg = "Invalid state\n" +
						  "Should be one of:\n" +
						  implode(context.statenames, ", ");
				context.messages += { error(msg, G@location) };
			}
		}
		
		//Validate variable names
		case V:variable(str name) : {
			if(name notin context.variablenames) {
				str msg = "Invalid variable\n" +
						  "Should be one of:\n" + 
						  implode(context.variablenames, ", ");
				context.messages += { error(msg, V@location) };
			}
		}
		/*
		//Validate property names
		case P:property(str element, str attribute) : {
			str msg;
			if(element notin allowedElements) {
				msg = "Invalid variable\n" +
					  "Should be one of:\n" +
					  implode(context.variablenames, ", ");
			}
			else {
				set[str] properties = allowedProperties[allowedElements[element]];
				if(attribute notin properties) {
					msg = "Invalid property\n" +
						  "Should be one of:\n" +
						  implode(properties, ", ");
				}
			}
			context.messages += { error(msg, P@location) };
		}*/
	}
	
	return context;
}

