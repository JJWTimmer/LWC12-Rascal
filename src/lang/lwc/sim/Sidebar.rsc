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

alias StructureMouseHandler = bool(int butnr, str \type, str name, list[value] attributes);

public Figure buildInteractiveStructureGraphWithSidebar(Structure ast) {
	Figure sidebar = buildSidebar("", "", updateSimContext);
	SimContext simCtx; //maar hoe krijg je de geüpdated versie terug in Simulator.rsc?
	
	StructureMouseHandler mouseHandler = bool(int butnr, str \type, str name) {
		if (butnr == 1)
			sidebar = buildSidebar(\type, name, updateSimContext);
			
		return true;
	};
	
	updateSimContext = void(str element, str property, SimBucket val) {
		setSimContextBucket(element, property, val, simCtx);
	}; 
	
	return hcat([
		buildInteractiveStructureGraph(ast, mouseHandler),
		computeFigure(Figure () { return sidebar; })
	]);
}

public void visualizeStructureWithSidebar(Structure ast) = render(buildInteractiveStructureWithSidebar(ast));

public Figure buildSidebar(str etype, str name, void() updateSimContext) {
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

Figure buildField(attribute(attributename(str name), valuelist(list[Value] values)), void() updateSimContext) {	
	
	return vcat([text(name, fontSize(14))
				,buildEdit(name, values, updateSimContext)
			]);
}

Figure buildEdit(str name, [bool boolean, R*], void() updateSimContext) {
	return checkbox(name, void (bool state) { updateSimContext(); } );
}

Figure buildEdit(str name, [metric(Value size, _), R*], void() updateSimContext) {
	int current; //get from SimContext
	return scaleSlider(int() { return 0; }
					  ,int() { return 100; }
					  ,int() { return current; }
					  ,void(int i) { current = i; updateSimContext(); });
}

Figure buildEdit(str name, [position(str p1), position(str p2)], void() updateSimContext) {
	;
}