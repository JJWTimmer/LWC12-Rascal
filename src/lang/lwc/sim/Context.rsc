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
data SensorValue = sensorVal(str name);
data ManualValue = manualVal(str name);

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
					+ [simProp(N,  createSimBucket(V)) | realproperty(N, valuelist([V, _*]))  <- attributes]
				;
				
				elements += state(name, \type, props);	
			} 
			else 
			{
				// sensors += sensor(name, valuelist([]));
				;
			}
		}
	}
	
	return simContext(elements, sensors, manuals);
}

data SimBucket 
	= simBucketBoolean(bool b)
	| simBucketNumber(num n)
	| simBucketVariable(str v);

SimBucket createSimBucket(Value v)
{
	switch (v)
	{
		case \false(): 				return simBucketBoolean(false);
		case \true(): 				return simBucketBoolean(true);
		case metric(integer(N), _): return simBucketNumber(N);
		case variable(str N): 		return simBucketVariable(N);
		
		default: throw "Unsupported value <v>";
	}
}
	
public SimBucket getSimContextBucket(str element, str property, SimContext ctx)
{
	if (/state(element, _, L) := ctx.elements)
		if (/simProp(property, V) := L)
			return V;
	
	throw "Property not found in simulation context";
}

public value getSimContextBucketValue(str element, str property, SimContext ctx)
{
	switch (getSimContextBucket(element, property, ctx))
	{
		case simBucketBoolean(V): return V;
		case simBucketNumber(V): return V;
		case simBucketVariable(V): return V;
		
		default: throw "Unsupported property <v>";
	}
}

// This is a prototyp only, implementation follows
public SimContext setSimContextBucket(str element, str property, SimBucket val, SimContext ctx) {
	return ctx;
}
