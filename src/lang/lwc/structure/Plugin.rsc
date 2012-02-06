module lang::lwc::structure::Plugin

extend lang::lwc::structure::Syntax;
import lang::lwc::structure::Checker;
import lang::lwc::structure::Outliner;

import util::IDE;
import ParseTree;
import Message;

str STRUCTURE_LANG = "LWC Structure Module";
str STRUCTURE_EXT  = "lwcs";


public void registerStructure() {

	registerLanguage(STRUCTURE_LANG, STRUCTURE_EXT, start[Structure](str input, loc org) {
       return parse(#start[Structure], input, org);
	});
    
	registerAnnotator(STRUCTURE_LANG, check);
	
	registerOutliner(STRUCTURE_LANG, outliner);
	
}
