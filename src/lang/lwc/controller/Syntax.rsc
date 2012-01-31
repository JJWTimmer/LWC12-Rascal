module lang::lwc::controller::Syntax
/*
	TODO:
		make Expression abstraction
		use 'bracket' keyword for the paren-case in Expression (remove constructor)
		rename slt to leq and sgt to geq
*/

lexical Comment = [#] ![\n]* $;

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r#];

keyword Keyword = "if" | "condition" | "goto" | "and" | "or" | "not" | "state" | "true" | "false";

lexical Identifier 	= ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;
lexical ValveConnection = @category="Identifier" ":" Identifier;
lexical Int 		= @category="Constant" "-"? [0-9]+ !>> [0-9];

syntax Boolean 	= @category="Identifier" \true: "true" 
					  | \false: "false";

syntax Primary 
	= integer: Int
	| boolean: Boolean
	| rhsvariable: Variable
	| rhsproperty: Property
	;
	
syntax StateName = @category="Variable" statename: Identifier;

start syntax Controller = controller: TopStatement*;

syntax TopStatement
	= state: "state" StateName ":" Statement*
	| condition: "condition" Identifier ":" Expression
	| declaration: Identifier "=" Primary 
	;
	
syntax Statement 
	= Assignment
	| ifstatement: "if" Expression ":" Statement
	| goto: "goto" StateName;
	
syntax Assignable = lhsproperty: Property 
                  | lhsvariable: Variable;

syntax Assignment = assign: Assignable "=" Value
	              | \append: Assignable "+=" Value
	              | remove: Assignable "-=" Value
	              | multiply: Assignable "*=" Value;
		
syntax Value = expression: Expression 
             | connections: {  ValveConnection "," }+;
             
syntax Variable = variable: Identifier;

syntax Property = property: Identifier "." Identifier;

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
