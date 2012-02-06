module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;
import lang::lwc::structure::Parser;
import lang::lwc::structure::Outliner;
import lang::lwc::structure::Checker;

import util::IDE;

str STRUCTURE_LANG = "LWC Structure Module";
str STRUCTURE_EXT  = "lwcs";

public void registerStructure() {

	registerLanguage(STRUCTURE_LANG, STRUCTURE_EXT, start[Structure](str input, loc origin) { 
		return parse(input, origin);
	});
	
	registerOutliner(STRUCTURE_LANG, outliner);
	
	registerAnnotator(STRUCTURE_LANG, check);
	
}
