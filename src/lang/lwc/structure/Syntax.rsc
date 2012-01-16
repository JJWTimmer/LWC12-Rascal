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

lexical Identifier = [a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_] \ Reserved;

lexical Int = "-"? [0-9]+;

syntax Value = Identifier | Int | Metric | IdList;

syntax Metric = Int Unit;

syntax Unit = Identifier;

syntax IdList = IdList "," Identifier
				 | Identifier
				 ;

start syntax Structure = Statement+;

syntax Statement = Element
				 | AliasElem
				 | Pipe
				 ;

syntax Element = @Foldable Modifier* ElementName Identifier Property* ";";

syntax ElementName = @category="Identifier" Identifier;

syntax Modifier = Identifier;

syntax AliasElem = @Foldable Identifier "is" ElementName Property* ";";

syntax Pipe = @Foldable ElementName Identifier "connects" ConnectionPoint "with" ConnectionPoint Property* ";";

syntax ConnectionPoint = ElementName "." ConnectionPointName;

syntax ConnectionPointName = Identifier;
	
syntax Property = "-" PropertyName ":" Value;

syntax PropertyName = @category="Constant" Identifier;