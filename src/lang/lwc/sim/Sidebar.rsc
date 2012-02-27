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

public Figure buildInteractiveStructureGraphWithSidebar(Structure ast, void(str, str, SimBucket) updateSimContext) {
	Figure sidebar = buildSidebar("", "", updateSimContext);
	SimContext simCtx; //maar hoe krijg je de geüpdated versie terug in Simulator.rsc?
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
		if (butnr == 1)
			sidebar = buildSidebar(\type, name, updateSimContext);
			
		return true;
	};
	
	return hcat([
		buildInteractiveStructureGraph(ast, mouseHandler),
		computeFigure(Figure () { return sidebar; })
	]);
}

public void visualizeStructureWithSidebar(Structure ast, void(str, str, SimBucket) updateSimContext) = render(buildInteractiveStructureWithSidebar(ast, updateSimContext));

public Figure buildSidebar(str etype, str name, void(str, str, SimBucket) updateSimContext) {
	/*
	list[Attribute] editableAttribs = [];
	if(EditableProps[etype]?) {
		editableAttribs = [ A | A:attribute(attributename(str aname, _)) <- attributes, aname in EditableProps(etype) ];
	}
	*/
	list[Figure] attribFields = [];/*
	for(attribute <- editableAttribs) {
		attribFields += buildField(attribute, updateSimContext);
	}*/

	return box(vcat(text(name, fontSize(20))
					+ attribFields					
					));
}

Figure buildField(attribute(attributename(str name), valuelist(list[Value] values)), void(str, str, SimBucket) updateSimContext) {	
	
	return vcat([text(name, fontSize(14))
				,buildEdit(name, values, updateSimContext)
			]);
}

Figure buildEdit(str name, [bool boolean, R*], void(str, str, SimBucket) updateSimContext) {
	return checkbox(name, void (bool state) { updateSimContext(); } );
}

Figure buildEdit(str name, [metric(Value size, _), R*], void(str, str, SimBucket) updateSimContext) {
	int current; //get from SimContext
	return scaleSlider(int() { return 0; }
					  ,int() { return 100; }
					  ,int() { return current; }
					  ,void(int i) { current = i; updateSimContext(); });
}

Figure buildEdit(str name, [position(str p1), position(str p2)], void(str, str, SimBucket) updateSimContext) {
	;
}