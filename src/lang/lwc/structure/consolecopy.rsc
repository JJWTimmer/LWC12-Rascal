import lang::lwc::structure::Load;
ast = load(|project://lwc-uva/lwc/example1.lwcs|);

import lang::lwc::structure::Parser;
import lang::lwc::structure::Checker;
tree = parse(|project://lwc-uva/lwc/example1.lwcs|);
tree2 = check(tree);