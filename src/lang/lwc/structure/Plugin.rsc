module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;
import lang::lwc::structure::Checker;
import lang::lwc::structure::Outliner;

import util::IDE;
import ParseTree;

private str lang() = "LWC Structure Language";

public void registerStructure() {

	registerLanguage(lang(), "lwcs", Structure(str input, loc org) {
       return parse(#Structure, input, org);
	});
    
	registerAnnotator(lang(), check);
	
	registerOutliner(lang(), outliner);
	
}
