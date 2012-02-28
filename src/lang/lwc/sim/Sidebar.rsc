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

alias StructureMouseHandler = bool(int butnr, str \type, str name);

alias UpdateContextValue = void(str property, str element, SimBucket val);

public Figure buildInteractiveContextAwareStructureGraphWithSidebar(
	Structure ast, 
	SimContextLookup lookupSimContext,
	SimContextUpdate updateSimContext
) {
	str currentType = "";
	str currentName = "";
	
	bool recompute = false;
	Figure sidebar = box();
	
	UpdateContextValue updateContextValue = void(str element, str property, SimBucket val) {
		updateSimContext(setSimContextBucket(element, property, val, lookupSimContext));
	};
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
	
		// left click?
		if (butnr != 1) 
			return false;
			
		// Has the type of the 
		recompute = (\type != currentType || name != currentName);
		
		currentType = \type;
		currentName = \name;
		
		if (recompute)
			sidebar = buildSidebar(\type, name, lookupSimContext().\data, updateContextValue);
		
		return true;
	};
	
	return hcat([
		buildContextAwareInteractiveStructureGraph(ast, mouseHandler, lookupSimContext()),
		
		computeFigure(
			bool() { return recompute; }, 
			Figure () { 
				recompute = false;
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
	= vcat(
		[text(name, fontSize(14)),
		buildEdit(element, name, bucket, updateContextValue)
	]);

Figure buildEdit(str element, str name, B:simBucketBoolean(bool b), UpdateContextValue updateContextValue) 
	= checkbox(name, void (bool state) { updateContextValue(element, name, createSimBucket(state)); } );

Figure buildEdit(str element, str name, B:simBucketNumber(int n), UpdateContextValue updateContextValue) 
{
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

Figure buildEdit(str element, str name, B:simBucketList(list[SimBucket] l), UpdateContextValue updateContextValue) {
	list[Figure] checkBoxes = [];
	for(bucket <- l) {
		checkBoxes += buildEdit(element, name, bucket, l, updateContextValue);
	}
	return hcat(checkBoxes);
}

Figure buildEdit(str element, str name, B:simBucketVariable(str s), list[SimBucket] l, UpdateContextValue updateContextValue) {
	return ellipse(fillColor(arbColor()));
}