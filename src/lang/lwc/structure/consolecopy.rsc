import lang::lwc::structure::Load;
sast = lang::lwc::structure::Load::load(|project://lwc-uva/lwc/example1.lwcs|);

import lang::lwc::controller::Load;
cast = lang::lwc::controller::Load::load(|project://lwc-uva/lwc/example1.lwcc|);

import lang::lwc::structure::Propagate;
sast2 = propagate(sast);

import util::Maybe;
import Graph;

import lang::lwc::sim::Context;
ctx = initSimContext(sast2, cast);

import lang::lwc::sim::Reach;
graph = buildGraph(sast2);
isReachable(graph, ctx, "C1", just("hotwaterout"), "V1", just("a"));

import lang::lwc::structure::Parser;
import lang::lwc::structure::Checker;
tree = parse(|project://lwc-uva/lwc/example1.lwcs|);
tree2 = check(tree);