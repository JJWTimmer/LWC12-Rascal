module lang::lwc::controller::Plugin

import lang::lwc::controller::Parser;
import lang::lwc::controller::Outliner;
import lang::lwc::controller::Checker;
import lang::lwc::controller::Visualizer;
import lang::lwc::sim::Simulator;

import util::IDE;

str CONTROLLER_LANG = "LWC Controller Module";
str CONTROLLER_EXT  = "lwcc";

public void registerController() {

	set[Contribution] contribution = { 
		popup(
			menu("LWC", [
				action("Visualize", 
					(ParseTree::Tree tree, loc selection) { visualizeController(tree); }),
				action("Simulate", 
					(ParseTree::Tree tree, loc selection) { simulate(selection); })
			])
		)
	};
	
	registerLanguage(CONTROLLER_LANG, CONTROLLER_EXT, parse);
	registerOutliner(CONTROLLER_LANG, controllerOutliner);	
	registerAnnotator(CONTROLLER_LANG, check);
	registerContributions(CONTROLLER_LANG, contribution);
}
