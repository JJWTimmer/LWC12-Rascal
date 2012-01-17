module lang::lwc::structure::Plugin

import lang::lwc::structure::Syntax;

import util::IDE;
import ParseTree;

public void registerStructure() {

	registerLanguage("LWC Structure Module", "lwcs", Structure(str input, loc org) {
       return parse(#Structure, input, org);
	});
    
	/*
	registerAnnotator("LWC Structure Module", Fighter(Fighter input) {
		set[Message] msgs = toSet(check(implode(input)));lang::lwc::controller::Parser::parse
		iprintln(msgs);
		return input[@messages=msgs];
	});
	*/
}
