module lang::lwc::controller::Checker

import lang::lwc::controller::AST;
import lang::lwc::controller::Load;
import lang::lwc::Constants;

import lang::lwc::structure::Extern;

import Message;
import List;
import Set;
import IO;
import Map;
import String;

anno loc start[Controller]@\loc;

data Context = context(
	map[str,str] elementMap,
	set[str] stateNames,
	set[str] variableNames,
	map[str,str] variableTypes,
	map[str,list[str]] valvePositions,
	
	set[Message] messages);
	
anno set[Message] start[Controller]@messages;
anno loc node@location;
	
Context initContext() = context((), {}, {}, (), (), {});

public start[Controller] check(start[Controller] parseTree) {

	Context context = initContext();
	Controller controllerAst = implode(parseTree);
	
	loc structureLocation = parseTree@\loc;
	structureLocation.path = substring(structureLocation.path, 0, size(structureLocation.path) - 1) + "s";
	
	if (! isFile(structureLocation)) {
		context.messages += { error("Structure file not found", parseTree@\loc) };
	} else {
		context.elementMap = structureElements(structureLocation);	
		context.valvePositions = valvePositions(structureLocation);
	}
	
	context = runChecks(context, controllerAst);
	
	return parseTree[@messages = context.messages];
}

Context runChecks(Context context, Controller ast) {	
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
			context.messages += { error("Duplicate name.
										'The name <name> is already in use", N@location) }; 
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
			context.variableTypes[name] = getType(context, expression);
		}
		case D:declaration(str name, Primary primary) : {
			context.variableNames += checkDuplicate(name, D);
			context.variableTypes[name] = getType(context, primary);
		}
	}
	
	return context;
}

str getType(Context context, Expression e) {
	switch(e) {
		case expvalue(p)  : return getType(context, p);
		case mul(l,_)	  : return "num";
		case div(l,_)	  : return "num";
		case mdl(l,_)	  : return "num";
		case add(l,_)	  : return "num";
		case sub(l,_)	  : return "num";
		case Expression x : return "bool"; 
	}

}

str getType(Context context, value v) {
	if(/integer(_) := v) {
		return "num";
	}
	else if(/boolean(_) := v) {
		return "bool";
	}
	else if(/connections(_) := v) {
		return "list";
	}
	else if(/rhsvariable(variable(str var)) := v) {
		if(var in context.variableTypes) {
			return context.variableTypes[var];
		}
	}
	else if(/rhsproperty(property(str elem, str attr)) := v) {
		if(elem in context.elementMap) {
			map[str,str] properties = getProperties(context, elem);
			if(attr in properties) {
				return properties[attr];
			}
		}
	}
	return "";
}

