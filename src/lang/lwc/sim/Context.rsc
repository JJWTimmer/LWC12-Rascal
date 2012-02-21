module lang::lwc::sim::Context

import lang::lwc::structure::AST;
import IO;

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
		case element(modifiers, elementname(etype), name, attributes) : {
		
			if (etype != "Sensor") {
				list[SimProperty] props = [simProp(pname, pval) | attribute(attributename(pname), pval)  <- attributes]
				+ [simProp(pname, pval) | realproperty(pname, pval)  <- attributes];
				elems += state(name, props);	
			} else {
				sensors += sensor(name, valuelist([]));
			}
		}
	}	
	
	return simContext(elems, sensors, manuals);
}

public value getSimContextProperty(str element, str property, SimContext ctx)
{
	if (/state(element, L) := ctx.elems)
	{
		if (/simProp(property, valuelist([V, _*])) := L)
			iprintln(V);
	}
	
	return 0;
}