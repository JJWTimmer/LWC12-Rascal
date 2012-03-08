module lang::lwc::controller::Syntax
extend lang::lwc::expressions::Syntax;

lexical Comment = [#] ![\n]* $;

lexical Layout 
	= Whitespace: [\ \t\n\r] 
	| @category="Comment" comment: Comment;

layout LAYOUTLIST = Layout* !>> [\ \t\n\r#];

keyword Keyword = "if" | "condition" | "goto" | "and" | "or" | "not" | "state" | "true" | "false";

lexical Identifier 	= ([a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keyword;
lexical ValveConnection = @category="Identifier" ":" Identifier;
lexical Int 		= @category="Constant" "-"? [0-9]+ !>> [0-9];

syntax Primary 
	= integer: Int
	| boolean: Boolean
	| rhsvariable: Variable
	| rhsproperty: Property
	;

syntax Expression = expvalue: Primary
				  | ...
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