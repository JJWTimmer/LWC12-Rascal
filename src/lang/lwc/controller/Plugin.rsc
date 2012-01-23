module lang::lwc::controller::Plugin

import lang::lwc::controller::Syntax;
import lang::lwc::controller::Parser;

import util::IDE;
import ParseTree;

public void registerController() {

	registerLanguage("LWC Controller Module", "lwcc", start[Controller](str input, loc origin) { 
		return parse(input, origin);
	});
	
	/*
	registerAnnotator("LWC Structure Module", Fighter(Fighter input) {
		set[Message] msgs = toSet(check(implode(input)));lang::lwc::controller::Parser::parse
		iprintln(msgs);
		return input[@messages=msgs];
	});
	*/
}
