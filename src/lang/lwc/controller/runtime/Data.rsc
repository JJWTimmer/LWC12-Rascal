module lang::lwc::controller::runtime::Data

import lang::lwc::controller::AST;

data RuntimeContext = createRuntimeContext(
	bool initialized,
	str state,
	str transition,
	
	rel[str, Expression] conditions,
	rel[str, list[Statement]] states 
);

public RuntimeContext createEmptyRuntimeContext() = createRuntimeContext(
	true,
	"", 
	"",
	
	{},
	{}
);

public RuntimeContext initRuntimeContext(Controller ast)
{
	// Collect states
	RuntimeContext runtimeCtx = createRuntimeContext(
		false,
		firstState(ast),
		"",
		
		{ <N, E> | /condition(N, E) <- ast },
		{ <N, S> | /state(statename(str N), Statements S) <- ast }
	);
	
	runtimeCtx.initialized = true;
	
	return runtimeCtx;
}


public bool inState(RuntimeContext ctx) = ctx.transition == "" && ctx.state != "";
public bool inTransition(RuntimeContext ctx) = ctx.transition != "" && ctx.state != "";

private str firstState(Controller ast) {
	for (/state(statename(str N), Statements S) <- ast) return N;
}

