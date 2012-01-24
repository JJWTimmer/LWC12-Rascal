module lang::lwc::Definition

// Units definitions
public alias Unit = str;
public list[Unit] VolumeUnits = ["cm3", "dm3", "m3", "liter"];
public list[Unit] TimeUnits = ["sec", "min", "hour", "day"];
public list[Unit] LengthUnits = ["mm", "cm", "dm", "m", "km"];
public list[Unit] PowerUnits = ["watt"];
public list[Unit] TemperatureUnits = ["Celcius", "kelvin", "Fahrenheit"];
public list[Unit] SpeedUnits = ["rpm"];
public list[Unit] Units = VolumeUnits + TimeUnits + LengthUnits + PowerUnits + TemperatureUnits + SpeedUnits;

public alias ModifierDefinition = str;
public alias ModifierSetDefinition = set[ModifierDefinition];

public data ElementDefinition = element(
	list[ModifierSetDefinition] modifiers, 
	list[AttributeDefinition] attributes, 
	list[ConnectionPointDefinition] connectionpoints, 
	list[SensorPointDefinition] sensorpoints
);

public data AttributeDefinition 
	= requiredAttrib(str name, list[list[Unit]] unit)
	| optionalAttrib(str name, list[list[Unit]] unit, ValueDefinition defaultvalue);

public data ValueDefinition 
	= numValue(num val, list[Unit] unit)
	| boolValue(bool boolean)
	| listValue(list[str] contents);
				  	   
public data SensorPointDefinition 
	= sensorPoint(str name, list[list[Unit]] unit)
	| selfPoint(list[list[Unit]] unit);
				 			 
public data ConnectionPointDefinition 
	= gasConnection(str name)
	| liquidConnection(str name)
	| unknownConnection(str name)
	| attribConnections()
	| liquidConnectionModifier(str name, ModifierDefinition modifier)
	| unknownConnectionModifier(str name, ModifierDefinition modifier)
	;

public ElementDefinition Boiler =
	element(	[], //modifiers
				[
					optionalAttrib("capacity", [VolumeUnits], numValue(50, ["liter"])),
					optionalAttrib("watertemp", [TemperatureUnits], numValue(80, ["Celsius"]))
				],  //attributes
				[
					liquidConnection("centralheatingin"),
					liquidConnection("centrailheatingout"),
					liquidConnection("hotwaterout"),
					liquidConnection("coldwaterin")
				], //connectionpoints
				[
					selfPoint([TemperatureUnits])
				]  // sensorpoints
	);


public ElementDefinition CentralHeatingUnit =
	element(	[], //modifiers
				[
					optionalAttrib("burnertemp", [TemperatureUnits], numValue(90, ["Celcius"])),
					optionalAttrib("power", [PowerUnits], numValue(1200, ["watt"])),
					optionalAttrib("ignite", [], boolValue(false))
				],  //attributes
				[
					gasConnection("gasin"),
					liquidConnection("centrailheatingout"),
					liquidConnection("hotwaterout"),
					liquidConnection("coldwaterin")
				], //connectionpoints
				[
					sensorPoint("ignitiondetect", [TemperatureUnits]),
					sensorPoint("internaltemp", [TemperatureUnits])
				]  // sensorpoints
	);
	
	
public ElementDefinition Exhaust =
	element(	[
					{"Gas", "Liquid"}
				], //modifiers
				[],  //attributes
				[
					unknownConnection("[self]")
				], //connectionpoints
				[]  // sensorpoints
	);

public ElementDefinition Joint =
	element(	[], //modifiers
				[
					optionalAttrib("connections", [], listValue(["in", "out"]))
				],  //attributes
				[
					attribConnections()
				], //connectionpoints
				[]  // sensorpoints
	);
	


public ElementDefinition Pipe =
	element(	[], //modifiers
				[
					optionalAttrib("diameter", [LengthUnits], numValue(15, ["mm"])),
					requiredAttrib("length", [LengthUnits])
				],  //attributes
				[], //connectionpoints
				[
					selfPoint([TemperatureUnits])
				]  // sensorpoints
	);
	

public ElementDefinition Pump =
	element(	[
					{"Vacuum", "Venturi"}
				], //modifiers
				[
					requiredAttrib("capacity", [VolumeUnits, TimeUnits])
				],  //attributes
				[
					liquidConnection("in"),
					liquidConnection("out"),
					liquidConnectionModifier("suck", "Venturi")
				], //connectionpoints
				[
					selfPoint([SpeedUnits])
				]  // sensorpoints
	);


public ElementDefinition Radiator =
	element(	[], //modifiers
				[
					requiredAttrib("heatcapacity", [PowerUnits])
				],  //attributes
				[
					liquidConnection("in"),
					liquidConnection("out")
				], //connectionpoints
				[
					selfPoint([TemperatureUnits])
				]  // sensorpoints
	);
	


public ElementDefinition Sensor =
	element(	[
					{
						"Speed",
						"Temperature",
						"Flow",
						"Pressure",
						"Level"
					}
				], //modifiers
				[
					requiredAttrib("on", []),   //sensorpoint
					requiredAttrib("range", []) //depends on modifier
				],  //attributes
				[
					liquidConnection("in"),
					liquidConnection("out")
				], //connectionpoints
				[
					selfPoint([TemperatureUnits])
				]  // sensorpoints
	);
	
	
	
	
public ElementDefinition Source =
	element(	[
					{"Gas", "Liquid"}
				], //modifiers
				[
					requiredAttrib("flowrate", [VolumeUnits, TimeUnits])
				],  //attributes
				[
					unknownConnection("[self]")
				], //connectionpoints
				[]  // sensorpoints
	);

public ElementDefinition Valve =
	element(	[
					{"Controlled"},
					{"Pin"},
					{"ThreeWay"}
				], //modifiers
				[
					optionalAttrib("position", [], listValue([":closed"]))
				],  //attributes
				[
					unknownConnection("a"),
					unknownConnection("b"),
					unknownConnectionModifier("c", "ThreeWay")
					
				], //connectionpoints
				[] // sensorpoints
	);
	

public map[str, ElementDefinition] Elements = (
	"Boiler" 	: Boiler,
	"CentralHeatingUnit" : CentralHeatingUnit,
	"Exhaust" 	: Exhaust,
	"Joint" 	: Joint,
	"Pipe" 		: Pipe,
	"Pump" 		: Pump,
	"Radiator" 	: Radiator,
	"Sensor" 	: Sensor,
	"Source" 	: Source,
	"Valve" 	: Valve
);

public list[str] ElementNames = [key | key <- Elements];
