module Plugin

import lang::lwc::structure::Parser;
import lang::lwc::structure::Syntax;

import util::IDE;

public void main() {

	registerLanguage("LWC Structure Module", "lwcs", Main(str input, loc l) {
  		return parse(input, l);
  	});

	/*
	registerAnnotator("LWC Structure Module", Fighter(Fighter input) {
		set[Message] msgs = toSet(check(implode(input)));
		iprintln(msgs);
		return input[@messages=msgs];
	});
	*/
}
