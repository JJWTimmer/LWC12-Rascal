module lang::lwc::sim::Context

import lang::lwc::structure::AST;
import lang::lwc::controller::AST;
import lang::lwc::controller::runtime::Data;

import IO;
import util::Maybe;
import String;

public data SimContext = createSimContext(
	SimData \data,
	RuntimeContext runtime
);

data SimData = simData(
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
SimBucket createSimBucket(integer(N))				= simBucketNumber(N);
 
public SimContext initSimContext(Structure sAst, Controller cAst) 
{
	list[ElementState] elements = [];
	list[SensorValue] sensors = [];
	list[ManualValue] manuals = [];
		
	// Visit the structure AST
	visit(sAst) {

		case E:element(modifiers, elementname(\type), name, attributes) : {
			
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
	
	// Visit the controller AST
	visit (cAst) {
		case declaration(N, P):
			manuals += manualVal(N, createSimBucket(P));
	}
	
	return createSimContext(
		simData(elements, sensors, manuals),
		initRuntimeContext(cAst)
	);
}

public SimBucket getSimContextBucket(str element, str property, SimContext ctx)
{
	// Check if there's a regular element with the given element name
	if (/state(element, T, L) := ctx.\data.elements)
	{	
	
		if (/simProp(property, V) := L)
			return V;
			
		str message = "Property <element>.<property> not found in simulation context.\n"
			+ "The following properties are available:\n"
			+ " - " + intercalate("\n - ", [ P | /simProp(P, _) <- L]); 
			
		throw message;
	}
	
	// Check if there's a sensor with the given element name
	else if (/sensorVal(element, B) := ctx.\data.sensors)
	{
		return B;
	}
	
	// Check if there's a manual value with the given element name
	else if (/manualVal(element, B) := ctx.\data.manuals)
	{
		return B;
	}
	else
	{
		throw "Property <element>.<property> not found in simulation context. The element is not defined in the structure.";
	}
}

public value getSimContextBucketValue(str element, SimContext ctx)
	= getSimContextBucketValue(element, "", ctx);
	
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
		case simBucketBoolean(V): 	return V;
		case simBucketNumber(V): 	return V;
		case simBucketVariable(V): 	return V;
		case simBucketList(V): 		throw "For the bucketlist use getSimList";
		case simBucketNothing(): 	return nothing();
		
		default: throw "Unknown bucket type";
	}
}