module lang::lwc::controller::Checker

extend lang::lwc::controller::AST;
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
		check whether variables and properties get the correct values (integer, bool, connectionlist) assigned?
*/

data Context = context(
	set[str] stateNames,
	set[str] variableNames,
	map[str,str] variableTypes,
	
	set[Message] messages);
	
anno set[Message] start[Controller]@messages;
anno loc node@location;
	
Context initContext() = context({}, {}, (), {});

public start[Controller] check(start[Controller] parseTree) {
	Controller ast = implode(parseTree);
	Context context = initContext();
	
	context = checkNames(context, ast);
	
	return parseTree[@messages = context.messages];
}

Context checkNames(Context context, Controller ast) {	
	context = collectNamesAndTypes(context, ast);
	context = validateNames(context, ast);
	context = validateTypes(context, ast);
	context = findUnusedNames(context, ast);
	context = findUnreachableCode(context, ast);
		
	return context;
}

Context collectNamesAndTypes(Context context, Controller ast) {
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
		//Propagate a set of names and a map of name to type
		case state(S:statename(str name), _) : context.stateNames += checkDuplicate(name, S);
		case C:condition(str name, Expression expression) : {
			context.variableNames += checkDuplicate(name, C);
			context.variableTypes += (name : getType(expression));
		}
		case D:declaration(str name, Primary primary) : {
			context.variableNames += checkDuplicate(name, D);
			context.variableTypes += (name : getType(primary));
		}
	}
	
	return context;
}

str getType(value v) {
	if(/integer(_) := v) {
		return "integer";
	}
	else if(/boolean(_) := v) {
		return "boolean";
	}
	else if(/connections(_) := v) {
		return "connections";
	}
	return "";
}

Context validateNames(Context context, Controller ast) {
	//this should contain all used variable names in the structure file
	//and their ElementType
	map[str,str] elementMap = ();

	//Validate names
	visit(ast) {
		//Validate state names
		case goto(S:statename(str name)) :
			context.messages += invalidNameError(S, name, context.stateNames, "state");
		
		//Validate variable names
		case V:variable(str name) :
			context.messages += invalidNameError(V, name, context.variableNames, "variable");
		
		//Validate property names
		case P:property(str element, str attribute) : {
			if(element notin elementMap) {
				str msg = invalidNameMessage("variable", domain(elementMap));
				context.messages += { error(msg, P@location) };
			}
			else {
				str elementType = elementMap[element];
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
	else return {}; //validateType
}

str invalidNameMessage(str name, set[str] allowedNames) {
	str allowed = intercalate(", ", toList(allowedNames));
	return "Invalid <name>.
		   'Should be one of:
		   '<allowed>";
}

Context validateTypes(Context context, Controller ast) {
	//Where to get info on what type a property should be? 
	//Because a property can also be a list of connections, instead of an Expression
	//This info will come from Definition/Constants or the structure file
	
	visit(ast) {
		case S:assign(left, right) : context.messages += validateType(context, S, left, right);
		case S:\append(left, right) : context.messages += validateType(context, S, left, right);
		case S:remove(left, right) : context.messages += validateType(context, S, left, right);
		case S:multiply(left, right) : context.messages += validateType(context, S, left, right);
	}
	
	return context;
}

set[Message] validateType(Context context, Statement S, lhsvariable(variable(str left)), Value right) {
	if(left in context.variableNames) {	
		return validateType(S, context.variableTypes[left], getType(right));
	}
	return {};
}

set[Message] validateType(Context context, Statement S, lhsproperty(property(str elem,str attr)), Value right) {
	//Where to get info on what type a property should be? 
	//Because a property can also be a list of connections, instead of an Expression
	//This info will come from Definition/Constants or the structure file

	str leftType = ""; //???
	
	return validateType(S, leftType, getType(right));
}

set[Message] validateType(Statement S, str left, str right) {
	if(left != right) {
		str msg = "Invalid type. Variable or property is of type <left>, not <right>";
		return { error(msg, S@location) };
	}
	return {};
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
		str msg = "State, variable or property <name> is never used";
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