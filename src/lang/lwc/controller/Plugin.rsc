module lang::lwc::controller::Plugin

import lang::lwc::controller::Parser;
import lang::lwc::controller::Outliner;
import lang::lwc::controller::Checker;
import lang::lwc::controller::Visualizer;
import lang::lwc::vis::Visualizer;

import util::IDE;

str CONTROLLER_LANG = "LWC Controller Module";
str CONTROLLER_EXT  = "lwcc";

public void registerController() {

	set[Contribution] contribution = { 
		popup(
			menu("LWC", [
				menu("Visualize", [
					action("Controller", 
						(ParseTree::Tree tree, loc selection) { visualizeController(tree); }),
					action("Both", 
						(ParseTree::Tree tree, loc selection) { visualizeBoth(selection); })
				])
			])
		)
	};
	
	registerLanguage(CONTROLLER_LANG, CONTROLLER_EXT, parse);
	registerOutliner(CONTROLLER_LANG, outliner);	
	registerAnnotator(CONTROLLER_LANG, check);
	registerContributions(CONTROLLER_LANG, contribution);
}
