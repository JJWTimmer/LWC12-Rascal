module lang::lwc::structure::Syntax

lexical LAYOUT = whitespace: [\t-\n\r\ ] | Comment ;

layout LAYOUTLIST = LAYOUT* !>> [\t-\n\r\ ] !>> "/*" ;

lexical Comment = @Foldable @category="Comment"  "/*" CommentChar* "*/" ;

lexical CommentChar = ![*] | Asterisk ;

lexical Asterisk = [*] !>> [/] ;

keyword Reserved = "is"
				 | "connects"
				 | "with"
				 ;

lexical Identifier = id: ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Reserved;

lexical Int = integer: "-"?[0-9]+;

syntax Value = id: Identifier
			 | integer: Int
			 | metric: Metric
			 | idlist: IdList
			 ;

syntax Metric = metric: Int Unit;

syntax Unit = unit: Identifier;

syntax IdList = idlist: IdList "," Identifier
			  | Identifier
			  ;

start syntax Structure = structure: Statement+;

syntax Statement = Element
				 | Alias
				 | Pipe
				 ;

syntax Element = @Foldable element: Modifier* ElementName Identifier Property* ";";

syntax ElementName = @category="Identifier" elementname: Identifier;

syntax Modifier = modifier: Identifier;

syntax Alias = @Foldable aliaselem: Identifier "is" ElementName Property* ";";

syntax Pipe = @Foldable pipe: ElementName Identifier "connects" ConnectionPoint "with" ConnectionPoint Property* ";";

syntax ConnectionPoint = connectionpoint: ElementName "." ConnectionPointName;

syntax ConnectionPointName = connectionpointname: Identifier;

syntax Property = property: "-" PropertyName ":" Value;

syntax PropertyName = @category="Constant" propertyname: Identifier;