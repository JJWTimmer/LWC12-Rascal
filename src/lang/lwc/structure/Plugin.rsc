module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;
import lang::lwc::structure::Checker;
import lang::lwc::structure::Outliner;

import util::IDE;
import ParseTree;
import Message;

private str lang() = "LWC Structure Language";


public void registerStructure() {

	registerLanguage(lang(), "lwcs", start[Structure](str input, loc org) {
       return parse(#start[Structure], input, org);
	});
    
	registerAnnotator(lang(), check);
	
	registerOutliner(lang(), outliner);
	
}
