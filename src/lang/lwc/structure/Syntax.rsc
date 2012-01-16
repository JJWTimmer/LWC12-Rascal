module lang::lwc::structure::Syntax


layout WhiteSpace =
            WhitespaceAndComment*
            !>> [#\ \t\n\r]
            ;

lexical Newline = [\r\n];

lexical WhitespaceAndComment 
  = [\ \t\r\n]
  | "#" ![\n]* "\n"
  ;

lexical Identifier = ([a-zA-Z_] [a-zA-Z0-9_]* !>> [a-zA-Z0-9_]);

start syntax Main = Statement+;

syntax Statement 
	= Element
	| Alias
	| Pipe
	;

syntax Element = Modifier* ElementType Identifier Properties;
syntax ElementType = "Boiler" | "Valve";

syntax Modifier = @syntax="Constant" Identifier;

syntax Alias = Identifier "is" ElementTypeOrPipe Properties;

syntax Pipe = Identifier Identifier "connects" Connection "with" Connection;

syntax Connection
	= Identifier
	| Identifier "." Identifier;
	
syntax Properties = Property*;
syntax Property = "-" Identifier ":" Identifier;

