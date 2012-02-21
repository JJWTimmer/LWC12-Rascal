module lang::lwc::structure::Visualizer

import lang::lwc::structure::Load;
import lang::lwc::structure::Propagate;
import lang::lwc::structure::AST;

import lang::lwc::Constants;

import vis::Figure;
import vis::Render;

import List;
import IO;
import ParseTree;
import util::Math;

public void visualizeStructure(Tree tree) = render(buildStructureGraph(propagate(implode(tree))));

Figure sidebar = buildSidebar("", []);

public Figure buildSidebar(str etype, str name, list[Attribute] attributes) {
/*	list[Attribute] editableAttribs = [];
	if(EditableProps[etype]?) {
		list[str] editables = EditableProps[etype];
		for(A:attribute(attributename(str aname), _) <- attributes) {
			if(aname in editables) {
				editableAttribs += A;
			}
		} 
	}
	
	for(attribute <- editableAttribs) {
	
	}
	attribField = buildField(
*/
	return box(vcat([text(name, fontSize(20))
					
					]));
}

public Figure buildStructureGraph(Structure ast)
{
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
		case element(_, elementname("Pump"), N, A):
			nodes += pumpFigure(N, A);
		
		// Handle Valves
		case element(M, elementname("Valve"), N, A): 	
			nodes += valveFigure(N, M, A); 
		
		// Handle radiators
		case E:element(M, elementname("Radiator"), N, A): {
			edges += radiatorEdges(E, N);
			nodes += radiatorFigure(N, A);
		}
			
		// Other elements
		case element(_, elementname(T), N, A): 			
			nodes += elementFigure(T, N, A);
		
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
	
	return graph(nodes, edges, gap(40));
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
			text(abbreviateSensorType(name), fontSize(9)), 
			text(N)
		]), 
		id(N), lineColor("blue"));
}

//
// Render a Radiator
//

list[Edge] radiatorEdges(Statement E, str to) {
	if (/attribute(attributename("room"), valuelist(L)) <- E)
		return [edge(roomName, to, lineColor("gray"), lineStyle("dash")) | /variable(str roomName) <- L ];
		
	return [];
}

Figure radiatorFigure(str name, list[Attribute] attributes)
{
	Figure symbol = overlay([
		ellipse(size(40)),
		overlay([point(0, 0.5), point(0.25, 0.3), point(0.75, 0.7), point(1, 0.5)], shapeConnected(true), size(40))
	], id(name)
	, onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
		if(butnr == 1) {
			sidebar = buildSidebar("Radiator", name, attributes);
		}
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

Figure elementFigure(str \type, str name, list[Attribute] attributes) = 
	box(
		vcat([
			text(\type, fontSize(9)),
			text(name)
		]), grow(1.5), id(name)
		, onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			if(butnr == 1) {
				sidebar = buildSidebar(\type, name, attributes);
			}
		})
	);

//
// Render a pump figure
//

Figure pumpFigure(str name, list[Attribute] attributes) = 
	box(
		vcat([
			text(name, fontSize(9)),
			pumpSymbol()
		], gap(5)), 
		id(name), lineWidth(0)
		,onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			if(butnr == 1) {
				sidebar = buildSidebar("Pump", name, attributes);
			}
		})
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

Figure valveFigure(str N, list[Modifier] M, list[Attribute] attributes) {

	Figure symbol = valveSymbol(modifier("ThreeWay") in M  ? 3 : 2);
	
	visit (M)
	{
		case modifier("Manual"): 
			symbol = augmentManualValveSymbol(symbol, N, attributes);
			
		case modifier("Controlled"):
			symbol = augmentControlledValveSymbol(symbol, N, attributes);
	}

	return box(
		vcat([
			text(N, fontSize(9)),
			symbol
		], gap(5)),
		lineWidth(0),
		id(N));
}

Figure augmentManualValveSymbol(Figure symbol, str name, list[Attribute] attributes)
{
	Figure controlSymbol = overlay([
		point(0, 0), 
		point(1, 0),
		point(0.5, 0),
		point(0.5, 0.5)
	], shapeConnected(true), width(20), height(40)
	, onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
		if(butnr == 1) {
			sidebar = buildSidebar("Valve", name, attributes);
		}
	}));
		
	return overlay([controlSymbol, symbol]);
}

Figure augmentControlledValveSymbol(Figure symbol, str name, list[Attribute] attributes) 
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
		],onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			if(butnr == 1) {
				sidebar = buildSidebar("Valve", name, attributes);
			}
		}));
	
	return overlay([controlSymbol, symbol]);
}
				
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

