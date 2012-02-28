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
import IO;

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

public Figure buildSidebar(Structure ast, str etype, str name, SimData simData, UpdateContextValue updateContextValue) {
	list[SimProperty] simProps = getSimContextProperties(simData, name);
	list[SimProperty] editableSimProps = [];
	
	if (EditableProps[etype]?)
		editableSimProps = [ A | A:simProp(str s, _) <- simProps, s in EditableProps[etype] ];
	
	list[Figure] fields = [ buildField(ast, name, simProp, updateContextValue) | simProp <- editableSimProps ];
	
	return box(
		vcat([text(name, fontSize(20))] + fields, gap(5))
	);
}

Figure buildField(Structure ast, str element, simProp(str name, SimBucket bucket), UpdateContextValue updateContextValue)
	= vcat([
			text(name, fontSize(14)),
			buildEdit(ast, element, name, bucket, updateContextValue)
		], 
		gap(5)
	);

Figure buildEdit(Structure ast, str element, str name, B:simBucketBoolean(bool b), UpdateContextValue updateContextValue) = 
	checkbox(name, void (bool state) { 
			updateContextValue(element, name, createSimBucket(state));
		} 
	);

Figure buildEdit(Structure ast, str element, str name, B:simBucketNumber(int n), UpdateContextValue updateContextValue) {
	int current = n;
	
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
	Figure buildCheckBox(str v) = checkbox(v, void (bool state) { updateContextValue(elementName, name, newBucketList(v, state)); });
	
	SimBucket newBucketList(str s, bool b) = createSimBucket(
			[ B | B:simBucketVariable(str var) <- bucketList, (var==s && b) || var!=s ]);
	
	set[str] variables = {};
	
	if(/element(_,elementname("Valve"), elementName, list[Attribute] attributes) := ast) {
		variables = { v
				| attribute("connections", valuelist(list[Value] values)) <- attributes,
				variable(str v) <- values
				}; 
	}
	for(simBucketVariable(str b) <- B) {
		variables += b;
	}
	
	list[Figure] checkBoxes = [];
	for(var <- variables) {
		checkBoxes += buildCheckBox(var);
	}
	return hcat(checkBoxes);
}

/*
Figure buildEdit(Structure ast, str element, str name, B:simBucketNothing(), UpdateContextValue updateContextValue)
	= buildEdit(ast, element, name, simBucketList([]), updateContextValue);
*/

default Figure buildEdit(Structure ast, str element, str name, B:SimBucket bucketList, UpdateContextValue updateContextValue) {
	println("Could not match <bucketList>");
}
