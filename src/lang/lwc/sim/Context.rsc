module lang::lwc::sim::Context

import lang::lwc::structure::AST;
import lang::lwc::controller::AST;
import lang::lwc::controller::runtime::Data;
import lang::lwc::sim::Graph;

import IO;
import util::Maybe;
import String;
import Graph;
import Type;
import List;

data SimData = simData(
	list[ElementState] elements, 
	list[SensorRef] sensors, 
	list[ManualValue] manuals
);

public alias StepAction = SimContext (SimContext);

public SimData createEmptyData() = simData([], [], []);

public data SimContext = createSimContext(
	SimData \data,
	RuntimeContext runtime,
	list[SimContext (SimContext)] stepActions,
	Graph[ElementNode] reachGraph
);

public SimContext createEmptyContext() = createSimContext(
	createEmptyData(),
	createEmptyRuntimeContext(),
	[],
	{}
);

alias SimContextUpdate = void(SimContext context);
alias SimContextLookup = SimContext();

data ElementState = state(str name, str \type, list[SimProperty] props);

data SimProperty = simProp(str name, SimBucket bucket);
data SensorRef = sensorRef(str name, str element, str property);
data ManualValue = manualVal(str name, SimBucket bucket);

data SimBucket 
	= simBucketBoolean(bool b)
	| simBucketNumber(num n)
	| simBucketVariable(str v)
	| simBucketList(list[SimBucket] l);

public SimBucket createSimBucket(boolean(B)) 				= createSimBucket(B);
public SimBucket createSimBucket(\false()) 					= simBucketBoolean(false);
public SimBucket createSimBucket(\true()) 					= simBucketBoolean(true);
public SimBucket createSimBucket(metric(integer(N), _)) 	= simBucketNumber(N);
public SimBucket createSimBucket(metric(realnum(N), _)) 	= simBucketNumber(N);
public SimBucket createSimBucket(variable(str N)) 			= simBucketVariable(N);
public SimBucket createSimBucket([]) 						= simBucketList([]);
public SimBucket createSimBucket(list[Value] L) 			= simBucketList([ createSimBucket(v) | v <- L]);
public SimBucket createSimBucket(bool B)					= simBucketBoolean(B);
public SimBucket createSimBucket(num N)						= simBucketNumber(N);
public SimBucket createSimBucket(integer(N))				= simBucketNumber(N);
public default SimBucket createSimBucket(X)					{ throw "Unknown type: <X> := <typeOf(X)>"; }

public SimContext initSimContext(Structure sAst, Controller cAst) 
{
	list[ElementState] elements = [];
	list[SensorRef] sensors = [];
	list[ManualValue] manuals = [];
	
	list[str] ignoredAttributes = [
		"sensorpoints", 
		"connections", 
		"position"
	];	
	
	list[SimProperty] getProps(list[Attribute] attributes) =
		// Single attributes 
		[ simProp(N, createSimBucket(V)) | attribute(attributename(N), valuelist([V, _*])) <- attributes, N notin ignoredAttributes ]
		
		// Real properties
	  + [ simProp(N, createSimBucket(V)) | realproperty(N, valuelist([V, _*]))  <- attributes]
	  
	  	// Multiple properties
	  + [ simProp(N, createSimBucket(V)) | attribute(attributename(N), valuelist(V)) <- attributes, N in ignoredAttributes ];
	
	SimBucket getPropByName(str name, list[Attribute] attributes)
		= (/simProp(name, B) := getProps(attributes)) ? B : createSimBucket([]);
	
	// Visit the structure AST
	visit(sAst) 
	{
		case E:element(modifiers, elementname(\type), name, attributes): 
		{
			if (\type != "Sensor") 
				elements += state(name, \type, getProps(attributes));
			
			else 
			{
				// Find the connection point
				if (/attribute(attributename("on"), valuelist([variable(V)])) := attributes)
					throw "This attribute should have been propagated ...";
				
				else if (/attribute(attributename("on"), valuelist([property(V, propname(P))])) := attributes)
					sensors += sensorRef(name, V, P);
				
				else
					throw "Did not find or recongnize connection point for sensor <name>";
			}
		}
		
		case pipe(_, str name, _, _, list[Attribute] attributes): 
			elements += state(name, "Pipe", getProps(attributes));
	}
	
	// Visit the controller AST
	visit (cAst) {
		case declaration(N, P):
			manuals += manualVal(N, createSimBucket(P));
	}
	
	return createSimContext(
		simData(elements, sensors, manuals),
		initRuntimeContext(cAst),
		[],
		buildGraph(sAst)
	);
}

