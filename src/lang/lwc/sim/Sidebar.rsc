module lang::lwc::sim::Sidebar

import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::structure::AST;
import lang::lwc::structure::Visualizer;

import lang::lwc::Constants;
import lang::lwc::sim::Context;

import vis::Figure;
import vis::Render;
import vis::KeySym;
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
	
	bool recomputeSidebar = false;
	bool recomputeGraph = false;
	
	Figure sidebar = box();
	Figure graph = box();
	
	UpdateContextValue updateContextValue = void(str element, str property, SimBucket val) {
		updateSimContext(setSimContextBucket(element, property, val, lookupSimContext()));
	};
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
	
		// left click?
		if (butnr != 1) 
			return false;
			
		// Has the type of the 
		recomputeSidebar = (\type != currentType || name != currentName);
		
		currentType = \type;
		currentName = \name;
		
		if (recomputeSidebar)
			sidebar = buildSidebar(\type, name, lookupSimContext().\data, updateContextValue);
		
		return true;
	};
	
	// If a step has been executed, rerender the structure graph
	updateSimContext(
		registerStepAction(SimContext(SimContext ctx) {
			graph = buildContextAwareInteractiveStructureGraph(ast, mouseHandler, ctx);
			recomputeGraph = true;
			return ctx;
		}, lookupSimContext())
	);
	
	return hcat([
		computeFigure(
			bool() { return recomputeGraph; },
			Figure() {
				recomputeGraph = false;
				return graph;
			}
		),
		computeFigure(
			bool() { return recomputeSidebar; }, 
			Figure () { 
				recomputeSidebar = false;
				return sidebar;
			}
		)
	]);
}

public Figure buildSidebar(str etype, str name, SimData simData, UpdateContextValue updateContextValue) {

	list[SimProperty] simProps = getSimContextProperties(simData, name);
	list[SimProperty] editableSimProps = [];
	
	if (EditableProps[etype]?)
		editableSimProps = [ A | A:simProp(str s, _) <- simProps, s in EditableProps[etype] ];
	
	list[Figure] fields = [ buildField(name, simProp, updateContextValue) | simProp <- editableSimProps ];
	
	return box(
		vcat([text(name, fontSize(20))] + fields)
	);
}

Figure buildField(str element, simProp(str name, SimBucket bucket), UpdateContextValue updateContextValue)
	= vcat([
			text(name, fontSize(14)),
			buildEdit(element, name, bucket, updateContextValue)
		], 
		gap(5)
	);

Figure buildEdit(str element, str name, B:simBucketBoolean(bool b), UpdateContextValue updateContextValue)
{
	return checkbox(name, void (bool state) { 
		updateContextValue(element, name, createSimBucket(state),
		width(100), height(100)); 
	});
}

Figure buildEdit(str element, str name, B:simBucketNumber(int n), UpdateContextValue updateContextValue) {
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

Figure buildEdit(str element, str name, B:simBucketList(list[SimBucket] bucketList), UpdateContextValue updateContextValue) {
	//propagate voegt position attribute toe met variable ipv position constructor
	println("<element> <name>");
	
	/*
	Figure buildListElem(B:simBucketPosition(str p)) {
		return checkbox(p, void (bool state) { updateSimContext(element, name, bucketList); } );
	};
	*/
	
	Figure buildListElem(SimBucket b) {
		str txt = "";
		switch(b) {
			case simBucketBoolean	: txt = "bool"; //waar komen bools vandaan?
			case simBucketNumber	: txt = "num";
			case simBucketList	 	: txt = "list";
			case simBucketVariable	: txt = "var";
			case simBucketPosition	: txt = "pos";
			case simBucketNothing	: txt = "nothing";
		}
		return box(text(txt));
	}
	list[Figure] checkBoxes = [];
	for(b <- bucketList) {
		checkBoxes += buildListElem(b);
	}
	return hcat(checkBoxes);
}