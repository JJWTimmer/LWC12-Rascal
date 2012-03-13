module lang::lwc::sim::RunnableController

import lang::lwc::controller::Visualizer;
import lang::lwc::controller::Extern;
import lang::lwc::controller::AST;
import lang::lwc::controller::runtime::Data;
import lang::lwc::controller::runtime::Run;
import lang::lwc::sim::Context;

import vis::Figure;
import vis::Render;
import IO;
import util::Math;
import List;

State contextToGraphState(RuntimeContext ctx) {
	if (inState(ctx))
		return ActiveState(ctx.state);
	else if (inTransition(ctx))
		return ActiveEdge(<ctx.state, ctx.transition>);
	else
		return Done();
}

public Figure buildRunnableControllerGraph(Controller ast, SimContextLookup simContextLookup, SimContextUpdate simContextUpdate)
{
	// Initial state
	State graphState = contextToGraphState(simContextLookup().runtime);
	
	bool automatic = false;
	int interval = 300;
	
	void stepSimulation() {
		SimContext ctx = step(simContextLookup());
		graphState = contextToGraphState(ctx.runtime);
		simContextUpdate(ctx);
	};
	
	// Visualization of the graph
	Figure graph = buildStatefulControllerGraph(ast, State() { return graphState; });
	
	TimerAction timeAction(TimerInfo t) = (stopped(_) := t && automatic) ? restart(interval) : noChange();
	
	void() executeTimer = stepSimulation;
	void() clickStep = stepSimulation;
		
	void(bool) checkAuto = void(bool checked) {
		automatic = checked;
	};
	
	Figure pane = hcat([
		box(
			vcat([
				button("Step", clickStep),
				
				text("Automatic", left()),
				checkbox("Enable", checkAuto, fillColor("lightblue")),
				
				text("Interval (ms)", left()),
				
				hcat([
					scaleSlider(int() { return 300; },     
	                    int () { return 1000; },  
	                    int () { return interval; },    
	                    void (int s) { interval = s; },
	                    fillColor("lightblue")),
	                text(str() { return "<interval>"; }, fontBold(true), fontSize(9))
	            ], gap(5))
                    
			], gap(10)),
		gap(10), fillColor(color("lightblue")), lineWidth(0), width(200), resizable(false), top()),
		
		vcat([ 
			graph            
		], timer(timeAction, executeTimer))
	]);
              
	return pane;
}
