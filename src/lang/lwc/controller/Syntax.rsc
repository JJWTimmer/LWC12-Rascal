module lang::lwc::controller::Syntax

lexical Comment = [#] ![\n]* $;

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r#];

keyword Keyword = "if" | "condition" | "goto" | "and" | "or" | "not" | "state" | "true" | "false";

lexical Identifier 	= ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;
lexical ValveConnection = @category="Identifier" ":" Identifier;
lexical Int 		= @category="Constant" "-"? [0-9]+ !>> [0-9];
lexical Boolean 	= @category="Identifier" booltrue: "true" | boolfalse: "false";

syntax Primary 
	= integer: Int
	| Boolean
	| Assignable
	;
	
syntax Variable = variable: Identifier;
syntax Property = propname: Identifier;
syntax StateName = @category="Variable" statename: Identifier;

start syntax Controller = controller: TopStatement*;

syntax TopStatement
	= State
	| Condition
	| Declaration 
	;
	
syntax State = state: "state" StateName ":" Statement*;
syntax Condition = condition: "condition" Identifier ":" Expression;
syntax Declaration = declaration: Variable "=" Primary;

syntax Statement 
	= Assignment
	| IfStatement
	| Goto;
	
syntax Assignable = property: Identifier "." Property | Variable;

syntax Assignment
	= assignment: Assignable ( "=" | "+=" | "-=" | "*=") operator Value;
	
syntax IfStatement
	= ifstatement: "if" Expression ":" Statement;

syntax Goto 
	= goto: "goto" StateName;
	
syntax Value = expression: Expression | ValveConfiguration;

syntax ValveConfiguration 
	= connections: {  ValveConnection "," }+
	;

syntax Expression 
	= prim: Primary
	| paren: "(" Expression ")"
	| not: "not" Expression
	> left (
         mul: Expression "*" Expression |
         div: Expression "/" Expression |
         mdl: Expression "%" Expression
    )
    > left (
         add: Expression "+" Expression |
         sub: Expression "-" Expression
    )
    > left (
         lt:  Expression "\<" Expression |
         gt:  Expression "\>" Expression |
         slt: Expression "\<=" Expression |
         sgt: Expression "\>=" Expression
    ) 
    > left(
		eq:  Expression "==" Expression |
		neq: Expression "!=" Expression
	)
	> left and: Expression "and" Expression
	> left or:  Expression "or" Expression
	;
