module lang::lwc::structure::Syntax
/*
	Syntax for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
	
	TODO: Add interlock / variant / constraint syntax
*/

lexical Comment = [#] ![\n]* [\n];

lexical Layout 
	= [\ \t\n\r] 
	| @category="Comment" Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r];

keyword Reserved = "is"
				 | "connects"
				 | "with"
				 | "on"
				 ;

lexical Identifier = ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Reserved;

lexical Real = "-"? [0-9]+ "." [0-9]+;
lexical Int = "-"? [0-9]+ !>> [.0-9];

syntax Num = @category="Constant" integer: Int
		   | @category="Constant" realnum: Real
		   ;

syntax Value = @category="Variable" id: Identifier
			 | Num
			 | Metric
			 | idlist: IdList
			 ;

syntax Metric = metric: Num Unit;

syntax Unit = @category="Identifier" unit: Identifier;

syntax IdList = @category="Constant" {Identifier  ","}+;

start syntax Structure = structure: Statement+;

syntax Statement = Element
				 | Alias
				 | Pipe
				 | MeasurementDevice
				 ;

syntax Element = @Foldable element: Modifier* ElementName Identifier Property* ";";

syntax ElementName = @category="Type" elementname: Identifier;

syntax Modifier = @category="Type" modifier: Identifier;

syntax Alias = @Foldable aliaselem: Identifier "is" Modifier* ElementName Property* ";";

syntax Pipe = @Foldable pipe: ElementName Identifier "connects" ConnectionPoint "with" ConnectionPoint Property* ";";

syntax ConnectionPoint = connectionpoint: Identifier "." ConnectionPointName
					   | singleconnection: Identifier
					   ;

syntax ConnectionPointName = @category="Identifier" connectionpointname: Identifier;

syntax Property = property: "-" PropertyName ":" Value;

syntax PropertyName = @category="Identifier" propertyname: Identifier;

syntax MeasurementDevice = sensor: Modifier* ElementName Identifier "on" ConnectionPoint ";";