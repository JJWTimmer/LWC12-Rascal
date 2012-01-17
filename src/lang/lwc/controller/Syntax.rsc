module lang::lwc::controller::Syntax

lexical Comment = [#] ![\n]* [\n];

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" Comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r];

keyword Keyword = "event" | "condition"
                 ;

lexical Identifier = ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;
lexical Int = "-"?[1-9][0-9]*;
lexical Boolean = "true" | "false";

syntax Primary 
	= Int
	| Boolean
	| Variable
	| Property;
	
syntax Variable = Identifier;
syntax Property = Identifier "." Identifier;
	
start syntax Controller = TopStatements*;

syntax TopStatements 
	= State
	| Condition
	| Declaration
	;
	
syntax State = "state" Identifier ":" Statement*;
syntax Condition = "condition" Identifier ":" Expression;
syntax Declaration = Identifier "=" Primary;

syntax Statement 
	= Assignment
	| IfStatement
	| Goto;
	
syntax Assignment
	= Variable "=" Expression
	| Property "=" Expression;
	
syntax IfStatement
	= "if" Expression ":" Statement;

syntax Goto 
	= "goto" Identifier;
	
syntax Expression 
	= Primary
	| "(" Expression ")"
	| "not" Expression
	> left (
         Expression lexp "*" Expression rexp |
         Expression "/" Expression |
         Expression "%" Expression
    ) 
    > left (
         Expression "+" Expression |
         Expression "-" Expression
    )
    > left (
         Expression "\<\<" Expression |
         Expression "\>\>" Expression
    )
    > left (
         Expression "\<" Expression |
         Expression "\>" Expression |
         Expression "\<=" Expression |
         Expression "\>=" Expression
    ) 
    > left(
		Expression "==" Expression |
		Expression "!=" Expression
	)
	> left Expression "and" Expression
	> left Expression "or" Expression
	;
