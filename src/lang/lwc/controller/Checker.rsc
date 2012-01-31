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

Context checkNames(Context context, Controller ast) {	
	context = collectNames(context, ast);
	context = validateNames(context, ast);
	context = findUnusedNames(context, ast);
		
	return context;
}

Context collectNames(Context context, Controller ast) {
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

	top-down visit(ast) {
		//Check for duplicate names for states, conditions and variables
		case state(S:statename(str name), _) : context.stateNames += checkDuplicate(name, S);
		case C:condition(str name, _) : context.variableNames += checkDuplicate(name, C);
		case D:declaration(str name, _) : context.variableNames += checkDuplicate(name, D);
	}
	
	return context;
}

Context validateNames(Context context, Controller ast) {
	//this should contain all used variable names in the structure file
	//and their ElementType
	map[str,str] allowedElements = ();

	//Validate names
	visit(ast) {
		//Validate state names
		case goto(S:statename(str name)) : {
			if(name notin context.stateNames) {
				str msg = invalidNameMessage("state", toList(context.stateNames));
				context.messages += { error(msg, S@location) };
			}
		}
		
		//Validate rhs variable names
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

Context findUnusedNames(Context context, Controller ast) {
	set[str] usedNames = {};
	
	//Create a set of state and variable names that are used
	visit(ast) {
		case goto(statename(str name)) : usedNames += name;
		case variable(str name) : usedNames += name;
	}
	
	//Look for names that are never used
	visit(ast) {
		case state(S:statename(str name), _) : { 
			context = unusedNameError(context, S, name, usedNames);
		}
		case C:condition(str name, _) : {
			context = unusedNameError(context, C, name, usedNames);
		}
		case D:declaration(str name, _) : {
			context = unusedNameError(context, D, name, usedNames);
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

Context unusedNameError(Context context, node N, str name, set[str] usedNames) {
	if(name notin usedNames) {
		str msg = "<name> is never used";
		context.messages += { error(msg, N@location) };
	}
	return context;
}