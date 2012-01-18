module lang::lwc::structure::Syntax
/*
	Syntax for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
*/

lexical Comment = [#] ![\n]* [\n];

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r];

keyword Reserved = "is"
				 | "connects"
				 | "with"
				 | "on"
				 ;

lexical Identifier = ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Reserved;

lexical Real = "-"? [0-9]+ "." [0-9]+;
lexical Int = "-"? [0-9]+ !>> [.0-9];

syntax Num = integer: Int
			| realnum: Real
			;

syntax Value = id: Identifier
			 | Num
			 | Metric
			 | idlist: IdList
			 ;

syntax Metric = metric: Num Unit;

syntax Unit = unit: Identifier;

syntax IdList = {Identifier  ","}+;

start syntax Structure = structure: Statement+;

syntax Statement = Element
				 | Alias
				 | Pipe
				 | MeasurementDevice
				 ;

syntax Element = @Foldable element: Modifier* ElementName Identifier Property* ";";

syntax ElementName = @category="Identifier" elementname: Identifier;

syntax Modifier = modifier: Identifier;

syntax Alias = @Foldable aliaselem: Identifier "is" Modifier* ElementName Property* ";";

syntax Pipe = @Foldable pipe: ElementName Identifier "connects" ConnectionPoint "with" ConnectionPoint Property* ";";

syntax ConnectionPoint = connectionpoint: ElementName "." ConnectionPointName
					   | singleconnection: ElementName
					   ;

syntax ConnectionPointName = connectionpointname: Identifier;

syntax Property = property: "-" PropertyName ":" Value;

syntax PropertyName = @category="Constant" propertyname: Identifier;

syntax MeasurementDevice = @Foldable sensor: Modifier* ElementName Identifier "on" ConnectionPoint ";";