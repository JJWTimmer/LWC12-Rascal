module lang::lwc::sim::Physics

import lang::lwc::sim::Context;
import lang::lwc::sim::Reach;

import util::Maybe;
import List;
import IO;

public SimContext physicsAction(SimContext ctx) {
	println("doing physics action");

	ctx = modifyRadiatorTemp(ctx);
	ctx = modifyRoomTemp(ctx);
	
	return ctx;
}

private SimContext modifyRadiatorTemp(SimContext ctx) {
	visit (ctx.\data.elements) {
		case S:state(name,"Room",props) : {
			radiators = getRoomRadiators(name, ctx);
			if (radiators != {}) {
				ctx = setRadiatorTemp(radiators, ctx);
			}
		}
	}

	return ctx;
}

private SimContext modifyRoomTemp(SimContext ctx) {
	ctx.\data.elements = visit (ctx.\data.elements) {
		case S:state(name, "Room", props) : {
			println("found room <name> in states");
			
			waterTemp = averageRadiatorTemp(name, ctx);
			
			println("average radiator temp in this room: <waterTemp> Celcius");
			
			//find the room temperature and increment it unless >= watertemp
			if ([H*, simProp("temperature", simBucketNumber(temp)), T*] := props) {
				println("room temp: <temp> Celcius");
				
				int tempDelta = 0;
				
				if (temp < waterTemp) {
					tempDelta = 1;
				} else if (temp > waterTemp) {
					tempDelta = -1;
				}
				
				S.props = H+T+[simProp("temperature", simBucketNumber(temp+tempDelta))];
				
				iprintln(S.props);
			}

			insert S;
		}
	}

	return ctx;
}

private set[str] getRoomRadiators(str roomname, SimContext ctx) {
	set[str] radiators = {};
	visit (ctx.\data.elements) {
		case state(radiator, "Radiator", [_*, simProp("room", simBucketVariable(roomname)) ,_*]) : {
			radiators += radiator;
		}
	}
	
	return radiators;
}

private set[str] getCentralHeatingUnits(SimContext ctx, bool heating) {
	set[str] chus = {};
	visit (ctx.\data.elements) {
		case state(chu, "CentralHeatingUnit", [_*, simProp("ignite", simBucketBoolean(heating)), _*]) : {
			chus += chu;
		}
	}
	
	return chus;
}

private SimContext setRadiatorTemp(set[str] radiators, SimContext ctx) {
	chus = getCentralHeatingUnits(ctx, true);
	println("heating CHUs: <chus>");
	
	visit(ctx.\data.elements) {
		case state(chu, _, [_*, simProp("burnertemp",simBucketNumber(temp)), _*]) : {
			if (chu in chus) {
				for (radiator <- radiators) {
					if(isReachable(ctx.reachGraph, ctx, chu, just("hotwaterout"), radiator, just("in")) && isReachable(ctx.reachGraph, ctx, radiator, just("out"), chu, just("coldwaterin"))) {
						println("radiator <radiator> reachable, CHU temp: <temp>");
						ctx = setSimContextBucket(radiator, "temperature", simBucketNumber(temp), ctx);
					}
				}
			}
		}
	}
	
	return ctx;
}

private int averageRadiatorTemp(str room, SimContext ctx) {
	list[tuple[int, int]] temperatureList = [];

	visit(ctx.\data.elements) {
		case state(_, "Radiator", props:[_*, simProp("room",simBucketVariable(room)), _*]) : {
			int power = -1;
			int temp = -1;
			
			for(prop <- props) {				
				if (simProp("heatcapacity", simBucketNumber(hc)) := prop) {
					power = hc;
				}
				if (simProp("temperature", simBucketNumber(tp)) := prop) {
					temp = tp;
				}
			}

			if (power > -1 && temp > -1) {
				
				temperatureList += <power, temp>;
			}
		}
	}
	
	if (size(temperatureList) == 0) return 0;
	
	int cumulativeTemp = (0 | it + (hc*tp)  | <hc, tp> <- temperatureList);
	int averageTemp = cumulativeTemp / (0 | it + hc | <hc, _> <- temperatureList);
	
	return averageTemp;
}