module lang::lwc::sim::Context

import lang::lwc::structure::AST;

data SimContext = simContext(list[ElementState] elems, list[SensorValue] sensors, list[ManualValue] manuals);
data ElementState = state(str name, list[SimProperty] props);
data SimProperty = simProp(str name, ValueList val);
data SensorValue = sensor(str name, ValueList val);
data ManualValue = manual(str name, ValueList val);

public SimContext createContext(Structure ast) {
	list[ElementState] elems = [];
	list[SensorValue] sensors = [];
	list[ManualValue] manuals = [];
	
	visit(ast) {
		case element(modifiers, etype, name, attributes) : {
			
			list[SimProperty] props = [simProp(pname, pval) | attribute(pname, pval)  <- attributes];
			ElementState newState = state(name, props);
			
			elems += newState;
		}
	}
	
	return simContext(elems, sensors, manuals);
}