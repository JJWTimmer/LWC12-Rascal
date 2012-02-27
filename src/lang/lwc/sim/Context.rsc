module lang::lwc::sim::Context

import lang::lwc::structure::AST;
import IO;

data SimContext = simContext(
	list[ElementState] elements, 
	list[SensorValue] sensors, 
	list[ManualValue] manuals
);

data ElementState = state(str name, str \type, list[SimProperty] props);
data SimProperty = simProp(str name, SimBucket bucket);
data SensorValue = sensorVal(str name, SimBucket bucket);
data ManualValue = manualVal(str name, SimBucket bucket);

public SimContext createSimContext(Structure ast) 
{
	list[ElementState] elements = [];
	list[SensorValue] sensors = [];
	list[ManualValue] manuals = [];
	
	visit(ast) {

		case element(modifiers, elementname(\type), name, attributes) : {
			if (\type != "Sensor") 
			{
				list[str] ignoredAttributes = ["sensorpoints", "connections"];
				
				props = [ simProp(N, createSimBucket(V)) | attribute(attributename(N), valuelist([V, _*])) <- attributes, N notin ignoredAttributes ]
					  + [ simProp(N, createSimBucket(V)) | realproperty(N, valuelist([V, _*]))  <- attributes]
					  + [ simProp(N, createSimBucket(V)) | attribute(attributename(N), valuelist(V)) <- attributes, N in ignoredAttributes ]
				;
				
				elements += state(name, \type, props);	
			} 
			else 
			{
				sensors += sensorVal(name, createSimBucket([]));
			}
		}
	}
	
	return simContext(elements, sensors, manuals);
}

data SimBucket 
	= simBucketBoolean(bool b)
	| simBucketNumber(num n)
	| simBucketVariable(str v)
	| simBucketList(list[SimBucket] l)
	| simBucketNothing();

SimBucket createSimBucket(\false()) = simBucketBoolean(false);
SimBucket createSimBucket(\true()) = simBucketBoolean(true);
SimBucket createSimBucket(metric(integer(N), _)) = simBucketNumber(N);
SimBucket createSimBucket(variable(str N)) = simBucketVariable(N);
SimBucket createSimBucket(list[Value] L) = simBucketList([ createSimBucket(v) | v <- L]);
SimBucket createSimBucket([]) = simBucketNothing();

	
public SimBucket getSimContextBucket(str element, str property, SimContext ctx)
{
	if (/state(element, _, L) := ctx.elements)
		if (/simProp(property, V) := L)
			return V;
	
	throw "Property not found in simulation context";
}

public value getSimContextBucketValue(str element, str property, SimContext ctx)
{
	val = getSimContextBucket(element, property, ctx);
	
	value getValue(SimBucket bucket) 
	{
		switch (bucket)
		{
			case simBucketBoolean(V): return V;
			case simBucketNumber(V): return V;
			case simBucketVariable(V): return V;
			case simBucketList(V): return [getValue(x) | x <- V];
			case simBucketNothing(): return nothing();
			
			default: throw "Unknown bucket type";
		}
	}
	
	return getValue(val);
}

// This is a prototyp only, implementation follows
public SimContext setSimContextBucket(str element, str property, SimBucket val, SimContext ctx) {
	return ctx;
}
