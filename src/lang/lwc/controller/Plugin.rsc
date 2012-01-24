module lang::lwc::controller::Plugin

import lang::lwc::controller::Syntax;
import lang::lwc::controller::Parser;
import lang::lwc::controller::Outliner;

import util::IDE;

str CONTROLLER_LANG = "LWC Controller Module";
str CONTROLLER_EXT  = "lwcc";

public void registerController() {

	registerLanguage(CONTROLLER_LANG, CONTROLLER_EXT, start[Controller](str input, loc origin) { 
		return parse(input, origin);
	});
	
	registerOutliner(CONTROLLER_LANG, outliner);
	
	/*
	registerAnnotator("LWC Structure Module", Fighter(Fighter input) {
		set[Message] msgs = toSet(check(implode(input)));lang::lwc::controller::Parser::parse
		iprintln(msgs);
		return input[@messages=msgs];
	});
	*/
}
