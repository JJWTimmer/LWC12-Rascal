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
	list[ModifierSetDefinition] modifiers,	//of every set, only one keyword is allowed
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
	| selfPoint(list[list[Unit]] unit);	//elementname == sensorpoint
				 			 
public data ConnectionPointDefinition 
	= gasConnection(str name)
	| liquidConnection(str name)
	| unknownConnection(str name)	// gas OR liquid
	| attribConnections()			// modifier for type, attribute 'connections' for names
	| liquidConnectionModifier(str name, ModifierDefinition modifier) 	//only if modifier is defined
	| unknownConnectionModifier(str name, ModifierDefinition modifier)	//only if modifier is defined
	;


//The Element definitions:
//---------------------------------------------------------------------------------------------------
public map[str, ElementDefinition] Elements = (
	"Boiler" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("capacity", [VolumeUnits], numValue(50, ["liter"])),
			optionalAttrib("watertemp", [TemperatureUnits], numValue(80, ["Celsius"]))
		],
		[	//connectionpoints
			liquidConnection("centralheatingin"),
			liquidConnection("centralheatingout"),
			liquidConnection("hotwaterout"),
			liquidConnection("coldwaterin")
		],
		[	//sensorpoints
			selfPoint([TemperatureUnits])
		]
	),
	
	"CentralHeatingUnit" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("burnertemp", [TemperatureUnits], numValue(90, ["Celcius"])),
			optionalAttrib("power", [PowerUnits], numValue(2400, ["watt"])),
			optionalAttrib("ignite", [], boolValue(false))
		],
		[	//connectionpoints
			gasConnection("gasin"),
			liquidConnection("centrailheatingout"),
			liquidConnection("hotwaterout"),
			liquidConnection("coldwaterin")
		],
		[	//sensorpoints
			sensorPoint("ignitiondetect", [TemperatureUnits]),
			sensorPoint("internaltemp", [TemperatureUnits])
		]
	),
	
	
	"Exhaust" : element(
		[	//modifiers
			{"Gas", "Liquid"}
		],
		[],	//attributes
		[	//connectionpoints
			unknownConnection("[self]")
		],
		[]	//sensorpoints
	),
	
	
	"Joint" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("connections", [], listValue(["in", "out"]))
		],
		[	//connectionpoints
			attribConnections()
		],
		[]	//sensorpoints
	),
	
	
	"Pipe" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("diameter", [LengthUnits], numValue(15, ["mm"])),
			requiredAttrib("length", [LengthUnits])
		],
		[],	//connectionpoints
		[	//sensorpoints
			selfPoint([TemperatureUnits])
		]
	),
	
	
	"Pump" : element(
		[	//modifiers
			{"Vacuum", "Venturi"}
		],
		[	//attributes
			requiredAttrib("capacity", [VolumeUnits, TimeUnits])
		],
		[	//connectionpoints
			liquidConnection("in"),
			liquidConnection("out"),
			liquidConnectionModifier("suck", "Venturi")
		],
		[	//sensorpoints
			selfPoint([SpeedUnits])
		]
	),
	
	
	"Radiator" : element(
		[],	//modifiers
		[	//attributes
			requiredAttrib("heatcapacity", [PowerUnits])
		],
		[	//connectionpoints
			liquidConnection("in"),
			liquidConnection("out")
		],
		[	//sensorpoints
			selfPoint([TemperatureUnits])
		]
	),
	
	
	"Sensor" : element(
		[	//modifiers
			{
				"Speed",
				"Temperature",
				"Flow",
				"Pressure",
				"Level"
			}
		], 
		[	//attributes
			requiredAttrib("on", []),   //sensorpoint
			requiredAttrib("range", []) //depends on modifier
		],
		[	//connectionpoints
			liquidConnection("in"),
			liquidConnection("out")
		],
		[	//sensorpoints
			selfPoint([TemperatureUnits])
		]
	),
	
	
	"Source" : element(
		[	//modifiers
			{"Gas", "Liquid"}
		],
		[	//attributes
			requiredAttrib("flowrate", [VolumeUnits, TimeUnits])
		],
		[	//connectionpoints
			unknownConnection("[self]")
		],
		[]	//sensorpoints
	),
	
	
	"Valve" : element(
		[	//modifiers
			{"Controlled"},
			{"Pin"},
			{"ThreeWay"}
		],
		[	//attributes
			optionalAttrib("position", [], listValue([":closed"]))
		],
		[	//connectionpoints
			unknownConnection("a"),
			unknownConnection("b"),
			unknownConnectionModifier("c", "ThreeWay")
			
		],
		[]	//sensorpoints
	)
);