Context validateNames(Context context, Controller ast) {
	//Validate names
	visit(ast) {
		//Validate state names
		case goto(S:statename(str name)) :
			context.messages += invalidNameError(S, name, context.stateNames, "state");
		
		//Validate variable names
		case V:variable(str name) :
			context.messages += invalidNameError(V, name, context.variableNames + {key | key <- context.elementMap}, "variable");
		
		//Validate property names
		case P:property(str element, str attribute) : {
			set[Message] invalidElementMsg = invalidNameError(P, element, domain(context.elementMap), "variable");
			
			if(invalidElementMsg == {}) {
				set[str] allowedProperties = domain(getProperties(context, element));
				context.messages += invalidNameError(P, attribute, allowedProperties, "property");
			}
			else {
				context.messages += invalidElementMsg;
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

str invalidNameMessage(str \type, set[str] allowedNames) {
	str allowed = intercalate(", ", toList(allowedNames));
	return "Invalid <\type>.
		   'Should be one of:
		   '<allowed>";
}

Context validateTypes(Context context, Controller ast) {
	visit(ast) {
		case S:assign(left, right) : context.messages += validateType(context, S, left, right);
		case S:\append(left, right) : context.messages += validateType(context, S, left, right);
		case S:remove(left, right) : context.messages += validateType(context, S, left, right);
		case S:multiply(left, right) : context.messages += validateType(context, S, left, right);
		case S:ifstatement(condition, _) : {
			if(getType(context, condition) == "bool") {
				context.messages += validateExpression(context, condition);
			}
			else {
				str msg = "Invalid expression. Condition of if statement should be of type bool";
				context.messages += { error(msg, S@location) };
			}
		}
	}
	
	return context;
}

set[Message] validateType(Context context, Statement S, lhsvariable(variable(str left)), Value right) {
	set[Message] result = {};
	if(expression(e) := right) {
		result += validateExpression(context, e);
	}
	if(left in context.variableNames) {	
		result += validateType(S, context.variableTypes[left], getType(context, right));
	}
	return result;
}

set[Message] validateType(Context context, Statement S, lhsproperty(property(str elem,str attr)), Value right) {
	set[Message] result = {};
	if(expression(e) := right) {
		result += validateExpression(context, e);
	}
	if(elem in context.elementMap) {
		map[str,str] allowedProperties = getProperties(context, elem);
		if(attr in allowedProperties) {
			str leftType = allowedProperties[attr];
			if(context.elementMap[elem] == "Valve") {
				result += validateValvePositions(context, S, elem, right);
			}
			else {
				result += validateType(S, leftType, getType(context, right));
			}
		} 
	}	
	return result;
}

set[Message] validateValvePositions(Context context, Statement S, str element, connections(list[str] connections)) {
	set[Message] result = {};
	list[str] allowedPositions = context.valvePositions[element];
	for(conn <- connections) {
		if(conn notin allowedPositions) {
			str msg = "Invalid position <conn>. 
					  'Valve <element> can have positions <intercalate(", ", allowedPositions)>";
			result += { error(msg, S@location) };
		}
	}
	return result;
}

set[Message] validateType(Statement S, str left, str right) {
	if(left != right) {
		str msg = "Invalid type. Variable or property is of type <left>, not <right>";
		return { error(msg, S@location) };
	}
	return {};
}

set[Message] validateExpression(Context context, Expression e) {
	loc location = e@location;
	switch(e) {
		case expvalue(_) : return {};
		case not(inside) : {
			if(getType(context, inside) == "bool") {
				return validateExpression(context, inside);
			}
			return { error("Invalid expression.
						   'Cannot negate something not of type bool", location) };
		}
		case Expression x : return validateExpression(context, x.left, x.right, location);
	}
}

set[Message] validateExpression(Context context, Expression left, Expression right, loc parentExp) {
	set[Message] leftMsg = validateExpression(context, left);
	set[Message] rightMsg = validateExpression(context, right);
	
	if(leftMsg != {} || rightMsg != {}) {
		return leftMsg + rightMsg;
	}
	
	str leftType = getType(context, left);
	str rightType = getType(context, right);
	if(leftType != rightType) {
		str msg = "Invalid expression. 
				  'Cannot do this operation on type <leftType> and <rightType>";
		return { error(msg, parentExp) };
	}
	return {};
}

Context findUnusedNames(Context context, Controller ast) 
{
	set[str] usedNames = {};
	
	// Find first state
	if (/state(statename(str name), _) := ast)
		usedNames += { name };
	
	// Create a set of state and variable names that are used
	visit(ast) {
		case goto(statename(str name)): usedNames += name;
		case variable(str name): usedNames += name;
	}
	
	// Look for names that are never used
	visit(ast) {
		case state(S:statename(str name), _): 
			context = unusedNameError(context, S, name, usedNames);
		
		case C:condition(str name, _):
			context = unusedNameError(context, C, name, usedNames);
		
		case D:declaration(str name, _):
			context = unusedNameError(context, D, name, usedNames);
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

map[str,str] getProperties(Context context, str elementName) {
	str elementType = context.elementMap[elementName];
	return ElementProperties[elementType];
}
