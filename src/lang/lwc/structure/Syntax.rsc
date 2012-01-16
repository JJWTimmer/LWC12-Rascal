module lang::lwc::structure::Syntax


layout WhiteSpace =
            WhitespaceAndComment*
            !>> [#\ \t\n\r]
            ;

lexical Newline = [\r\n];

lexical WhitespaceAndComment 
  = [\ \t\r\n]
//  | @category="comment" "#" ![\n]* "\n"
  ;

lexical Identifier = [a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_];
lexical Int = "-"? [0-9]+;

syntax Value = Identifier | Value | Metric;
syntax Metric = Int Unit?;
syntax ValueList = ValueList "," Value | Value;

start syntax Main = Statement+;

syntax Statement 
	= Element
	| Alias
	| Pipe
	;

syntax Element = Modifier* ElementType Identifier Properties;
keyword ElementType = "Boiler" | "Valve" | "Radiator" | "CentralHeatingUnit" | "Pump" | "Pipe";

syntax Modifier = Identifier;

syntax Alias = Identifier "is" ElementType Properties;

syntax Pipe = ElementType Identifier "connects" Connection "with" Connection Properties*;

syntax Connection = Identifier ("." Identifier)?;
	
syntax Properties = Property*;
syntax Property = "-" Identifier ":" ValueList;

keyword Unit = "watt" | "mm";

