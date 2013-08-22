module lang::lwc::tests::TestStructureImplode

import lang::lwc::structure::Load;

test bool testStructureImplode() {
	try
		ast = load(|project://lwc-uva/lwc/example1.lwcs|);
	catch:
		return false;
		
	return true;
}