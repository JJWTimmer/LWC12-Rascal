module lang::lwc::structure::Syntax
extend lang::lwc::ExpressionSyntax;
/*
	Syntax for LWC'12 Structure Language
	Author: Jasper Timmer <jjwtimmer@gmail.com>
	
	TODO:
		make Expression abstraction
		use 'bracket' keyword for the paren-case in Expression (remove constructor)
		rename slt to leq and sgt to geq
*/

lexical Comment = [#] ![\n]* $;

lexical Layout 
	= [\ \t\n\r] 
	| @category="Comment" Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r#];

keyword Reserved = "is"
				 | "connects"
				 | "with"
				 | "constraint"
				 | "true"
				 | "false"
				 | "and"
				 | "or"
				 ;

lexical Identifier = ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Reserved;

lexical Real = "-"? [0-9]+ "." [0-9]+;
lexical Int = "-"? [0-9]+ !>> [.0-9];
syntax Boolean = @category="Constant" booltrue: "true"
			   | @category="Constant" boolfalse: "false"
			   ;

syntax Num = @category="Constant" integer: Int
		   | @category="Constant" realnum: Real
		   ;

syntax Assignable = property: Identifier "." PropName
				  | variable: Identifier
				  ;

syntax PropName = @category="Variable" propname: Identifier;

syntax Value = Assignable
			 | Num
			 | Metric
			 | Boolean
			 | position: Position
			 ;

syntax ValueList = valuelist: {Value  ","}+;

lexical Position = ":" Identifier;

syntax Metric = metric: Num Unit;

syntax Unit = @category="Constant" unit: "[" {Identifier "/"}+ "]";

syntax ExpVal = expval: Value; //for imported expressions
				 
syntax ElementName = @category="Type" elementname: Identifier;

syntax Modifier = @category="Type" modifier: Identifier;

syntax Attribute = attribute: "-" AttributeName ":" ValueList;

syntax AttributeName = @category="Identifier" attributename: Identifier;

start syntax Structure = structure: Statement*;//Start

syntax Statement = Element
				 | Alias
				 | Pipe
				 | Constraint
				 ;

syntax Element = @Foldable element: Modifier* ElementName Identifier Attribute* ";";

syntax Alias = @Foldable aliaselem: Identifier "is" Modifier* ElementName Attribute* ";";

syntax Pipe = @Foldable pipe: ElementName Identifier "connects" Assignable "with" Assignable Attribute* ";";

syntax Constraint = @Foldable constraint: "constraint" Identifier ":" Expression ";";