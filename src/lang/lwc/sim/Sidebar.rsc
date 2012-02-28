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

public Figure buildInteractiveContextAwareStructureGraphWithSidebar(
	Structure ast, 
	SimContextLookup lookupSimContext,
	SimContextUpdate updateSimContext
) {
	
	str \type = "";
	bool recompute = false;
	Figure sidebar = box();
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \T, str name) {
		// left click?
		if (butnr == 1) {
			recompute = (T != \type);
			\type = T;
			
			if (recompute)
				sidebar = buildSidebar(\type, name, lookupSimContext().\data, updateSimContext);
			
			return true;
		}
		
		return false;
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

public void visualizeStructureWithSidebar(Structure ast, SimContextUpdate updateSimContext) = render(buildInteractiveStructureWithSidebar(ast, updateSimContext));

public Figure buildSidebar(str etype, str name, SimData simData, SimContextUpdate updateSimContext) {

	list[SimProperty] simProps = getSimContextProperties(simData, name);
	list[SimProperty] editableSimProps = [];
	if(EditableProps[etype]?) {
		editableSimProps = [ A | A:simProp(str s, _) <- simProps, s in EditableProps[etype] ];
	}
	
	list[Figure] fields = [];
	for(simProp <- editableSimProps) {
		fields += buildField(name, simProp, updateSimContext);
	}

	return box(vcat(text(name, fontSize(20))
					+ fields					
					));
}

Figure buildField(str element, simProp(str name, SimBucket bucket), SimContextUpdate updateSimContext) {	
	
	return vcat([text(name, fontSize(14))
				,buildEdit(element, name, bucket, updateSimContext)
			]);
}

Figure buildEdit(str element, str name, B:simBucketBoolean(bool b), SimContextUpdate updateSimContext) {
	return checkbox(name, void (bool state) { updateSimContext(element, name, createSimBucket(state)); } );
}

Figure buildEdit(str element, str name, B:simBucketNumber(int n), SimContextUpdate updateSimContext) {
	int current = n;
	return scaleSlider(int() { return 0; }
					  ,int() { return 100; }
					  ,int() { return current; }
					  ,void(int input) { current = input; updateSimContext(element, name, createSimBucket(current)); });
}

Figure buildEdit(str element, str name, B:simBucketList(list[SimBucket] l), SimContextUpdate updateSimContext) {
	list[Figure] checkBoxes = [];
	for(bucket <- l) {
		checkBoxes += buildEdit(element, name, bucket, l, updateSimContext);
	}
	return hcat(checkBoxes);
}

Figure buildEdit(str element, str name, B:simBucketVariable(str s), list[SimBucket] l, SimContextUpdate updateSimContext) {
	return ellipse(fillColor(arbColor()));
}