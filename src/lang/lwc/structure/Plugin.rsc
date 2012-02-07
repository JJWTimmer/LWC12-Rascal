module lang::lwc::structure::Plugin

import util::IDE;

import lang::lwc::structure::Parser;
import lang::lwc::structure::Outliner;
import lang::lwc::structure::Checker;

str STRUCTURE_LANG = "LWC Structure Module";
str STRUCTURE_EXT  = "lwcs";

public void registerStructure() {

	registerLanguage(STRUCTURE_LANG, STRUCTURE_EXT, parse);
	
	registerOutliner(STRUCTURE_LANG, outliner);
	
	registerAnnotator(STRUCTURE_LANG, check);
	
	contribs = {popup(menu("LWC",[action("Re-register", rereg)]))};
	registerContributions(STRUCTURE_LANG, contribs);
	
}

public void rereg(ParseTree::Tree tree, loc file) {
	registerStructure();
}
