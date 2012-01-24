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

public data ValidElement = element(list[ValidModifierSet] modifiers, list[ValidAttribute] attributes, list[ValidConnectionPoint] connectionpoints, list[ValidSensorPoint] sensorpoints);
public alias ValidModifier = str;
public alias ValidModifierSet = set[ValidModifier];
public data ValidAttribute = requiredAttrib(str name, list[list[Unit]] unit)
					  	   | optionalAttrib(str name, list[list[Unit]] unit, ValidValue defaultvalue);
public data ValidValue = numValue(num val, list[Unit] unit)
				  	   | boolValue(bool boolean)
				  	   | listValue(list[str] contents)
				  	   ;
public data ValidSensorPoint = sensorPoint(str name, list[list[Unit]] unit)
				 			 | selfPoint(list[list[Unit]] unit);
public data ValidConnectionPoint = gasConnection(str name)
					 			 | liquidConnection(str name)
					 			 | unknownConnection(str name)
					 			 | attribConnections()
								 | liquidConnectionModifier(str name, ValidModifier modifier)
					 			 | unknownConnectionModifier(str name, ValidModifier modifier)
					 			 ;

public ValidElement Boiler =
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


public ValidElement CentralHeatingUnit =
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
	
	
public ValidElement Exhaust =
	element(	[
					{"Gas", "Liquid"}
				], //modifiers
				[],  //attributes
				[
					unknownConnection("[self]")
				], //connectionpoints
				[]  // sensorpoints
	);

public ValidElement Joint =
	element(	[], //modifiers
				[
					optionalAttrib("connections", [], listValue(["in", "out"]))
				],  //attributes
				[
					attribConnections()
				], //connectionpoints
				[]  // sensorpoints
	);
	


public ValidElement Pipe =
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
	

public ValidElement Pump =
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


public ValidElement Radiator =
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
	


public ValidElement Sensor =
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
	
	
	
	
public ValidElement Source =
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

public ValidElement Valve =
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
				[] // sensorpoints
	);
	

public map[str, ValidElement] Elements = (
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
public list[str] ElementNames = [key | key <- Elements];