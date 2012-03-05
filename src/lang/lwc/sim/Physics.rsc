module lang::lwc::sim::Physics

import lang::lwc::sim::Context;
import lang::lwc::sim::Reach;

import util::Maybe;
import IO;

public SimContext physicsAction(SimContext ctx) {
	println("doing physics action");
	ctx.\data.elements = visit (ctx.\data.elements) {
		case S:state(name,"Room",props) : {
			println("found room <name> in states");
			radiators = getRoomRadiators(name, ctx);
			println("radiators: <radiators>");
			if (radiators != {} && averageRadiatorTemp(name, ctx) > 0) {
				println("watertemp in this room: <averageRadiatorTemp(name, ctx)>");
				ctx = setRoomRadiatorTemp(radiators, ctx);
				
				waterTemp = averageRadiatorTemp(name, ctx);
				
				//find the room temperature and increment it unless >= watertemp
				if ([H*, simProp("temperature", simBucketNumber(temp)), T*] := props) {
					println("average radiator temperature in this room: <waterTemp>");
					S.props = H+T+[simProp("temperature", simBucketNumber((temp < waterTemp)? (temp+1) : temp))];
				}

				insert S;
			} else {
				println("average temp: <averageRadiatorTemp(name, ctx) > 0> Celcius");
				//find the room temperature and decrement it unless >= watertemp
				if ([H*, simProp("temperature", simBucketNumber(temp)), T*] := props) {
					S.props = H+T+[simProp("temperature", simBucketNumber((temp > 0)? (temp-1) : temp))];
				}

				insert S;
			}
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

private SimContext setRoomRadiatorTemp(set[str] radiators, SimContext ctx) {
	chus = getCentralHeatingUnits(ctx, true);
	println("heating CHUs: <chus>");
	
	visit(ctx.\data.elements) {
		case state(chu, _, [_*, simProp("burnertemp",simBucketNumber(temp)), _*]) : {
			if (chu in chus) {
				for (radiator <- radiators) {
					if(isReachable(ctx.reachGraph, ctx, chu, just("hotwaterout"), radiator, just("in")) && isReachable(ctx.reachGraph, ctx, radiator, just("out"), chu, just("coldwaterin"))) {
						println("radiator <radiator> reachable");
						ctx = setSimContextBucket(radiator, "temperature", temp, ctx);
					}
				}
			}
		}
	}
	
	return ctx;
}

private int averageRadiatorTemp(str room, SimContext ctx) {
	list[tuple[int power, int temp]] temperatureList = [];
	
	visit(ctx.\data.elements) {
		case state(_, "Radiator", props:[_*, simProp("room",simBucketVariable(room)), _*]) : {
			for(prop <- props) {
				int power = -1;
				int temp = -1;
				
				if (simProp("heatcapacity", simBucketNumber(hc)) := prop) {
					power = hc;
				}
				if (simProp("temperature", simBucketNumber(tp)) := prop) {
					temp = tp;
				}
				
				if (power > -1 && temp > -1) {
					temperatureList += [<power, temp>];
				}
			}
		}
	}
	
	if (temperatureList == []) return 0;
	
	iprintln(temperatureList);
	
	int cumulativeTemp = (0 | it + (hc*tp)  | <hc, tp> <- temperatureList);
	int averageTemp = cumulativeTemp / (0 | it + hc | <hc, _> <- temperatureList);
	
	return averageTemp;
}