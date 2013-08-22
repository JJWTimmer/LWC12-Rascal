module lang::lwc::tests::TestStructureParse

import lang::lwc::structure::Parser;

test bool testStructureParse() {
	try
		tree = parse(|project://lwc-uva/lwc/example1.lwcs|);
	catch:
		return false;
		
	return true;
}