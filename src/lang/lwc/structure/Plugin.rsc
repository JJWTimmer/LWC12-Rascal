module lang::lwc::structure::Plugin

import lang::lwc::structure::Parser;
import lang::lwc::structure::Outliner;
import lang::lwc::structure::Checker;
import lang::lwc::structure::Visualizer;
import lang::lwc::sim::Simulator;

import util::IDE;

str STRUCTURE_LANG = "LWC Structure Module";
str STRUCTURE_EXT  = "lwcs";

public void registerStructure() {

	set[Contribution] contribution = { 
		popup(
			menu("LWC", [
				action("Visualize",
					(ParseTree::Tree tree, loc selection) { visualizeStructure(tree); }),
				action("Simulate",
					(ParseTree::Tree tree, loc selection) { simulate(selection); }
				)
			])
		)
	};

	registerLanguage(STRUCTURE_LANG, STRUCTURE_EXT, parse);
	registerOutliner(STRUCTURE_LANG, structureOutliner);
	registerAnnotator(STRUCTURE_LANG, check);
	registerContributions(STRUCTURE_LANG, contribution);	
}