public SimContext registerStepAction(SimContext(SimContext) action, SimContext context)
{
	context.stepActions += [action];
	return context;
}

public SimContext simContextExecuteActions(SimContext context)
{
	for (action <- context.stepActions)
		context = action(context);
	
	return context;
}

@doc{Collect all properties of the given element}
public list[SimProperty] getSimContextProperties(SimData \data, str element) 
	= [ p | state(element, _, P:props) <- \data.elements, p <- P ];

public SimProperty getSimContextProperty(SimData \data, str E, str P)
{
	if (/state(E, _, L) := \data.elements)
	{	
		if (/S:simProp(P, _) := L)
			return S;
			
		throw "Property <E>.<P> not found in simulation context.\n"
			+ "The following properties are available:\n"
			+ " - " + intercalate("\n - ", [ P | /simProp(P, _) <- L]);
	}
	
	throw "Element <E> not found in simulation context.";
}

public SimBucket getSimContextBucket(str element, str property, SimContext ctx)
	= getSimContextBucket(element, property, ctx.\data);
	
public SimBucket getSimContextBucket(str element, str property, SimData \data)
{
	// Check if there's a regular element with the given element name
	if (/state(element, T, L) := \data.elements)
	{	
		if (/simProp(property, V) := L) {
			return V;
		}
			
		throw "Property <element>.<property> not found in simulation context.\n"
			+ "The following properties are available:\n"
			+ " - " + intercalate("\n - ", [ P | /simProp(P, _) <- L]);
	}
	
	// Check if there's a sensor with the given element name
	else if (/sensorRef(element, V, P) := \data.sensors) {
		return getSimContextBucket(V, P, \data); 
	}
	// Check if there's a manual value with the given element name
	else if (/manualVal(element, B) := \data.manuals) {
		return B;
	}	
	else
		throw "Property <element>.<property> not found in simulation context. The element is not defined in the structure.";
}

public value getSimContextBucketValue(str element, SimContext ctx)
	= getSimContextBucketValue(element, "", ctx);
	
public value getSimContextBucketValue(str element, str property, SimContext ctx)
	= bucketToValue(getSimContextBucket(element, property, ctx));

public list[value] getSimContextBucketList(str element, str property, SimContext ctx)
	= getSimContextBucketList(getSimContextBucket(element, property, ctx));

public list[value] getSimContextBucketList(SimBucket bucket) {
	if (simBucketList(V) := bucket)
		return [bucketToValue(x) | x <- V];
	else
		throw "Bucket not a list: <bucket>";
}

public SimContext setSimContextBucket(str element, str property, SimBucket val, SimContext ctx) 
{	
	bool done = false;

	ctx.\data = top-down-break visit (ctx.\data)
	{
		case S:state(element, _, [head*, P:simProp(property, _), tail*]):
		{
			P.bucket = val;
			S.props = head + P + tail;
			
			done = true;
			insert S;
		}
	}
		
	if (! done)
		throw "Could not set the given value <val> for <element>.<property>";

	return ctx;
}

public SimContext setSimContextBucketValue(str element, str property, value val, SimContext ctx) =
	setSimContextBucket(element, property, valueToBucket(val), ctx);
	 
//
// Private functions
//

private SimBucket valueToBucket(value v)
{
	switch (v)
	{
		case bool V:_: 		return simBucketBoolean(V);
		case num V:_: 		return simBucketNumber(V);
		case str V:_:		return simBucketVariable(V);
		case list[value] V: return simBucketList([ valueToBucket(e) | e <- V ]);
		
		default: throw "Could not convert value <v> to bucket";
	} 
}

private value bucketToValue(SimBucket bucket)
{
	switch (bucket)
	{
		case simBucketBoolean(V): 	return V;
		case simBucketNumber(V): 	return V;
		case simBucketVariable(V): 	return V;
		case L:simBucketList(_): 	return getSimContextBucketList(L);
		
		default: throw "Unknown bucket type";
	}
}
