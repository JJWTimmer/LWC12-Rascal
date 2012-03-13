module lang::lwc::controller::runtime::Run

import lang::lwc::controller::Load;
import lang::lwc::controller::AST;
import lang::lwc::controller::runtime::Data;
import lang::lwc::sim::Context;

import Relation;
import Set;
import IO;
import util::Math;

data Action = actionNoop()
			| actionTransition(str state)
			| actionData(SimData \data);

public SimContext step(SimContext ctx)
{
	if (inState(ctx.runtime)) {
		ctx = evaluateState(ctx);
	}
	else if (inTransition(ctx.runtime))
	{
		ctx.runtime.state = ctx.runtime.transition;
		ctx.runtime.transition = "";
	}
	
	ctx = simContextExecuteActions(ctx);
	
	return ctx;
}

private SimContext evaluateState(SimContext ctx)
{
	println("In state: <ctx.runtime.state>");
	//for (statement <- getOneFrom(ctx.runtime.states[ctx.runtime.state]))
	for (statements <- ctx.runtime.states[ctx.runtime.state])
	{
		for (statement <- statements) {
			switch (evaluateStatement(statement, ctx))
			{
				case actionTransition(str T): {
					ctx.runtime.transition = T; 
					return ctx;
				}
				
				case actionData(D):
					ctx.\data = D;
					
				case actionNoop(): ;
					// do nothing
					
				default: throw "Unsupported controller action!";
			}
		}
	}
	
	return ctx;
}

private Action evaluateStatement(Statement statement, SimContext ctx)
{
	switch (statement)
	{
		case ifstatement(expr, stmt):
			if (boolValueOf(evaluateExpression(expr, ctx)))
				return evaluateStatement(stmt, ctx);	
		
		case goto(statename(str T)):
			return actionTransition(T);
		
		case assign(Assignable left, Value right):
			return assignStatement(left, right, ctx);
		
		default: throw "Unsupported AST node <statement>";
	}
	
	return actionNoop();
}

private Action assignStatement(left, right, ctx)
{
	str elementName= "";
	str propName = "";
	
	if (/property(str E, str P) := left)
	{
		elementName = E;
		propName = P; 
	}
	
	value v;
	
	if (expression(E) := right)
		v = evaluateExpression(E, ctx);
	else if (connections(L) := right)
		v = L;
	else
		throw "Unsupported right handside for assignment: <right>";
	
	ctx = setSimContextBucketValue(elementName, propName, v, ctx);

	return actionData(ctx.\data);
}

private value evaluateExpression(Expression expr, SimContext ctx)
{
	eval = value (V){ return evaluateExpression(V, ctx); };
	boolEval = bool (V){ return boolValueOf(eval(V)); };
	numEval = num (V){ return numValueOf(eval(V)); };
	
	switch (expr)
	{
		case expvalue(Primary p): return valueOf(p, ctx);
		
		case \or(lhs, rhs): 	return boolEval(lhs) || boolEval(rhs);
		case \and(lhs, rhs): 	return boolEval(lhs) && boolEval(rhs);
		
		case lt(lhs, rhs): 		return numEval(lhs) < numEval(rhs);
		case gt(lhs, rhs): 		return numEval(lhs) > numEval(rhs);
		case leq(lhs, rhs):		return numEval(lhs) <= numEval(rhs);
        case geq(lhs, rhs):		return numEval(lhs) >= numEval(rhs);
        case eq(lhs, rhs):		return eval(lhs) == eval(rhs);
        case neq(lhs, rhs):		return eval(lhs) != eval(rhs);
        
		case not(lhs): 			return ! boolEval(lhs);
		case mul(lhs, rhs): 	return numEval(lhs) * numEval(rhs);
		case div(lhs, rhs): 	return numEval(lhs) / numEval(rhs);
		case mdl(lhs, rhs): 	return numEval(lhs) % numEval(rhs);
		case sub(lhs, rhs): 	return numEval(lhs) - numEval(rhs);
		case add(lhs, rhs): 	return numEval(lhs) + numEval(rhs);
	
		default: throw "Unsupported expression";
	}
}

public value valueOf(Primary p, SimContext ctx)
{
	switch (p)
	{
		case integer(I): 
			return I;
			
		case boolean(\true()):
			return true;
		
		case boolean(\false()):
			return false;
			
		case rhsvariable(variable(str N)): 
			return lookup(N, ctx);
		
		case rhsproperty(property(str element, str attribute)):
			return getSimContextBucketValue(element, attribute, ctx);
			
		default: throw "Unsupported type: <p>";
	}
}

public value lookup(str symbol, SimContext ctx)
{
	// Is the given symbol a condition?
	if (symbol in domain(ctx.runtime.conditions))
	{
		Expression E = getOneFrom(ctx.runtime.conditions[symbol]);
		return evaluateExpression(E, ctx);
	}
	
	return getSimContextBucketValue(symbol, ctx);
}

public bool boolValueOf(Primary p, SimContext ctx) = boolValueOf(valueOf(p, ctx));

public bool boolValueOf(value v) 
{
	switch (v)
	{
		case num V:_: return V > 0;
		case bool V:_: return V;
		case []: return false;
		default: throw "Could not convert to boolean <v>";
	}
}

public num numValueOf(value v)
{
	switch (v)
	{
		case num V:_: return V;
		case bool V:_: return V ? 1 : 0;
		case []: return 0;
		default: throw "Could not convert to numeric <v>";
	}
}
