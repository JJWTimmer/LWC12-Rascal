module lang::lwc::structure::Visualizer

import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::structure::AST;

import lang::lwc::sim::Context;

import vis::Figure;
import vis::Render;
import vis::KeySym;

import List;
import ParseTree;
import IO;
import util::Math;

alias StructureMouseHandler = bool(int butnr, str \type, str name);

public void visualizeStructure(Tree tree) 
	= render(buildStructureGraph(propagate(implode(tree))));

public Figure buildInteractiveStructureGraph(Structure ast, StructureMouseHandler mouseHandler) 
	= buildGraph(ast, mouseHandler, createEmptyContext());

public Figure buildStructureGraph(Structure ast) 
	= buildGraph(ast, bool(int butnr, str \type, str name) { return true; }, createEmptyContext());

public Figure buildContextAwareStructureGraph(Structure ast, SimContext context)
	= buildGraph(ast, bool(int butnr, str \type, str name) { return true; }, context);

public Figure buildContextAwareInteractiveStructureGraph(Structure ast, StructureMouseHandler mouseHandler, SimContext context)
	= buildGraph(ast, mouseHandler, context);

private Figure buildGraph(Structure ast, StructureMouseHandler mouseHandler, SimContext context)
{
	// Build the graph
	list[Figure] nodes = [];
	list[Edge] edges = [];
	
	visit (ast.body) 
	{
		// Match sensors
		case E:element(M, elementname("Sensor"), N, _): {
			edges += sensorEdges(E, N);
			nodes += sensorFigure(N, M, mouseHandler);
		}
		
		// Handle Joints
		case element(_, elementname("Joint"), N, _):
			nodes += jointFigure(N);
		
		// Handle Pumps
		case element(_, elementname("Pump"), N, _):
			nodes += pumpFigure(N, mouseHandler);
		
		// Handle Valves
		case element(M, elementname("Valve"), N, _): 	
			nodes += valveFigure(N, M, mouseHandler, context); 
		
		// Handle Central Heating Units
		case element(_, elementname("CentralHeatingUnit"), N, _):
			nodes += chuFigure(N, mouseHandler, context);
			
		// Handle radiators
		case E:element(M, elementname("Radiator"), N, _): {
			edges += radiatorEdges(E, N);
			nodes += radiatorFigure(N, mouseHandler, context);
		}
		
		// Handle Boilers
		case element(_, elementname("Boiler"), N, _):
			nodes += boilerFigure(N, mouseHandler, context);
			
		// Handle Rooms
		case element(_, elementname("Room"), N, _):
			nodes += roomFigure(N, mouseHandler, context);
		
		// Other elements
		case element(_, elementname(T), N, _): 			
			nodes += elementFigure(T, N, mouseHandler);
		
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
	
	return graph(nodes, edges, hint("layered"), gap(40));
}
 
//
// Render sensors
//

list[Edge] sensorEdges(Statement E, str to) = [ edge(name, to, lineColor("blue")) | str name <- collectSensorConnections(E) ];

Figure sensorFigure(str N, list[Modifier] modifiers, StructureMouseHandler mouseHandler) 
{ 
	str name = intercalate(" ", [ m.id | m <- modifiers]);
	 
	return ellipse(
		vcat([
			text(abbreviateSensorType(name), fontSize(9)), 
			text(N)
		]),
		id(N), 
		lineColor("blue"),
		onMouseDown(bool(int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, "Sensor", N);
		}));
}

//
// Render a Radiator
//

list[Edge] radiatorEdges(Statement E, str to) {
	if (/attribute(attributename("room"), valuelist(L)) <- E)
		return [edge(roomName, to, lineColor("gray"), lineStyle("dash")) | /variable(str roomName) <- L ];
		
	return [];
}

num getSimContextBucketValueNum(str element, str property, SimContext context)
{
	if (num v := getSimContextBucketValue(element, property, context)) return v;
	throw "Could not convert to num";
}

Figure radiatorFigure(str name, StructureMouseHandler mouseHandler, SimContext context)
{
	num temperature = getSimContextBucketValueNum(name, "temperature", context);
	list[Color] colors = colorSteps(color("blue"), color("red"), 100);
	Color color = colors[max(0, min(99, temperature))];
	
	Figure symbol = overlay([
			ellipse(size(40), fillColor(color)),
			overlay([point(0, 0.5), point(0.25, 0.3), point(0.75, 0.7), point(1, 0.5)], shapeConnected(true), size(40))
		], 
		id(name), 
		onMouseDown(bool(int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, "Radiator", name);
		})
	);
 
	return vcat([
		text(name, fontSize(9)),
		symbol
	], id(name), gap(5));
}

//
// Render an element
//

Figure elementFigure(str \type, str name, StructureMouseHandler mouseHandler) = 
	box(
		vcat([
			text(\type, fontSize(9)),
			text(name)
		]), 
		grow(1.5), 
		id(name), 
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, \type, name);
		})
	);

//
// Render a pump figure
//

Figure pumpFigure(str name, StructureMouseHandler mouseHandler)
{ 
	return box(
		vcat([
			text(name, fontSize(9)),
			pumpSymbol()
		], gap(5)), 
		id(name), 
		lineWidth(0),
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			mouseHandler(butnr, "Pump", name);
			return true;
		})
	);
}
	
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

private list[str] convertToStringList(list[value] L)
	= [ S | V <- L, str S := V ];

Figure valveFigure(str N, list[Modifier] M, StructureMouseHandler mouseHandler, SimContext context) {

	Figure symbol = valveSymbol(
		modifier("ThreeWay") in M  ? 3 : 2, 
		convertToStringList(getSimContextBucketList(N, "position", context))
	);
	
	visit (M) {
		case modifier("Manual"): 
			symbol = augmentManualValveSymbol(symbol, N);
			
		case modifier("Controlled"):
			symbol = augmentControlledValveSymbol(symbol, N);
	}

	return box(
		vcat([
			text(N, fontSize(9)),
			symbol
		], gap(5)),
		lineWidth(0),
		id(N),
		onMouseDown(bool(int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, "Valve", N);
		})
	);
}

