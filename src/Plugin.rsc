module Plugin

import lang::lwc::structure::Syntax;

import util::IDE;
import ParseTree;

public void main() {

	registerLanguage("LWC Structure Module", "lwcs", Structure(str input, loc org){
       return parse(#Structure, input, org);
   } );

	/*
	registerAnnotator("LWC Structure Module", Fighter(Fighter input) {
		set[Message] msgs = toSet(check(implode(input)));
		iprintln(msgs);
		return input[@messages=msgs];
	});
	*/
}
