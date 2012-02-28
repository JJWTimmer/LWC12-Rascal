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

public Figure buildInteractiveStructureGraphWithSidebar(Structure ast, SimData simData, void(str, str, SimBucket) updateSimContext) {
	Figure sidebar = buildSidebar("", "", simData, updateSimContext);
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
		if (butnr == 1)
			sidebar = buildSidebar(\type, name, simData, updateSimContext);
			
		return true;
	};
	
	return hcat([
		buildInteractiveStructureGraph(ast, mouseHandler),
		computeFigure(Figure () { return sidebar; })
	]);
}

public void visualizeStructureWithSidebar(Structure ast, void(str, str, SimBucket) updateSimContext) = render(buildInteractiveStructureWithSidebar(ast, updateSimContext));

public Figure buildSidebar(str etype, str name, SimData simData, void(str, str, SimBucket) updateSimContext) {

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

Figure buildEdit(str element, str name, B:simBucketList(list[SimBucket] bucketList), void(str, str, SimBucket) updateSimContext) {
	//propagate voegt position attribute toe met variable ipv position constructor
	println("<element> <name>");
	iprint(bucketList);
/*
	Figure buildListElem(B:simBucketPosition(str p)) {
		return checkbox(p, void (bool state) { updateSimContext(element, name, bucketList); } );
	};*/
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