Figure augmentManualValveSymbol(Figure symbol, str name)
{
	Figure controlSymbol = overlay([
			point(0, 0), 
			point(1, 0),
			point(0.5, 0),
			point(0.5, 0.5)
		], shapeConnected(true), width(20), height(40)
	);
		
	return overlay([controlSymbol, symbol]);
}

Figure augmentControlledValveSymbol(Figure symbol, str name) 
{
	Figure controlSymbol = 
		vcat([
			overlay(
				[ thetaPoint(<0.5, 1>, - angle, <0.5, 1>) | angle <- [ 0 .. 180 ], angle % 10 == 0],
				shapeConnected(true), width(20), height(10)),
			
			overlay([
				point(0, 0), 
				point(1, 0),
				point(0.5, 0),
				point(0.5, 0.5)
			], shapeConnected(true), width(20), height(40)),
			
			box(width(20), height(10), lineWidth(0))
		]);
	
	return overlay([controlSymbol, symbol]);
}
				
Figure valveSymbol(int ways, list[str] position)
	= (ways == 2) ? valveSymbolTwoWay(position) : valveSymbolThreeWay(position);

private Figure valveSymbolTwoWay(list[str] position)
{
	return
		overlay([
			point(0,0), 
			point(1,1), 
			point(1,0), 
			point(0, 1)
		], shapeConnected(true), shapeClosed(true), width(40), height(20));	
}

private Figure valveSymbolThreeWay(list[str] position)
{
	FProperty determineColor(bool active) = fillColor(active ? color("red") : color("white"));
	
	return 
		overlay([
		
			// Left
			overlay([
				point(0, 0), 		
				point(0.5, 0.33),
				point(0, 0.66)],
				shapeConnected(true), shapeClosed(true), width(40), height(32),
				determineColor(":a" in position)
			),
				
			// Right
			overlay([
				point(1, 0),		
				point(1, 0.66), 
				point(0.5, 0.33)],
				shapeConnected(true), shapeClosed(true), width(40), height(32),
				determineColor(":b" in position)	
			),
				
			// Middle
			overlay([	
				point(0.8, 1),
				point(0.2, 1),
				point(0.5, 0.33)],
				shapeConnected(true), shapeClosed(true), width(40), height(32),
				determineColor(":c" in position)
			)
			
		], width(40), height(32)
	);
}

//
// Render Central Heating units
//

Figure chuFigure(str name, StructureMouseHandler mouseHandler, SimContext context)
{
	value ignited = getSimContextBucketValue(name, "ignite", context);
	num temperature = getSimContextBucketValueNum(name, "burnertemp", context);
	
	list[Color] colors = colorSteps(color("blue"), color("red"), 100);
	Color ignitedColor = colors[max(0, min(99, temperature))];
	
	FProperty determineColor(bool active) = fillColor(active ? ignitedColor : color("white"));
	 
	return box(
		vcat([
			text("Central Heating Unit", fontSize(9)),
			text(name)
		]), 
		grow(1.5), 
		id(name),
		
		determineColor(ignited == true), 
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, "CentralHeatingUnit", name);
		})
	);
}

//
// Render Boilers
//

Figure boilerFigure(str name, StructureMouseHandler mouseHandler, SimContext context)
{
	int temperature = toInt(getSimContextBucketValueNum(name, "watertemp", context));
	list[Color] colors = colorSteps(color("blue"), color("red"), 100);
	Color color = colors[max(0, min(99, temperature))];
	 
	return box(
		vcat([
			text("Boiler", fontSize(9)),
			text(name)
		]), 
		grow(1.5), 
		id(name),
		
		fillColor(color), 
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, "Boiler", name);
		})
	);
}

//
// Render Rooms, max 30 degrees
//

Figure roomFigure(str name, StructureMouseHandler mouseHandler, SimContext context)
{
	int temperature = toInt(getSimContextBucketValueNum(name, "temperature", context));
	list[Color] colors = colorSteps(color("blue"), color("red"), 30);
	Color color = colors[max(0, min(39, temperature))];
	 
	return box(
		vcat([
			text("Room", fontSize(9)),
			text(name)
		]), 
		grow(1.5), 
		id(name),
		
		fillColor(color), 
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			return mouseHandler(butnr, "Room", name);
		})
	);
}

//
// Helper methods
//

private Figure point(num x, num y) = ellipse(align(x, y));

private Figure thetaPoint(tuple[num, num] r, int deg, tuple[num, num] offset) = point(
		cos(deg * PI() / 180) * r[0] + offset[0], 
		sin(deg * PI() / 180) * r[1] + offset[1]
	);

private Figure thetaPoint(num r, int deg) = thetaPoint(r, deg, <0,0>);
private Figure thetaPoint(num r, int deg) = thetaPoint(<r, r>, deg, <0,0>);

private list[str] collectSensorConnections(Statement sensor) {
	list[str] points = [];
	
	if ([_*, A:attribute(attributename("on"), _*), _*] := sensor.attributes) {
		top-down-break visit (A.val.values) {
			case variable(str name): points += name;
			case property(str name, _): points += name;
		}
	}
	
	return points;
}

private str abbreviateSensorType(str T)
{
	map[str,str] m = (
		"Temperature": 	"Temp",
		"Flow": 		"Flow",
		"Level": 		"Lvl",
		"Pressure":		"Pres",
		"Speed":		"Speed"
	);
	
	return m[T];
}

