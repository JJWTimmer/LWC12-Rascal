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

data SimBucket 
	= simBucketBoolean(bool b)
	| simBucketNumber(num n)
	| simBucketVariable(str v)
	| simBucketList(list[SimBucket] l)
	| simBucketNothing();

SimBucket createSimBucket(\false()) 				= simBucketBoolean(false);
SimBucket createSimBucket(\true()) 					= simBucketBoolean(true);
SimBucket createSimBucket(metric(integer(N), _)) 	= simBucketNumber(N);
SimBucket createSimBucket(variable(str N)) 			= simBucketVariable(N);
SimBucket createSimBucket([]) 						= simBucketNothing();
SimBucket createSimBucket(list[Value] L) 			= simBucketList([ createSimBucket(v) | v <- L]);

SimBucket createSimBucket(bool B)					= simBucketBoolean(B);
SimBucket createSimBucket(int N)					= simBucketNumber(N);


public SimContext createSimContext(Structure ast) 
{
	list[ElementState] elements = [];
	list[SensorValue] sensors = [];
	list[ManualValue] manuals = [];
	
	visit(ast) {

		case element(modifiers, elementname(\type), name, attributes) : {
			if (\type != "Sensor") 
			{
				list[str] ignoredAttributes = ["sensorpoints", "connections", "position"];
				
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

public list[SimProperty] getSimContextProperties(SimContext simCtx, str element) {
	list[ElementState] elements = simCtx.elements;
	list[SimProperty] result = [];
	
	if(/state(element, _, props) := elements) {
		result = props;
	}
	return result;
}

public SimBucket getSimContextBucket(str element, str property, SimContext ctx)
{
	if (/state(element, _, L) := ctx.elements)
		if (/simProp(property, V) := L)
			return V;
	
	throw "Property not found in simulation context";
}

public value getSimContextBucketValue(str element, str property, SimContext ctx)
	= bucketToValue(getSimContextBucket(element, property, ctx));

public list[value] getSimContextBucketList(SimBucket bucket) 
{
	switch (bucket)
	{
		case simBucketList(V): return [getSimValue(x) | x <- V];
		default: throw "Bucket not a list";
	}
}

// This is a prototype only, implementation follows
public SimContext setSimContextBucket(str element, str property, SimBucket val, SimContext ctx) = ctx;
	
//
// Private functions
//

private value bucketToValue(SimBucket bucket) 
{
	switch (bucket)
	{
		case simBucketBoolean(V): return V;
		case simBucketNumber(V): return V;
		case simBucketVariable(V): return V;
		case simBucketList(V): throw "For the bucketlist use getSimList";
		case simBucketNothing(): return nothing();
		
		default: throw "Unknown bucket type";
	}
}