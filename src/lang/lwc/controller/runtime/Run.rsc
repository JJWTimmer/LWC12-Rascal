module lang::lwc::controller::runtime::Run

import IO;
import lang::lwc::controller::Load;
import lang::lwc::controller::AST;
import lang::lwc::sim::Context;
import Relation;
import Set;
import IO;
import util::Math;

data Action = \continue() | transition(str state);

data RuntimeContext = createRuntimeContext(
	bool initialized,
	str state,
	str transition,
	
	rel[str, value] declarations,
	rel[str, Expression] conditions,
	rel[str, list[Statement]] states 
);

public RuntimeContext initRuntimeContext(Controller ast, SimContext simCtx)
{
	// Collect states
	RuntimeContext runtimeCtx = createRuntimeContext(
		false,
		firstState(ast),
		"",
		
		{},
		{ <N, E> | /condition(N, E) <- ast },
		{ <N, S> | /state(statename(str N), Statements S) <- ast }
	);
	
	runtimeCtx.declarations = { <N, valueOf(P, runtimeCtx, simCtx)> | /declaration(N, P) <- ast };
	runtimeCtx.initialized = true;
	
	return runtimeCtx;
}

public RuntimeContext step(RuntimeContext runtimeCtx, SimContext simCtx)
{
	if (inState(runtimeCtx)) {
		runtimeCtx = evaluateState(runtimeCtx, simCtx);
	}
	
	else if (inTransition(runtimeCtx))
	{
		runtimeCtx.state = runtimeCtx.transition;
		runtimeCtx.transition = "";
	}
	
	return runtimeCtx;
}

public bool inState(RuntimeContext ctx) = ctx.transition == "" && ctx.state != "";
public bool inTransition(RuntimeContext ctx) = ctx.transition != "" && ctx.state != "";

private str firstState(Controller ast) {
	for (/state(statename(str N), Statements S) <- ast) return N;
}

private RuntimeContext evaluateState(RuntimeContext runtimeCtx, SimContext simCtx)
{
	for (statement <- getOneFrom(runtimeCtx.states[runtimeCtx.state]))
	{
		switch (evaluateStatement(statement, runtimeCtx, simCtx))
		{
			case transition(str T): {
				iprintln("We\'re going to: <T>");
				runtimeCtx.transition = T; 
				return runtimeCtx;
			}
			
			case \continue():
				// do nothing
				println("Do nothing");
				
			default: throw "Unsupported action!";
		}
	}
	
	return runtimeCtx;
}

private Action evaluateStatement(Statement statement, RuntimeContext runtimeCtx, SimContext simCtx)
{
	switch (statement)
	{
		case ifstatement(expr, stmt):
			if (boolValueOf(evaluateExpression(expr, runtimeCtx, simCtx)))
				return evaluateStatement(stmt, runtimeCtx, simCtx);	
		
		case goto(statename(str T)):
			return transition(T);
		
		case assign(Assignable left, Value right): {
			println("ASSIGN");
		}
		
		default: throw "Unsupported AST node <statement>";
	}
	
	return \continue();
}

private value evaluateExpression(Expression expr, RuntimeContext runtimeCtx, SimContext simCtx)
{
	eval = value(V) { return evaluateExpression(V, runtimeCtx, simCtx); };
	boolEval = bool(V) { return boolValueOf(eval(V)); };
	numEval = num(V) { return numValueOf(eval(V)); };
	
	switch (expr)
	{
		case expvalue(Primary p): return boolValueOf(p, runtimeCtx, simCtx);
		
		case \or(lhs, rhs): 	return boolEval(lhs) || boolEval(rhs);
		case \and(lhs, rhs): 	return boolEval(lhs) && boolEval(rhs);
		
		case lt(lhs, rhs): 		return eval(lhs) < eval(rhs);
		case gt(lhs, rhs): 		return eval(lhs) > eval(rhs);
		case leq(lhs, rhs):		return eval(lhs) <= eval(rhs);
        case geq(lhs, rhs):		return eval(lhs) >= eval(rhs);
        case eq(lhs, rhs):		return eval(lhs) == eval(rhs);
        case neq(lhs, rhs):		return eval(lhs) != eval(rhs);
        
		case not(lhs, rhs): 	return ! boolEval(lhs);
		case mul(lhs, rhs): 	return eval(lhs) * eval(rhs);
		case div(lhs, rhs): 	return numEval(lhs) / numEval(rhs);
		case mdl(lhs, rhs): 	return numEval(lhs) % numEval(rhs);
		case sub(lhs, rhs): 	return numEval(lhs) - numEval(rhs);
		case add(lhs, rhs): 	return numEval(lhs) + numEval(rhs);
	
		default: throw "Unsupported expression";
	}
}

public value valueOf(Primary p, RuntimeContext runtimeCtx, SimContext simCtx)
{
	switch (p)
	{
		case integer(int I): 
			return I;
		
		case rhsvariable(variable(str N)): 
			return lookup(N, runtimeCtx, simCtx);
		
		case rhsproperty(property(str element, str attribute)):
		{
			println("ControllerRuntime: valueof(rhsproperty(property(<element>, <attribute>)))");
			
			return getSimContextBucketValue(element, attribute, simCtx);
		}
			
		default: throw "Unsupported type: <p>";
	}
}

public value lookup(str symbol, RuntimeContext runtimeCtx, SimContext simCtx)
{
	// Is the give symbol a condition?
	if (symbol in domain(runtimeCtx.conditions))
	{
		Expression E = getOneFrom(runtimeCtx.conditions[symbol]);
		value V = evaluateExpression(E, runtimeCtx, simCtx);
		
		println("Condition <symbol> = <V>");
		
		return V;
	}
	
	if (symbol in domain(runtimeCtx.declarations))
		return getOneFrom(runtimeCtx.declarations[symbol]);
	
	throw "Symbol not found <symbol>";
}

public bool boolValueOf(Primary p, RuntimeContext runtimeCtx, SimContext simCtx) = boolValueOf(valueOf(p, runtimeCtx, simCtx));

public bool boolValueOf(value v) 
{
	switch (v)
	{
		case int V:_: return V > 0;
		case bool V:_: return V;
		default: throw "Could not convert to boolean <v>";
	}
}

public num numValueOf(value v)
{
	switch (v)
	{
		case bool V:_: return V ? 1 : 0;
		default: throw "Could not convert to numeric <v>";
	}
}
