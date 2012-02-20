module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;
import lang::lwc::structure::Parser;
import lang::lwc::structure::Outliner;
import lang::lwc::structure::Checker;
import lang::lwc::structure::Visualizer;
import lang::lwc::vis::Visualizer;

import util::IDE;


str STRUCTURE_LANG = "LWC Structure Module";
str STRUCTURE_EXT  = "lwcs";

public void registerStructure() {

	set[Contribution] contribution = { 
		popup(
			menu("LWC", [
				menu("Visualize", [
					action("Structure",
						(ParseTree::Tree tree, loc selection) { visualizeStructure(tree); }
					),
					action("Both",
						(ParseTree::Tree tree, loc selection) { visualizeBoth(selection); }
					)
				]),
				
				menu("Debug", [
					action("Re-register",
						(ParseTree::Tree tree, loc selection) { registerStructure(); }
					)
				])
			])
		)
	};
	
	start[Structure] language(str input, loc origin) = parse(input, origin);

	registerLanguage(STRUCTURE_LANG, STRUCTURE_EXT, language);
	registerOutliner(STRUCTURE_LANG, outliner);
	registerAnnotator(STRUCTURE_LANG, check);
	registerContributions(STRUCTURE_LANG, contribution);	
}
