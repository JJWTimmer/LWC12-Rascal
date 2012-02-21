module lang::lwc::sim::Context

import lang::lwc::structure::AST;
import IO;

data SimContext = simContext(
	list[ElementState] elements, 
	list[SensorValue] sensors, 
	list[ManualValue] manuals
);

data ElementState = state(str name, str \type, list[SimProperty] props);
data SimProperty = simProp(str name, Bucket bucket);
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
				
				props = [ simProp(N, createBucket(V)) | attribute(attributename(N), valuelist([V, _*])) <- attributes, N notin ignoredAttributes ]
					+ [simProp(N,  createBucket(V)) | realproperty(N, valuelist([V, _*]))  <- attributes]
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

data Bucket 
	= bucketBoolean(bool b)
	| bucketNumber(num n)
	| bucketVariable(str v);

Bucket createBucket(Value v)
{
	switch (v)
	{
		case \false(): 	return bucketBoolean(false);
		case \true(): 	return bucketBoolean(true);
		case metric(integer(N), _): return bucketNumber(N);
		case variable(str N): return bucketVariable(N);
		
		default: throw "Unsupported value <v>";
	}
}
	
public value getSimContextProperty(str element, str property, SimContext ctx)
{
	if (/state(element, _, L) := ctx.elements)
		if (/simProp(property, V) := L)
			return V;
	
	throw "Property not found in simulation context";
}
