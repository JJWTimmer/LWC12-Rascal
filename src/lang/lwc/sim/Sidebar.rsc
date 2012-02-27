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

public Figure buildInteractiveStructureGraphWithSidebar(Structure ast, SimContext simCtx, void(str, str, SimBucket) updateSimContext) {
	Figure sidebar = buildSidebar("", "", simCtx, updateSimContext);
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
		if (butnr == 1)
			sidebar = buildSidebar(\type, name, simCtx, updateSimContext);
			
		return true;
	};
	
	return hcat([
		buildInteractiveStructureGraph(ast, mouseHandler),
		computeFigure(Figure () { return sidebar; })
	]);
}

public void visualizeStructureWithSidebar(Structure ast, void(str, str, SimBucket) updateSimContext) = render(buildInteractiveStructureWithSidebar(ast, updateSimContext));

public Figure buildSidebar(str etype, str name, SimContext simCtx, void(str, str, SimBucket) updateSimContext) {

	list[SimProperty] simProps = getSimContextProperties(simCtx, name);
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

Figure buildField(str element, simProp(str name, SimBucket bucket), void(str, str, SimBucket) updateSimContext) {	
	
	return vcat([text(name, fontSize(14))
				,buildEdit(element, name, bucket, updateSimContext)
			]);
}

Figure buildEdit(str element, str name, B:simBucketBoolean(bool b), void(str, str, SimBucket) updateSimContext) {
	return checkbox(name, void (bool state) { updateSimContext(element, name, createSimBucket(state)); } );
}

Figure buildEdit(str element, str name, B:simBucketNumber(int n), void(str, str, SimBucket) updateSimContext) {
	int current = n;
	return scaleSlider(int() { return 0; }
					  ,int() { return 100; }
					  ,int() { return current; }
					  ,void(int input) { current = input; updateSimContext(element, name, createSimBucket(current)); });
}

Figure buildEdit(str element, str name, B:simBucketList(list[SimBucket] l), void(str, str, SimBucket) updateSimContext) {
	;
}