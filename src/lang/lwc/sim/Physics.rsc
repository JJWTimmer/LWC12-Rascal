module lang::lwc::sim::Physics

import lang::lwc::sim::Context;
import lang::lwc::sim::Reach;
import lang::lwc::sim::Graph;

import util::Maybe;
import util::Math;
import Graph;
import List;
import IO;

public SimContext physicsAction(SimContext ctx) {
	println("doing physics action");

	ctx = modifyRadiatorTemp(ctx);
	ctx = modifyRoomTemp(ctx);
	ctx = modifyBoilerTemp(ctx);
	
	return ctx;
}

private SimContext modifyRadiatorTemp(SimContext ctx) {
	visit (ctx.\data.elements) {
		case S:state(name,"Radiator",props) : {
			ctx = setRadiatorTemp(name, ctx);
		}
	}

	return ctx;
}

private SimContext modifyRoomTemp(SimContext ctx) {
	visit (ctx.\data.elements) {
		case S:state(name, "Room", props) : {
			println("found room <name> in states");
			
			waterTemp = averageRadiatorTemp(name, ctx);
			
			println("average radiator temp in this room: <waterTemp> Celcius");
			
			simBucketNumber(temp) = getSimContextBucket(name, "temperature", ctx);
			println("room temp: <temp> Celcius");
			
			tempDelta = 0;
			
			if (temp < waterTemp) {
				tempDelta = 1;
			} else if (temp >= waterTemp) {
				tempDelta = -0.5;
			}
			
			ctx = setSimContextBucket(name, "temperature", simBucketNumber(temp+tempDelta), ctx);

		}
	}

	return ctx;
}

private SimContext modifyBoilerTemp(SimContext ctx) {
	chus = getCentralHeatingUnits(ctx, true);
	
	
	visit(ctx.\data.elements) {
		case state(boilername, "Boiler", boilerprops) : {
			heatertemp = 0;
			for (state(chuname, "CentralHeatingUnit", _) <- ctx.\data.elements) {
				chuOutReachable = isReachable(ctx.reachGraph, ctx, chuname, just("hotwaterout"), boilername, just("centralheatingin"));
				chuInReachable = isReachable(ctx.reachGraph, ctx, boilername, just("centralheatingout"), chuname, just("coldwaterin"));
				if (chuOutReachable && chuInReachable)
					heatertemp = max(getSimContextBucket(chuname, "burnertemp", ctx).n, heatertemp);
			}
			
			tempDelta = 0;
			simBucketNumber(oldTemp) = getSimContextBucket(boilername, "watertemp", ctx);
			
			if (oldTemp < heatertemp) {
				tempDelta = 1;
			} else if (oldTemp >= heatertemp) {
				tempDelta = -0.5;
			}
			
			println("new boilertemp: <oldTemp+tempDelta> Celcius");
			ctx = setSimContextBucket(boilername, "watertemp", simBucketNumber(oldTemp+tempDelta), ctx);

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

private SimContext setRadiatorTemp(str radiator, SimContext ctx) {
	chus = getCentralHeatingUnits(ctx, true);
	reached = false;
	println("heating CHUs: <chus>");
	
	visit(ctx.\data.elements) {
		case state(chu, _, [_*, simProp("burnertemp",simBucketNumber(temp)), _*]) : {
			if (chu in chus) {
				if(isReachable(ctx.reachGraph, ctx, chu, just("hotwaterout"), radiator, just("in")) && isReachable(ctx.reachGraph, ctx, radiator, just("out"), chu, just("coldwaterin"))) {
					println("radiator <radiator> reachable, CHU temp: <temp>");
					reached = true;
					ctx = setSimContextBucket(radiator, "temperature", simBucketNumber(temp), ctx);
				}
			}
		}
	}
	
	if (!reached) {
		simBucketNumber(oldTemp) = getSimContextBucket(radiator, "temperature", ctx); 
		ctx = setSimContextBucket(radiator, "temperature", simBucketNumber(15), ctx);
	}
	
	return ctx;
}

private num averageRadiatorTemp(str room, SimContext ctx) {
	list[tuple[num, num]] temperatureList = [];

	visit(ctx.\data.elements) {
		case state(_, "Radiator", props:[_*, simProp("room",simBucketVariable(room)), _*]) : {
			power = -1;
			temp = -1;
			
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
	
	cumulativeTemp = (0 | it + (hc*tp)  | <hc, tp> <- temperatureList);
	averageTemp = cumulativeTemp / (0 | it + hc | <hc, _> <- temperatureList);
	
	return averageTemp;
}