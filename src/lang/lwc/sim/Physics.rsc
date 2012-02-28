module lang::lwc::sim::Physics

import lang::lwc::sim::Context;
import lang::lwc::sim::Reach;

import util::Maybe;
import IO;

public SimContext physicsAction(SimContext ctx) {
	ctx.\data.elements = visit (ctx.\data.elements) {
		case S:state(name,"Room",props) : {
			radiators = getRoomRadiators(name, ctx);
			if (radiators != {} && roomWaterTemp(radiators, ctx) > 0) {
				waterTemp = roomWaterTemp(radiators, ctx);
				
				//find the room temperature and increment it unless >= watertemp
				if ([H*, simProp("temperature", simBucketNumber(temp)), T*] := props) {
					S.props = H+T+[simProp(simProp("temperature", simBucketNumber(temp < waterTemp? temp+1 : temp)))];
				}

				insert S;
			} else {
				//find the room temperature and increment it unless >= watertemp
				if ([H*, simProp("temperature", simBucketNumber(temp)), T*] := props) {
					S.props = H+T+[simProp(simProp("temperature", simBucketNumber(temp>0?temp-1:temp)))];
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
		case state(radiator, "Radiator", [_*, simProp("Room", simBucketVariable(roomname)) ,_*]) : {
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

private int roomWaterTemp(set[str] radiators, SimContext ctx) {
	chus = getCentralHeatingUnits(ctx, true);
	int roomHeating = -1;
	
	visit(ctx.\data.elements) {
		case state(chu, _, [_*, simProp("burnertemp",simBucketNumber(temp)), _*]) : {
			if (chu in chus) {
				for (radiator <- radiators) {
					if(isReachable(ctx.structureGraph, ctx, chu, just("hotwaterout"), radiator, just("in")) && isReachable(ctx.structureGraph, ctx, radiator, just("out"), chu, just("coldwaterin"))) {
						roomHeating = temp;
					}
				}
			}
		}
	}
	
	return roomHeating;
}