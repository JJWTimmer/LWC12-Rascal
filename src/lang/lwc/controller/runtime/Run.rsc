module lang::lwc::controller::runtime::Run

import IO;
import lang::lwc::controller::Load;
import lang::lwc::controller::AST;
import Relation;
import Set;
import util::Math;

data Action = \continue() | transition(str state);

data RuntimeContext = runtimeContext(
	bool initialized,
	str state,
	str transition,
	
	rel[str, value] declarations,
	rel[str, Expression] conditions,
	rel[str, list[Statement]] states 
);

public RuntimeContext initRuntimeContext(Controller ast)
{
	// Collect states
	RuntimeContext ctx = runtimeContext(
		false,
		firstState(ast),
		"",
		
		{},
		{ <N, E> | /condition(N, E) <- ast },
		{ <N, S> | /state(statename(str N), Statements S) <- ast }
	);
		
	ctx.declarations = { <N, valueOf(P, ctx)> | /declaration(N, P) <- ast };
	
	ctx.initialized = true;
	
	return ctx;
}

public RuntimeContext step(RuntimeContext ctx)
{
	if (inState(ctx)) {
		println("IN STATE: <ctx.state>");
		ctx = evaluateState(ctx);
	}
	
	else if (inTransition(ctx))
	{
		println("TRANSITION TO: <ctx.transition>");
		
		ctx.state = ctx.transition;
		ctx.transition = "";
	}
	
	return ctx;
}

public bool inState(RuntimeContext ctx) = ctx.transition == "" && ctx.state != "";
public bool inTransition(RuntimeContext ctx) = ctx.transition != "" && ctx.state != "";

private str firstState(Controller ast) {
	for (/state(statename(str N), Statements S) <- ast) return N;
}

private RuntimeContext evaluateState(ctx)
{
	for (statement <- getOneFrom(ctx.states[ctx.state]))
	{
		switch (evaluateStatement(statement, ctx))
		{
			case transition(str T): {
				iprintln("We\'re going to: <T>");
				ctx.transition = T; 
				return ctx;
			}
			
			case \continue():
				println("Do nothing");
				// do nothing
				
				
			default: throw "Unsupported action!";
		}
	}
	
	return ctx;
}

private Action evaluateStatement(Statement statement, RuntimeContext ctx)
{
	switch (statement)
	{
		case ifstatement(expr, stmt):
			if (boolValueOf(evaluateExpression(expr, ctx)))
				return evaluateStatement(stmt, ctx);	
		
		case goto(statename(str T)):
			return transition(T);
		
		case assign(Assignable left, Value right): {
			println("ASSIGN");
		}
		
		default: throw "Unsupported AST node <statement>";
	}
	
	return \continue();
}

private value evaluateExpression(Expression expr, RuntimeContext ctx)
{
	eval = value(V) { return evaluateExpression(V, ctx); };
	boolEval = bool(V) { return boolValueOf(eval(V)); };
	numEval = num(V) { return numValueOf(eval(V)); };
	
	switch (expr)
	{
		case expvalue(Primary p): return boolValueOf(p, ctx);
		
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

public value valueOf(Primary p, RuntimeContext ctx)
{
	switch (p)
	{
		case integer(int I): return I;
		case rhsvariable(variable(str N)): return lookup(N, ctx);
		
		// @todo get from structure context
		case rhsproperty(property(str element, str attribute)): return arbInt(90);
			
		default: throw "Unsupported type: <p>";
	}
}

public value lookup(str symbol, RuntimeContext ctx)
{
	// Is the give symbol a condition?
	if (symbol in domain(ctx.conditions))
	{
		Expression E = getOneFrom(ctx.conditions[symbol]);
		value V = evaluateExpression(E, ctx);
		
		println("Condition <symbol> = <V>");
		
		return V;
	}
	
	if (symbol in domain(ctx.declarations))
		return getOneFrom(ctx.declarations[symbol]);
	
	throw "Symbol not found <symbol>";
}

public bool boolValueOf(Primary p, RuntimeContext ctx) = boolValueOf(valueOf(p, ctx));

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
