module lang::lwc::controller::Syntax

lexical Comment = [#] ![\n]* [\n];

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r];

keyword Keyword = "if" | "state" | "condition" | "goto" | "and" | "or" | "not";

lexical Identifier 	= ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;
lexical Int 		= @category="Constant" "-"? [0-9]+ !>> [0-9];
lexical Boolean 	= @category="Identifier" "true" | "false";

syntax Primary 
	= Int
	| Boolean
	| Variable
	| Property;
	
syntax Variable = @category="Identifier" Identifier;
syntax Property = @category="Identifier" Identifier "." Identifier;
syntax StateName = @category="Variable" Identifier;

start syntax Controller = TopStatements*;

syntax TopStatements 
	= State
	/*
	| Condition
	/*
	| Declaration 
	*/
	;
	
syntax State = "state" StateName ":" Statement*;
syntax Condition = "condition" Identifier ":" Expression;
syntax Declaration = Identifier "=" Primary;

syntax Statement 
	= Assignment
	| IfStatement
	| Goto;
	
syntax Assignable = Variable | Property;

syntax Assignment
	= Assignable ("=" | "+=" | "-=" | "*=") Expression;
	
syntax IfStatement
	= "if" Expression ":" Statement;

syntax Goto 
	= "goto" StateName;
	
syntax Expression 
	= Primary
	| "(" Expression ")"
	| "not" Expression
	> left (
         Expression "*" Expression |
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
