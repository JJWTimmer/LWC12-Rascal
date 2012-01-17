module lang::lwc::controller::Syntax

lexical Comment = [#] ![\n]* [\n];

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r];

keyword Keyword = "if" | "state" | "condition" | "goto" | "and" | "or" | "not";

lexical Identifier 	= id: ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;
lexical Int 		= @category="Constant" "-"? [0-9]+ !>> [0-9];
lexical Boolean 	= @category="Identifier" "true" | "false";

syntax Primary 
	= Int
	| Boolean
	| Variable
	| Property
	;
	
syntax Variable = Identifier;
syntax Property = Identifier "." Identifier;
syntax StateName = @category="Variable" Identifier;

start syntax Controller = controller: TopStatement*;

syntax TopStatement
	= state: State
	| condition: Condition
	| declaration: Declaration 
	;
	
syntax State = "state" StateName ":" Statement*;
syntax Condition = "condition" Identifier ":" Expression;
syntax Declaration = Variable "=" Primary;

syntax Statement 
	= assignment: Assignment
	| ifstatement: IfStatement
	| goto: Goto;
	
syntax Assignable = variable: Variable | property: Property;

//bij gebruik van implode wordt de operator weggegooid toch? Maar willen we die 
//info niet eigenlijk behouden?
syntax Assignment
	= Assignable ( "=" | "+=" | "-=" | "*=") operator Expression;
	
syntax IfStatement
	= "if" Expression ":" Statement;

syntax Goto 
	= "goto" StateName;
	
syntax Expression 
	= prim: Primary
	| paren: "(" Expression ")"
	| not: "not" Expression
	> left (
         mul: Expression "*" Expression |
         div: Expression "/" Expression |
         modulo: Expression "%" Expression
    )
    > left (
         add: Expression "+" Expression |
         sub: Expression "-" Expression
    )
    > left (
         Expression "\<\<" Expression |
         Expression "\>\>" Expression
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
