module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;
import util::IDE;

import lang::lwc::structure::Parser;
import lang::lwc::structure::Outliner;
import lang::lwc::structure::Checker;
import lang::lwc::structure::Visualizer;



str STRUCTURE_LANG = "LWC Structure Module";
str STRUCTURE_EXT  = "lwcs";

public void registerStructure() {

	set[Contribution] contribution = { 
		popup(menu("LWC", [
			action(
				"Visualize", (Tree tree, loc selection) {
					visualize(tree);
				}
			)
		]))
	};
	
	start[Structure] language(str input, loc origin) = parse(input, origin);

	registerLanguage(STRUCTURE_LANG, STRUCTURE_EXT, language);
	registerOutliner(STRUCTURE_LANG, outliner);
	registerAnnotator(STRUCTURE_LANG, check);
	registerContributions(STRUCTURE_LANG, contribution);
	contribs = {popup(menu("LWC",[action("Re-register", rereg)]))};
	registerContributions(STRUCTURE_LANG, contribs);
	
}

public void rereg(ParseTree::Tree tree, loc file) {
	registerStructure();
}
