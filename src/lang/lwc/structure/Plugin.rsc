module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;
import lang::lwc::structure::Checker;

import util::IDE;
import ParseTree;

public void registerStructure() {

	registerLanguage("LWC Structure Module", "lwcs", Structure(str input, loc org) {
       return parse(#Structure, input, org);
	});
    
	registerAnnotator("LWC Structure Module", check);
}
