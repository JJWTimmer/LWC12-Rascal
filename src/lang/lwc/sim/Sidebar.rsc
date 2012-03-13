module lang::lwc::sim::Sidebar

import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::structure::AST;
import lang::lwc::structure::Visualizer;

import lang::lwc::Constants;
import lang::lwc::structure::Extern;
import lang::lwc::sim::Context;

import vis::Figure;
import vis::Render;
import vis::KeySym;
import util::Math;
import IO;

alias StructureMouseHandler = bool(int butnr, str \type, str name);

alias UpdateContextValue = void(str property, str element, SimBucket val);

public Figure buildInteractiveContextAwareStructureGraphWithSidebar(
	Structure ast, 
	SimContextLookup lookupSimContext,
	SimContextUpdate updateSimContext
) {
	str currentType = "";
	str currentName = "";
	
	bool recomputeSidebar = true;
	bool recomputeGraph = true;
	
	UpdateContextValue updateContextValue = void(str element, str property, SimBucket val) {
		updateSimContext(setSimContextBucket(element, property, val, lookupSimContext()));
		recomputeGraph = true;
	};
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
	
		// left click?
		if (butnr != 1) 
			return false;
			
		// Has the type of the 
		recomputeSidebar = (\type != currentType || name != currentName);
		
		currentType = \type;
		currentName = name;
		
		return true;
	};
	
	// If a step has been executed, rerender the structure graph
	updateSimContext(
		registerStepAction(SimContext(SimContext ctx) {
			recomputeGraph = true;
			return ctx;
		}, lookupSimContext())
	);
	
	return hcat([
		computeFigure(
			bool() { return recomputeGraph; },
			Figure() {
				recomputeGraph = false;
				return buildContextAwareInteractiveStructureGraph(ast, mouseHandler, lookupSimContext());
			}
		),
		computeFigure(
			bool() { return recomputeSidebar; }, 
			Figure () { 
				recomputeSidebar = false;
				return buildSidebar(ast, currentType, currentName, lookupSimContext().\data, updateContextValue);
			}
		)
	]);
}

public Figure buildSidebar(Structure ast, str etype, str name, SimData simData, UpdateContextValue updateContextValue) 
{	
	list[Figure] fields = [];
	
	// Sensors deserve special treatment
	if (etype == "Sensor")
	{
		tuple[str,str] C = getSensorConnection(name, ast);
		fields = [ buildReadableField(ast, "Sensor", C[1], getSimContextProperty(simData, C[0], C[1])) ];
	}
	else
	{
		fields = buildFields(ast, etype, name, simData, updateContextValue);
	}
	
	return box(
		vcat([text(name, fontSize(20))] + fields, gap(5))
	);
}

tuple[str,str] getSensorConnection(name, Structure ast) {
	if (/element(_, elementname("Sensor"), name, [_*, attribute(attributename("on"), valuelist([_*, property(E, propname(P)), _*])), _*]) := ast)
		return <E, P>;
	
	throw "Sensor connection not found";
}

list[Figure] buildFields(Structure ast, str etype, str name, SimData simData, UpdateContextValue updateContextValue)
{
	simProps = getSimContextProperties(simData, name);
	
	list[SimProperty] editableSimProps = (EditableProps[etype]?)
		? [ A | A:simProp(str s, _) <- simProps, s in EditableProps[etype] ]
		: [];
	
	list[SimProperty] readableSimProps = (ReadableProps[etype]?)
		? [ A | A:simProp(str s, _) <- simProps, s in ReadableProps[etype] ]
		: [];
		
	return
		[ buildReadableField(ast, etype, name, simProp) | simProp <- readableSimProps ]
		+ [ buildEditableField(ast, etype, name, simProp, updateContextValue) | simProp <- editableSimProps ];
}

Figure buildReadableField(Structure ast, str etype, str element, simProp(str name, SimBucket bucket)) =
	vcat([
			text(name, fontSize(14)),
			buildReadable(element, name, bucket)
		], 
		gap(5)
	);
	
Figure buildReadable(str element, str name, B:simBucketNumber(n)) {
	return text("<n>");
}

default Figure buildReadable(Structure ast, str element, str name, B:SimBucket bucket) {
	throw "Could not match <bucket>";
}

Figure buildEditableField(Structure ast, str etype, str element, simProp(str name, SimBucket bucket), UpdateContextValue updateContextValue) =
	vcat([
			text(name, fontSize(14)),
			buildEdit(ast, element, name, bucket, updateContextValue)
		], 
		gap(5)
	);

Figure buildEdit(Structure ast, str element, str name, B:simBucketBoolean(bool b), UpdateContextValue updateContextValue) = 
	checkbox(
		name, 
		void (bool state) { 
			updateContextValue(element, name, createSimBucket(state));
		} 
	);

Figure buildEdit(Structure ast, str element, str name, B:simBucketNumber(n), UpdateContextValue updateContextValue) {
	int current = toInt(n);
	
	return scaleSlider(
		int() { return 0; },
		int() { return 100; },
		int() { return current; },
		void(int input) { 
		  	current = input; 
		  	updateContextValue(element, name, createSimBucket(current)); 
		}
	);
}

Figure buildEdit(Structure ast, str elementName, str name, B:simBucketList(list[SimBucket] bucketList), UpdateContextValue updateContextValue) {	
	SimBucket newBucketList(str s, bool b) = createSimBucket(
		[ B | B:simBucketVariable(str var) <- bucketList, (var==s && b) || var!=s ]);

	Figure buildCheckBox(str v) = checkbox(v, void (bool state) { updateContextValue(elementName, name, newBucketList(v, state)); });
	
	set[str] variables = {};
	
	if(/element(_, elementname("Valve"), elementName, list[Attribute] attributes) := ast) {
		variables = { v
					| attribute(attributename("connections"), valuelist(list[Value] values)) <- attributes,
					  variable(str v) <- values
					};
	}
	
	variables += { b | simBucketVariable(str b) <- B };
	
	list[Figure] checkBoxes = [];
	for(var <- variables) {
		checkBoxes += buildCheckBox(var);
	}
	return hcat(checkBoxes); 
}

default Figure buildEdit(Structure ast, str element, str name, B:SimBucket bucket, UpdateContextValue updateContextValue) {
	println("Could not match <bucket>");
}

Figure buildEditSensor(str elementName, str name, B:simBucketNumber(n), UpdateContextValue updateContextValue) {
	println("sensor <elementName>, bucket <B>");
	return vcat([text(name, fontSize(14)), text(n, fontSize(14))]);
}