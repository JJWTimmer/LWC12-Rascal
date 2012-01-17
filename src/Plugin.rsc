module Plugin

import lang::lwc::structure::Syntax;

import lang::lwc::controller::Syntax;
import lang::lwc::controller::Parser;

import util::IDE;
import ParseTree;

public void main() {

	registerLanguage("LWC Structure Module", "lwcs", Structure(str input, loc org) {
       return parse(#Structure, input, org);
	});
    
	registerLanguage("LWC Controller Module", "lwcc", Controller(str input, loc origin) { 
		return lang::lwc::controller::Parser::parse(input, origin);
	});
	
	/*
	registerAnnotator("LWC Structure Module", Fighter(Fighter input) {
		set[Message] msgs = toSet(check(implode(input)));
		iprintln(msgs);
		return input[@messages=msgs];
	});
	*/
}
