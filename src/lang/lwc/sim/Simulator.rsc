module lang::lwc::sim::Simulator

import lang::lwc::controller::Extern;
import lang::lwc::controller::AST;
import lang::lwc::controller::Visualizer;

import lang::lwc::structure::Extern;
import lang::lwc::structure::AST;
import lang::lwc::structure::Visualizer;

import vis::Render;
import vis::Figure;
import IO;
import String;
import ParseTree;

public void simulate(loc baseName)
{
	loc structureName = baseName;
	loc controllerName = baseName;
	
	int len = size(baseName.path);
	str basePath = substring(baseName.path, 0, len - 4);
	
	structureName.path = basePath + "lwcs";
	controllerName.path = basePath + "lwcc"; 
	 
	Structure structureAst = loadStructure(structureName);
	Controller controllerAst = loadController(controllerName);
	
	render(hcat([
		box(buildControllerGraph(controllerAst), gap(10)),
		box(buildStructureGraph(structureAst), gap(10))
	]));	
}

