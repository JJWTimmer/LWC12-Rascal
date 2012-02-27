import lang::lwc::structure::Load;
ast = load(|project://lwc-uva/lwc/example1.lwcs|);

import lang::lwc::structure::Propagate;
ast2 = propagate(ast);

import lang::lwc::sim::Reach;
graph = buildGraph(ast2);

import util::Maybe;
import Graph;

import lang::lwc::sim::Context;
ctx = createSimContext(ast2);


import lang::lwc::structure::Parser;
import lang::lwc::structure::Checker;
tree = parse(|project://lwc-uva/lwc/example1.lwcs|);
tree2 = check(tree);