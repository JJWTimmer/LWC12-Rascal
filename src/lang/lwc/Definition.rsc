module lang::lwc::Definition

// Units definitions
public alias Unit = str;
public list[Unit] VolumeUnits = ["cm3", "dm3", "m3", "liter"];
public list[Unit] AreaUnits = ["mm2", "cm2", "dm2", "m2"];
public list[Unit] ForceUnits = ["N"];
public list[Unit] TimeUnits = ["sec", "min", "hour", "day"];
public list[Unit] LengthUnits = ["mm", "cm", "dm", "m", "km"];
public list[Unit] PowerUnits = ["watt"];
public list[Unit] TemperatureUnits = ["Celcius", "kelvin", "Fahrenheit"];
public list[Unit] SpeedUnits = ["rpm"];
public list[Unit] Units = VolumeUnits + AreaUnits + ForceUnits + TimeUnits + LengthUnits + PowerUnits + TemperatureUnits + SpeedUnits;

public alias ModifierDefinition = str;
public alias ModifierSetDefinition = set[ModifierDefinition];

public data ElementDefinition = element(
	list[ModifierSetDefinition] modifiers,	//of every set, only one keyword is allowed
	list[AttributeDefinition] attributes, 
	list[set[ConnectionPointDefinition]] connectionpoints, 
	list[SensorPointDefinition] sensorpoints
);

public data AttributeDefinition 
	= requiredAttrib(str name, list[list[Unit]] unit, bool editable)
	| optionalAttrib(str name, list[list[Unit]] unit, ValueDefinition defaultvalue, bool editable)
	| optionalModifierAttrib(str name, str modifier, list[list[Unit]] unit, ValueDefinition defaultvalue, bool editable)
	| hiddenProperty(str name, list[list[Unit]] unit, ValueDefinition defaultvalue);

public data ValueDefinition 
	= numValue(num val, list[Unit] unit)
	| boolValue(bool boolean)
	| listValue(list[str] contents)
	| none();
				  	   
public data SensorPointDefinition 
	= sensorPoint(str name, str property)
	| selfPoint(str property); //elementname == sensorpoint
				 			 
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
			optionalAttrib("capacity", [VolumeUnits], numValue(50, ["liter"]), false),
			hiddenProperty("watertemp", [TemperatureUnits], numValue(80, ["Celsius"]))
		],
		[	//connectionpoints
			{
				liquidConnection("centralheatingin"),
				liquidConnection("centralheatingout")
			},
			{
				liquidConnection("hotwaterout"),
				liquidConnection("coldwaterin")
			}
		],
		[	//sensorpoints
			selfPoint("watertemp")
		]
	),
	
	"CentralHeatingUnit" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("burnertemp", [TemperatureUnits], numValue(90, ["Celcius"]), true),
			optionalAttrib("maxpower", [PowerUnits], numValue(2400, ["watt"]), false),
			hiddenProperty("ignite", [], boolValue(false)),
			hiddenProperty("power", [PowerUnits], numValue(2400, ["watt"]))
		],
		[	//connectionpoints
			{
				gasConnection("gasin")
			},
			{
				liquidConnection("hotwaterout"),
				liquidConnection("coldwaterin")
			}
		],
		[	//sensorpoints
			sensorPoint("ignite"),
			sensorPoint("burnertemp")
		]
	),
	
	
	"Exhaust" : element(
		[	//modifiers
			{"Gas", "Liquid"}
		],
		[],	//attributes
		[	//connectionpoints
			{
				unknownConnection("[self]")
			}
		],
		[]	//sensorpoints
	),
	
	
	"Joint" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("connections", [], listValue(["in", "out"]), false)
		],
		[	//connectionpoints
			{
				attribConnections()
			}
		],
		[]	//sensorpoints
	),
	
	
	"Pipe" : element(
		[],	//modifiers
		[	//attributes
			optionalAttrib("diameter", [LengthUnits], numValue(15, ["mm"]), false),
			requiredAttrib("length", [LengthUnits], false),
			hiddenProperty("flow", [VolumeUnits, TimeUnits], numValue(1, ["km", "hour"])),
			hiddenProperty("temperature", [TemperatureUnits], numValue(15, ["Celcius"]))
		],
		[],	//connectionpoints
		[	//sensorpoints
			sensorPoint("flow", "flow"),
			sensorPoint("temperature", "temperature")
		]
	),
	
	
	"Pump" : element(
		[	//modifiers
			{"Vacuum", "Venturi"} //default: regular
		],
		[	//attributes
			requiredAttrib("capacity", [VolumeUnits, TimeUnits], false),
			hiddenProperty("throughput", [VolumeUnits, TimeUnits], numValue(0, ["liter", "hour"])),
			hiddenProperty("enabled", [], boolValue(false))
		],
		[	//connectionpoints
			{
				liquidConnection("in"),
				liquidConnection("out")
			},
			{
				liquidConnectionModifier("suck", "Venturi")
			}
		],
		[	//sensorpoints
			selfPoint("throughput")
		]
	),
	
	
	"Radiator" : element(
		[],	//modifiers
		[	//attributes
			requiredAttrib("heatcapacity", [PowerUnits], false),
			requiredAttrib("room", [], false),
			hiddenProperty("temperature", [TemperatureUnits], numValue(15, ["Celsius"]))
		],
		[	//connectionpoints
			{
				liquidConnection("in"),
				liquidConnection("out")
			}
		],
		[	//sensorpoints
			selfPoint("temperature")
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
			requiredAttrib("on", [], false),   	// sensorpoint
			requiredAttrib("range", [], false), // depends on modifier
			hiddenProperty("value", [], numValue(14, ["Celsius"]))
		],
		[],	//connectionpoints
		[]	//sensorpoints
	),
	
	
	"Source" : element(
		[	//modifiers
			{"Gas", "Liquid"}
		],
		[	//attributes
			requiredAttrib("flowrate", [VolumeUnits, TimeUnits], true)
		],
		[	//connectionpoints
			{
				unknownConnection("[self]")
			}
		],
		[]	//sensorpoints
	),
	
	
	"Valve" : element(
		[	//modifiers
			{"Controlled", "Manual"},
			{"Pin"},					//default: Discrete
			{"ThreeWay"}				//default: TwoWay
		],
		[	//attributes
			optionalAttrib("position", [], listValue([]), true),
			optionalModifierAttrib("flowrate", "Pin", [VolumeUnits, TimeUnits], numValue(1, ["m3", "hour"]), true) // only for pin-valve
		],
		[	//connectionpoints
			{
				unknownConnection(":a"),
				unknownConnection(":b"),
				unknownConnectionModifier(":c", "ThreeWay")
			}
		],
		[]	//sensorpoints
	),
	
	
	"Room" : element(
		[],	//modifiers
		[	//attributes
			requiredAttrib("volume", [VolumeUnits], false),
			hiddenProperty("temperature", [TemperatureUnits], numValue(15, ["Celcius"]))
		],
		[],	//connectionpoints
		[	//sensorpoints
			selfPoint("temperature")
		]
	)
);

//The sensor modifier definitions:
//---------------------------------------------------------------------------------------------------
public map[str, list[list[Unit]]] SensorModifiers = (
	"Speed"			:	[SpeedUnits],
	"Temperature"	:	[TemperatureUnits],
	"Flow"			:	[VolumeUnits, TimeUnits],
	"Pressure"		:	[ForceUnits, AreaUnits],
	"Level"			:	[LengthUnits]
);
