module lang::lwc::structure::Visualizer

import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::structure::AST;

import vis::Figure;
import vis::Render;

import List;
import IO;
import ParseTree;
import util::Math;

public void visualize(Tree tree)
{
	Structure ast = propagate(implode(tree));
	
	// Build the graph
	list[Figure] nodes = [];
	list[Edge] edges = [];
	
	visit (ast.body) 
	{
		// Match sensors
		case E:element(M, elementname("Sensor"), N, _): {
			edges += sensorEdges(E, N);
			nodes += sensorFigure(N, M);
		}
		
		// Handle Joints
		case element(_, elementname("Joint"), N, _):
			nodes += jointFigure(N);
		
		// Handle Pumps
		case element(_, elementname("Pump"), N, _):
			nodes += pumpFigure(N);
		
		// Handle Valves
		case element(M, elementname("Valve"), N, A): 	
			nodes += valveFigure(N, M); 
		
		// Other elements
		case element(_, elementname(T), N, _): 			
			nodes += elementFigure(T, N);
		
		// Match pipes
		case pipe(_, str N, Value from, Value to, _): {
		
			// Collect a list of all sensor connections
			list[str] allSensorConnections =
				([] | it + collectSensorConnections(E) | E:element(_, elementname("Sensor"), _, _) <- ast.body);
				
			// If a sensor is connected to this pipe, we have to split it in half to create a connection point
			// for the sensor
			if (N in allSensorConnections) {
				nodes += box(id(N));
				edges += [edge(from.var, N), edge(N, to.var)];
				
			// We're dealing with a simple pipe
			} else {
				edges += [edge(from.var, to.var)];
			}
		}
	}
	
	render(graph(nodes, edges, gap(40)));
}

//
// Render sensors
//

list[Edge] sensorEdges(Statement E, str to) = [ edge(name, to, lineColor("blue")) | str name <- collectSensorConnections(E) ];

Figure sensorFigure(str N, list[Modifier] modifiers) 
{ 
	str name = intercalate(" ", [ m.id | m <- modifiers]);
	 
	return ellipse(
		vcat([
			text(name, fontSize(9)), 
			text(N)
		]), 
		id(N), lineColor("blue"));
}

//
// Render an element
//

Figure elementFigure(str typ, str name) = 
	box(
		vcat([
			text(typ, fontSize(9)),
			text(name)
		]), grow(1.5), id(name)
	);

//
// Render a pump figure
//

Figure pumpFigure(str name) = 
	box(
		vcat([
			text(name, fontSize(9)),
			pumpSymbol()
		]), 
		id(name), lineWidth(0)
	);
	
Figure pumpSymbol()
{
	Figure deg2p(num angle) = 
		point(
			cos(angle * PI() / 180) * 0.5 + 0.5,
			sin(angle * PI() / 180) * 0.5 + 0.5);
	
    return overlay([
		ellipse(size(30)),
		overlay([deg2p(-90 - 20), deg2p(0)], shapeConnected(true), size(30)),
		overlay([deg2p(90 + 20), deg2p(0)], shapeConnected(true), size(30))
	]);
}

//
// Render a joint
//

Figure jointFigure(str name) = 
	ellipse(
		text(name, fontColor("white"), fontSize(8)), fillColor("black"), id(name)
	);
			
//
// Render a valve figure
//

Figure valveFigure(str N, list[Modifier] M) = box(
	vcat([
		text(N, fontSize(9)),
		valveSymbol(modifier("ThreeWay") in M  ? 3 : 2)
	]),
	lineWidth(0),
	id(N));
				
Figure valveSymbol(int ways)
{
	Figure twoWay =
		overlay([
			point(0,0), 
			point(1,1), 
			point(1,0), 
			point(0, 1)
		], shapeConnected(true), shapeClosed(true), width(40), height(20));
	
	Figure threeWay = 
		overlay([
			point(0, 0),
			point(0.5, 0.33),
			point(1, 0),
			point(1, 0.66),
			point(0.5, 0.33),
			point(0.8, 1),
			point(0.2, 1),
			point(0.5, 0.33),
			point(0, 0.66)
		], shapeConnected(true), shapeClosed(true), width(40), height(32));
		
	return ways == 2 ? twoWay : threeWay;
}

//
// Helper methods
//

private Figure point(num x, num y) = ellipse(align(x, y));

private list[str] collectSensorConnections(Statement sensor)
{
	list[str] points = [];
	
	if ([_*, A:attribute(attributename("on"), _*), _*] := sensor.attributes)
	{
		top-down-break visit (A.val.values)
		{
			case variable(str name): points += name;
			case property(str name, _): points += name;
		}
	}
	
	return points;
}
