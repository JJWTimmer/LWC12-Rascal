module lang::lwc::Elements

//Units
public alias Unit = str;
public list[Unit] VolumeUnits = ["cm3", "dm3", "m3", "liter"];
public list[Unit] TimeUnits = ["sec", "min", "hour", "day"];
public list[Unit] LengthUnits = ["mm", "cm", "dm", "m", "km"];
public list[Unit] PowerUnits = ["watt"];
public list[Unit] TemperatureUnits = ["Celcius", "kelvin", "Fahrenheit"];
public list[Unit] SpeedUnits = ["rpm"];

public list[Unit] Units = VolumeUnits + TimeUnits + LengthUnits + PowerUnits + TemperatureUnits + SpeedUnits;

public data Element = element(list[ModifierSet] modifiers, list[Attribute] attributes, list[ConnectionPoint] connectionpoints, list[SensorPoint] sensorpoints);
public alias Modifier = str;
public alias ModifierSet = set[Modifier];
public data Attribute = requiredAttrib(str name, list[list[Unit]] unit)
			   | optionalAttrib(str name, list[list[Unit]] unit, Value defaultvalue);
public data Value = numValue(num val, list[Unit] unit)
		   | boolValue(bool boolean)
		   | listValue(list[str] contents)
		   ;
public data SensorPoint = sensorPoint(str name, list[list[Unit]] unit)
				 | selfPoint(list[list[Unit]] unit);
public data ConnectionPoint = gasConnection(str name)
					 | liquidConnection(str name)
					 | unknownConnection(str name)
					 | attribConnections()
					 | liquidConnectionModifier(str name, Modifier modifier)
					 | unknownConnectionModifier(str name, Modifier modifier)
					 ;

public Element Boiler =
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


public Element CentralHeatingUnit =
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
	
	
public Element Exhaust =
	element(	[
					{"Gas", "Liquid"}
				], //modifiers
				[],  //attributes
				[
					unknownConnection("[self]")
				], //connectionpoints
				[]  // sensorpoints
	);

public Element Joint =
	element(	[], //modifiers
				[
					optionalAttrib("connections", [], listValue(["in", "out"]))
				],  //attributes
				[
					attribConnections()
				], //connectionpoints
				[]  // sensorpoints
	);
	


public Element Pipe =
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
	

public Element Pump =
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


public Element Radiator =
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
	


public Element Sensor =
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
	
	
	
	
public Element Source =
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

public Element Valve =
	element(	[
					{"Controlled"},
					{"Pin"},
					{"3-way"}
				], //modifiers
				[
					optionalAttrib("position", [], listValue([":closed"]))
				],  //attributes
				[
					unknownConnection("a"),
					unknownConnection("b"),
					unknownConnectionModifier("c", "3-way")
					
				], //connectionpoints
				[]  // sensorpoints
	);
	

public map[str, Element] Elements = (
								"Boiler" : Boiler,
								"CentralHeatingUnit" : CentralHeatingUnit,
								"Exhaust" : Exhaust,
								"Joint" : Joint,
								"Pipe" : Pipe,
								"Pump" : Pump,
								"Radiator" : Radiator,
								"Sensor" : Sensor,
								"Source" : Source,
								"Valve" : Valve
							);