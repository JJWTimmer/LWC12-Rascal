module lang::lwc::controller::Checker

import lang::lwc::controller::AST;
import lang::lwc::controller::Load;
import lang::lwc::Constants;

import Message;
import List;
import Set;
import IO;
import Map;

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
	context = findUnreachableCode(context, ast);
		
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
	map[str,str] allowedElementNames = ();

	//Validate names
	visit(ast) {
		//Validate state names
		case goto(S:statename(str name)) :
			context.messages += invalidNameError(S, name, context.stateNames, "state");
		
		//Validate rhs variable names
		case V:variable(str name) :
			context.messages += invalidNameError(V, name, context.variableNames, "variable");
		
		//Validate property names
		case P:property(str element, str attribute) : {
			if(element notin allowedElementNames) {
				str msg = invalidNameMessage("variable", domain(allowedElementNames));
				context.messages += { error(msg, P@location) };
			}
			else {
				str elementType = allowedElementNames[element];
				set[str] allowedProperties = ElementProperties[elementType];	 
				context.messages += invalidNameError(P, attribute, allowedProperties, "property");
			}
		}
	}
	
	return context;
}

set[Message] invalidNameError(node N, str name, set[str] names, str nodeType) {
	if(name notin names) {
		str msg = invalidNameMessage(nodeType, names);
		return { error(msg, N@location) };
	}
	else return {};
}

str invalidNameMessage(str name, set[str] allowedNames) {
	str allowed = intercalate(", ", toList(allowedNames));
	return "Invalid <name>
		   'Should be one of:
		   '<allowed>";
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

Context unusedNameError(Context context, node N, str name, set[str] usedNames) {
	if(name notin usedNames) {
		str msg = "<name> is never used";
		context.messages += { error(msg, N@location) };
	}
	return context;
}

Context findUnreachableCode(Context context, Controller ast) { 
	for(/state(_,[S1*, G:goto(_), S, S2*]) <- ast) {
		str msg = "Unreachable code";
		context.messages += { error(msg, S@location) } + { error(msg, N@location) | N <- S2 };
	}
	return context;
}