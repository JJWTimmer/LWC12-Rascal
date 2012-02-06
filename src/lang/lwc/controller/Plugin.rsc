module lang::lwc::controller::Plugin

extend lang::lwc::controller::Syntax;
import lang::lwc::controller::Parser;
import lang::lwc::controller::Outliner;
import lang::lwc::controller::Checker;

import util::IDE;

str CONTROLLER_LANG = "LWC Controller Module";
str CONTROLLER_EXT  = "lwcc";

public void registerController() {

	registerLanguage(CONTROLLER_LANG, CONTROLLER_EXT, start[Controller](str input, loc origin) { 
		return parse(input, origin);
	});
	
	registerOutliner(CONTROLLER_LANG, outliner);
	
	registerAnnotator(CONTROLLER_LANG, check);
	
}
