module lang::lwc::controller::Checker

import lang::lwc::controller::AST;
import lang::lwc::controller::Load;
import lang::lwc::Constants;

import Message;
import List;
import Set;
import IO;

/*
	TODO:
		get map from element variables as defined in structure file, to element type of these variables
		check for unused states or variables (not yet fixed!)
		look at how to make clear isDuplicate modifies the Context
*/

data Context = context(
	set[str] stateNames,
	set[str] variableNames,
	
	set[Message] messages);
	
anno set[Message] start[Controller]@messages;
anno loc node@location;
	
Context initContext() = context({}, {}, {});

public start[Controller] check(start[Controller] parseTree) {
	Controller ast = implode(parseTree);
	Context context = initContext();
	
	context = checkNames(context, ast);
	
	return parseTree[@messages = context.messages];
}

Context checkNames(Context context, Controller tree) {	
	context = collectNames(context, tree);
	context = validateNames(context, tree);
	context = findUnusedNames(context,tree);
		
	return context;
}

Context collectNames(Context context, Controller tree) {
	bool isDuplicate(str name) = name in (
		context.stateNames + 
		context.variableNames);
		
	set[str] checkDuplicate(str name, node N) {
		if (isDuplicate(name)) {
			context.messages += { error("Duplicate name\nThe name <name> is already in use", N@location) }; 
		 	return {};
		} else {
			return {name};
		}
	}

	top-down visit(tree) {
		//Check for duplicate names for states, conditions and variables
		case S:state(statename(str name), _) : context.stateNames += checkDuplicate(name, S);
		case C:condition(str name, _) : context.variableNames += checkDuplicate(name, C);
		case D:declaration(str name, _) : context.variableNames += checkDuplicate(name, D);
	}
	
	return context;
}

Context validateNames(Context context, Controller tree) {
	//this should contain all used variable names in the structure file
	//and their ElementType
	map[str,str] allowedElements = ();

	//Validate names
	visit(tree) {
		//Validate state names
		case G:goto(statename(str name)) : {
			if(name notin context.stateNames) {
				str msg = invalidNameMessage("state", toList(context.stateNames));
				context.messages += { error(msg, G@location) };
			}
		}
		
		//Validate variable names
		case V:variable(str name) : {
			if(name notin context.variableNames) {
				str msg = invalidNameMessage("variable", toList(context.variableNames));
				context.messages += { error(msg, V@location) };
			}
		}
		
		//Validate property names
		case P:property(str element, str attribute) : {
			str msg;
			if(element notin allowedElements) {
				msg = invalidNameMessage("variable", toList(context.variableNames));
			}
			else {
				str elementType = allowedElements[element];
				allowedProperties = ElementProperties[elementType];
				 
				if(attribute notin allowedProperties) {
					msg = invalidNameMessage("property", allowedProperties);					  
				}
			}
			context.messages += { error(msg, P@location) };
		}
	}
	
	return context;
}

Context findUnusedNames(Context context, Controller tree) {
	set[str] usedNames = {};
	
	visit(tree) {
		case goto(statename(str name, _)) : usedNames += name;
		case variable(str name) : usedNames += name;
		case property(str name, _) : usedNames += name; //should this be here?
	}
	
	visit(tree) {
		case S:state(statename(str name, _)) : {
			if(name notin usedNames) {
				str msg = unusedNameMessage(name);
				context.messages += { error(msg, S@location) };
			}
		}
		case C:condition(str name, _) : {
			if(name notin usedNames) {
				str msg = unusedNameMessage(name);
				context.messages += { error(msg, C@location) };
			}
		}
		case D:declaration(str name, _) : {
			if(name notin usedNames) {
				str msg = unusedNameMessage(name);
				context.messages += { error(msg, D@location) };
			}
		}
	}

	return context;
}

str invalidNameMessage(str name, list[str] allowedNames) {
	str allowed = intercalate(", ", allowedNames);
	return "Invalid <name>
		   'Should be one of:
		   '<allowed>";
}

str unusedNameMessage(str name) {
	return "<name> is never used";
} 